/// Graph centrality measures.
library;

///
/// Each algorithm returns a map of `node_id => score`. Scores are normalised
/// where a standard definition exists (e.g. degree centrality divides by
/// *n-1*). Nodes that do not appear in a result map have an implicit score
/// of `0.0`.
///
/// Algorithms are organised by computational family:
/// * **Local** – [degree]
/// * **Distance-based** – [closeness], [harmonic], [betweenness]
/// * **Spectral / iterative** – [pageRank], [eigenvector], [katz], [alpha]
/// * **Link-analysis** – [hits]

import 'dart:math' as math;

import '../model/graph_kind.dart';
import '../model/roles.dart';
import '../model/weight_algebra.dart';
import '../pathfinding/a_star.dart';
import '../pathfinding/dijkstra.dart';
import 'brandes.dart';

// ---------------------------------------------------------------------------
// Options / Result types
// ---------------------------------------------------------------------------

/// Controls which incident edges are counted by [Centrality.degree].
enum DegreeMode {
  /// Count only incoming edges.
  inDegree,

  /// Count only outgoing edges.
  outDegree,

  /// Count both incoming and outgoing edges.
  totalDegree,
}

/// Configuration for [Centrality.pageRank].
class PageRankOptions {
  /// Damping factor (probability of following a link). Must be in `(0, 1)`.
  final double damping;

  /// Maximum number of power iterations.
  final int maxIterations;

  /// L1-norm convergence threshold.
  final double tolerance;

  const PageRankOptions({
    this.damping = 0.85,
    this.maxIterations = 100,
    this.tolerance = 1.0e-6,
  }) : assert(damping > 0 && damping < 1, 'damping must be in (0, 1)');
}

/// Hub and authority scores produced by [Centrality.hits].
class HitsResult {
  /// Authority score for each node.
  final Map<int, double> authorities;

  /// Hub score for each node.
  final Map<int, double> hubs;

  const HitsResult({required this.authorities, required this.hubs});
}

// ---------------------------------------------------------------------------
// Centrality algorithms
// ---------------------------------------------------------------------------

/// Static container for all centrality algorithms.
///
/// Every method is a pure function: it reads from the graph but never
/// mutates it.
abstract final class Centrality {
  const Centrality._();

  // ========================================================================
  // Degree
  // ========================================================================

  /// Degree centrality.
  ///
  /// For an undirected graph the score of *v* is `deg(v) / (n-1)`.
  ///
  /// For a directed graph the behaviour depends on [mode]:
  /// * [DegreeMode.inDegree]  → `indeg(v) / (n-1)`
  /// * [DegreeMode.outDegree] → `outdeg(v) / (n-1)`
  /// * [DegreeMode.totalDegree] → `(indeg(v) + outdeg(v)) / (n-1)`
  ///
  /// When `n <= 1` every node receives `0.0`.
  ///
  /// Time complexity: **O(n)**.
  static Map<int, double> degree<N, E>(
    Bidirectional<N, E> graph, {
    DegreeMode mode = DegreeMode.totalDegree,
  }) {
    final nodes = graph.nodeIds.toList();
    final n = nodes.length;
    if (n <= 1) {
      return {for (final v in nodes) v: 0.0};
    }
    final denom = (n - 1).toDouble();
    final isUndirected = graph.kind == GraphKind.undirected;

    final scores = <int, double>{};
    for (final v in nodes) {
      int count;
      if (isUndirected) {
        count = graph.successors(v).length;
      } else {
        switch (mode) {
          case DegreeMode.inDegree:
            count = graph.predecessors(v).length;
          case DegreeMode.outDegree:
            count = graph.successors(v).length;
          case DegreeMode.totalDegree:
            count = graph.predecessors(v).length + graph.successors(v).length;
        }
      }
      scores[v] = count / denom;
    }
    return scores;
  }

  // ========================================================================
  // Closeness
  // ========================================================================

  /// Closeness centrality.
  ///
  /// For each node *s* we run a single-source shortest-path search and sum
  /// the distances to every other reachable node.
  ///
  /// ```
  /// C(s) = (n-1) / Σ_{t≠s} d(s,t)
  /// ```
  ///
  /// If *s* cannot reach any other node the score is `0.0`.
  ///
  /// Custom edge-weight semantics may be supplied via [algebra].
  ///
  /// Time complexity: **O(n · (E log V))** (one Dijkstra per source).
  static Map<int, double> closeness<N, E>(
    WeightedWalkable<N, E> graph, {
    WeightAlgebra<E>? algebra,
  }) {
    final alg = resolveAlgebra<E>(algebra);
    final nodes = graph.nodeIds.toList();
    final n = nodes.length;
    if (n <= 1) return {for (final v in nodes) v: 0.0};

    final scores = <int, double>{};
    final zero = alg.zero;

    for (final s in nodes) {
      final distances = Dijkstra.singleSourceDistances(graph, s, algebra: alg);

      var total = zero;
      var reachable = 0;
      for (final entry in distances.entries) {
        if (entry.key == s) continue;
        if (alg.compare(entry.value, zero) == 0) {
          continue; // unreachable / zero-weight
        }
        total = alg.add(total, entry.value);
        reachable++;
      }

      final totalD = alg.toDouble(total);
      if (reachable == 0 || totalD == 0.0) {
        scores[s] = 0.0;
      } else {
        scores[s] = (n - 1) / totalD;
      }
    }
    return scores;
  }

  // ========================================================================
  // Harmonic
  // ========================================================================

  /// Harmonic centrality.
  ///
  /// Handles disconnected graphs gracefully by using the harmonic mean of
  /// distances instead of the arithmetic mean.
  ///
  /// ```
  /// H(s) = (1/(n-1)) · Σ_{t≠s} 1/d(s,t)
  /// ```
  ///
  /// Unreachable nodes contribute `0` to the sum.
  ///
  /// Time complexity: **O(n · (E log V))**.
  static Map<int, double> harmonic<N, E>(
    WeightedWalkable<N, E> graph, {
    WeightAlgebra<E>? algebra,
  }) {
    final alg = resolveAlgebra<E>(algebra);
    final nodes = graph.nodeIds.toList();
    final n = nodes.length;
    if (n <= 1) return {for (final v in nodes) v: 0.0};

    final denom = (n - 1).toDouble();
    final scores = <int, double>{};
    final zero = alg.zero;

    for (final s in nodes) {
      final distances = Dijkstra.singleSourceDistances(graph, s, algebra: alg);

      var sum = 0.0;
      for (final entry in distances.entries) {
        if (entry.key == s) continue;
        if (alg.compare(entry.value, zero) == 0) continue;
        final d = alg.toDouble(entry.value);
        if (d != 0.0) {
          sum += 1.0 / d;
        }
      }
      scores[s] = sum / denom;
    }
    return scores;
  }

  // ========================================================================
  // Betweenness
  // ========================================================================

  /// Betweenness centrality (Brandes' algorithm).
  ///
  /// For each node *s* we discover all shortest paths from *s* and
  /// accumulate dependency scores on every intermediate node.
  ///
  /// ```
  /// CB(v) = Σ_{s≠v≠t} σ_st(v) / σ_st
  /// ```
  ///
  /// For undirected graphs the raw scores are halved because every
  /// shortest path is counted twice (once in each direction).
  ///
  /// Custom edge-weight semantics may be supplied via [algebra].
  ///
  /// Time complexity: **O(n · (E log V))** for weighted graphs,
  /// **O(n · E)** for unweighted graphs.
  static Map<int, double> betweenness<N, E>(
    WeightedWalkable<N, E> graph, {
    WeightAlgebra<E>? algebra,
  }) {
    final alg = resolveAlgebra<E>(algebra);
    final nodes = graph.nodeIds.toList();
    final n = nodes.length;
    if (n <= 1) return {for (final v in nodes) v: 0.0};

    final scores = <int, double>{};
    for (final s in nodes) {
      final discovery = Brandes.runDiscovery(graph, s, algebra: alg);
      final deltas = Brandes.accumulateNodeDependencies(discovery);
      for (final entry in deltas.entries) {
        if (entry.key == s) continue; // exclude self-dependency
        scores[entry.key] = (scores[entry.key] ?? 0.0) + entry.value;
      }
    }

    // Undirected scaling: each shortest path counted twice
    if (graph.kind == GraphKind.undirected) {
      for (final key in scores.keys) {
        scores[key] = scores[key]! / 2.0;
      }
    }

    // Ensure every node appears (with 0.0 if it had no betweenness)
    for (final v in nodes) {
      scores.putIfAbsent(v, () => 0.0);
    }

    return scores;
  }

  // ========================================================================
  // PageRank
  // ========================================================================

  /// PageRank (random surfer model).
  ///
  /// Returns the stationary distribution of the Markov chain induced by
  /// the graph's transition matrix with damping.
  ///
  /// Sinks (nodes with out-degree 0) redistribute their mass uniformly
  /// across all nodes.
  ///
  /// Time complexity: **O(maxIterations · (n + E))**.
  static Map<int, double> pageRank<N, E>(
    Bidirectional<N, E> graph, {
    PageRankOptions? options,
  }) {
    final opts = options ?? const PageRankOptions();
    final nodes = graph.nodeIds.toList();
    final n = nodes.length;
    if (n == 0) return {};
    if (n == 1) return {nodes.first: 1.0};

    final oneOverN = 1.0 / n;
    final d = opts.damping;
    final oneMinusDOverN = (1.0 - d) / n;

    // Pre-compute successors and out-degrees for speed.
    final succs = <int, List<int>>{};
    final outDegs = <int, int>{};
    final sinks = <int>[];
    for (final v in nodes) {
      final succ = graph.successors(v).toList();
      succs[v] = succ;
      outDegs[v] = succ.length;
      if (succ.isEmpty) sinks.add(v);
    }

    var ranks = <int, double>{for (final v in nodes) v: oneOverN};

    for (var iter = 0; iter < opts.maxIterations; iter++) {
      var danglingSum = 0.0;
      for (final v in sinks) {
        danglingSum += ranks[v] ?? 0.0;
      }
      final danglingContrib = d * danglingSum / n;

      final newRanks = <int, double>{};
      for (final v in nodes) {
        var sum = 0.0;
        for (final u in graph.predecessors(v)) {
          final outDeg = outDegs[u] ?? 0;
          if (outDeg > 0) {
            sum += (ranks[u] ?? 0.0) / outDeg;
          }
        }
        newRanks[v] = oneMinusDOverN + danglingContrib + d * sum;
      }

      // L1 convergence check
      var diff = 0.0;
      for (final v in nodes) {
        diff += (newRanks[v]! - (ranks[v] ?? 0.0)).abs();
      }
      ranks = newRanks;
      if (diff < opts.tolerance) break;
    }

    return ranks;
  }

  // ========================================================================
  // Eigenvector
  // ========================================================================

  /// Eigenvector centrality (power iteration).
  ///
  /// Computes the principal eigenvector of the transpose of the weighted
  /// adjacency matrix. For directed graphs this means a node is important
  /// when important nodes point *to* it.
  ///
  /// Time complexity: **O(maxIterations · (n + E))**.
  static Map<int, double> eigenvector<N, E>(
    Bidirectional<N, E> graph, {
    int maxIterations = 100,
    double tolerance = 0.0001,
  }) {
    final nodes = graph.nodeIds.toList();
    final n = nodes.length;
    if (n == 0) return {};
    if (n == 1) return {nodes.first: 1.0};

    var scores = <int, double>{for (final v in nodes) v: 1.0};

    for (var iter = 0; iter < maxIterations; iter++) {
      final next = <int, double>{};
      for (final v in nodes) {
        var sum = 0.0;
        for (final u in graph.predecessors(v)) {
          sum += (scores[u] ?? 0.0) * graph.edgeWeight(u, v);
        }
        next[v] = sum;
      }

      // L2 normalisation
      var norm = 0.0;
      for (final v in nodes) {
        norm += (next[v] ?? 0.0) * (next[v] ?? 0.0);
      }
      norm = (norm <= 0) ? 1.0 : math.sqrt(norm);

      var diff = 0.0;
      for (final v in nodes) {
        final old = scores[v] ?? 0.0;
        final val = (next[v] ?? 0.0) / norm;
        next[v] = val;
        diff += (val - old).abs();
      }
      scores = next;
      if (diff < tolerance) break;
    }

    return scores;
  }

  // ========================================================================
  // Katz
  // ========================================================================

  /// Katz centrality.
  ///
  /// Attenuated influence centrality:
  ///
  /// ```
  /// x_i = α · Σ_j A_ji · x_j + β
  /// ```
  ///
  /// [alpha] must be smaller than the reciprocal of the largest eigenvalue
  /// of the adjacency matrix for convergence.
  ///
  /// Time complexity: **O(maxIterations · (n + E))**.
  static Map<int, double> katz<N, E>(
    Bidirectional<N, E> graph, {
    double alpha = 0.1,
    double beta = 1.0,
    int maxIterations = 100,
    double tolerance = 0.0001,
  }) {
    final nodes = graph.nodeIds.toList();
    final n = nodes.length;
    if (n == 0) return {};

    var scores = <int, double>{for (final v in nodes) v: beta};

    for (var iter = 0; iter < maxIterations; iter++) {
      final next = <int, double>{};
      for (final v in nodes) {
        var sum = 0.0;
        for (final u in graph.predecessors(v)) {
          sum += (scores[u] ?? 0.0) * graph.edgeWeight(u, v);
        }
        next[v] = alpha * sum + beta;
      }

      var diff = 0.0;
      for (final v in nodes) {
        final old = scores[v] ?? 0.0;
        final val = next[v]!;
        diff += (val - old).abs();
      }
      scores = next;
      if (diff < tolerance) break;
    }

    return scores;
  }

  // ========================================================================
  // Alpha
  // ========================================================================

  /// Alpha centrality.
  ///
  /// Similar to Katz but with a uniform external influence [initial]:
  ///
  /// ```
  /// x = α · A^T · x + e
  /// ```
  ///
  /// where every entry of *e* equals [initial].
  ///
  /// Time complexity: **O(maxIterations · (n + E))**.
  static Map<int, double> alpha<N, E>(
    Bidirectional<N, E> graph, {
    double alpha = 0.1,
    double initial = 1.0,
    int maxIterations = 100,
    double tolerance = 0.0001,
  }) {
    final nodes = graph.nodeIds.toList();
    final n = nodes.length;
    if (n == 0) return {};

    var scores = <int, double>{for (final v in nodes) v: initial};

    for (var iter = 0; iter < maxIterations; iter++) {
      final next = <int, double>{};
      for (final v in nodes) {
        var sum = 0.0;
        for (final u in graph.predecessors(v)) {
          sum += (scores[u] ?? 0.0) * graph.edgeWeight(u, v);
        }
        next[v] = initial + alpha * sum;
      }

      var diff = 0.0;
      for (final v in nodes) {
        final old = scores[v] ?? 0.0;
        final val = next[v]!;
        diff += (val - old).abs();
      }
      scores = next;
      if (diff < tolerance) break;
    }

    return scores;
  }

  // ========================================================================
  // HITS
  // ========================================================================

  /// HITS (Hyperlink-Induced Topic Search).
  ///
  /// Computes hub and authority scores via mutual reinforcement:
  ///
  /// * `auth(v) = Σ_{u→v} hub(u) · w(u,v)`
  /// * `hub(v)  = Σ_{v→u} auth(u) · w(v,u)`
  ///
  /// Scores are L2-normalised after every iteration.
  ///
  /// Time complexity: **O(maxIterations · (n + E))**.
  static HitsResult hits<N, E>(
    Bidirectional<N, E> graph, {
    int maxIterations = 100,
    double tolerance = 1.0e-6,
  }) {
    final nodes = graph.nodeIds.toList();
    final n = nodes.length;
    if (n == 0) {
      return const HitsResult(authorities: {}, hubs: {});
    }
    if (n == 1) {
      return HitsResult(
        authorities: {nodes.first: 1.0},
        hubs: {nodes.first: 1.0},
      );
    }

    final initial = 1.0 / math.sqrt(n.toDouble());
    var auth = <int, double>{for (final v in nodes) v: initial};
    var hub = <int, double>{for (final v in nodes) v: initial};

    for (var iter = 0; iter < maxIterations; iter++) {
      // Authority update
      final nextAuth = <int, double>{};
      for (final v in nodes) {
        var sum = 0.0;
        for (final u in graph.predecessors(v)) {
          sum += (hub[u] ?? 0.0) * graph.edgeWeight(u, v);
        }
        nextAuth[v] = sum;
      }

      // Hub update
      final nextHub = <int, double>{};
      for (final v in nodes) {
        var sum = 0.0;
        for (final u in graph.successors(v)) {
          sum += (nextAuth[u] ?? 0.0) * graph.edgeWeight(v, u);
        }
        nextHub[v] = sum;
      }

      // L2 normalisation
      var authNorm = 0.0;
      var hubNorm = 0.0;
      for (final v in nodes) {
        authNorm += (nextAuth[v] ?? 0.0) * (nextAuth[v] ?? 0.0);
        hubNorm += (nextHub[v] ?? 0.0) * (nextHub[v] ?? 0.0);
      }
      authNorm = (authNorm <= 0) ? 1.0 : math.sqrt(authNorm);
      hubNorm = (hubNorm <= 0) ? 1.0 : math.sqrt(hubNorm);

      var diff = 0.0;
      for (final v in nodes) {
        final oldAuth = auth[v] ?? 0.0;
        final oldHub = hub[v] ?? 0.0;
        final newAuth = (nextAuth[v] ?? 0.0) / authNorm;
        final newHub = (nextHub[v] ?? 0.0) / hubNorm;
        nextAuth[v] = newAuth;
        nextHub[v] = newHub;
        diff += (newAuth - oldAuth).abs() + (newHub - oldHub).abs();
      }

      auth = nextAuth;
      hub = nextHub;
      if (diff < tolerance) break;
    }

    return HitsResult(authorities: auth, hubs: hub);
  }
}
