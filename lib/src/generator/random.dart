import 'dart:math' as math;
import '../model/graph_kind.dart';
import '../simple_graph.dart';

/// Stochastic graph generators for random graph models.
abstract final class RandomGenerator {
  RandomGenerator._();

  /// Generates a random graph using the Erdős-Rényi G(n, p) model.
  ///
  /// Each possible edge is included independently with probability [p].
  static SimpleGraph<void, int> erdosRenyiGnp(
    int n,
    double p, {
    GraphKind kind = GraphKind.undirected,
    int? seed,
  }) {
    final graph = kind == GraphKind.directed
        ? SimpleGraph<void, int>.directed()
        : SimpleGraph<void, int>.undirected();

    if (n <= 0 || p < 0.0 || p > 1.0) return graph;

    final rng = seed != null ? math.Random(seed) : math.Random();

    for (var i = 0; i < n; i++) {
      graph.addNode(i);
    }

    for (var i = 0; i < n; i++) {
      for (var j = (kind == GraphKind.undirected ? i + 1 : 0); j < n; j++) {
        if (i == j) continue;
        if (rng.nextDouble() <= p) {
          graph.addEdge(i, j, data: 1);
        }
      }
    }

    return graph;
  }

  /// Generates a random graph using the Erdős-Rényi G(n, m) model.
  ///
  /// Exactly [m] edges are added uniformly at random.
  static SimpleGraph<void, int> erdosRenyiGnm(
    int n,
    int m, {
    GraphKind kind = GraphKind.undirected,
    int? seed,
  }) {
    final graph = kind == GraphKind.directed
        ? SimpleGraph<void, int>.directed()
        : SimpleGraph<void, int>.undirected();

    if (n <= 0 || m < 0) return graph;

    for (var i = 0; i < n; i++) {
      graph.addNode(i);
    }

    final allPairs = <(int, int)>[];
    for (var i = 0; i < n; i++) {
      for (var j = (kind == GraphKind.undirected ? i + 1 : 0); j < n; j++) {
        if (i == j) continue;
        allPairs.add((i, j));
      }
    }

    final rng = seed != null ? math.Random(seed) : math.Random();
    // Shuffle allPairs
    final shuffled = List<(int, int)>.from(allPairs)..shuffle(rng);
    final limit = math.min(m, shuffled.length);

    for (var i = 0; i < limit; i++) {
      final (u, v) = shuffled[i];
      graph.addEdge(u, v, data: 1);
    }

    return graph;
  }

  /// Generates a scale-free graph using the Barabási-Albert preferential attachment model.
  static SimpleGraph<void, int> barabasiAlbert(
    int n,
    int m, {
    GraphKind kind = GraphKind.undirected,
    int? seed,
  }) {
    final graph = kind == GraphKind.directed
        ? SimpleGraph<void, int>.directed()
        : SimpleGraph<void, int>.undirected();

    if (n <= 0 || m <= 0 || m >= n) {
      // Return graph with n isolated nodes
      for (var i = 0; i < n; i++) {
        graph.addNode(i);
      }
      return graph;
    }

    final rng = seed != null ? math.Random(seed) : math.Random();

    // Start with a complete graph on m nodes
    for (var i = 0; i < m; i++) {
      graph.addNode(i);
      for (var j = 0; j < i; j++) {
        graph.addEdge(i, j, data: 1);
      }
    }

    // Add remaining nodes
    for (var i = m; i < n; i++) {
      graph.addNode(i);

      // Collect degrees of existing nodes
      final degrees = <int, int>{};
      var totalDegree = 0;
      for (var node = 0; node < i; node++) {
        final deg = graph.degree(node);
        final weight = math.max(deg, 1);
        degrees[node] = weight;
        totalDegree += weight;
      }

      // Select m distinct nodes preferentially
      final selectedTargets = <int>{};
      while (selectedTargets.length < m) {
        var pick = rng.nextDouble() * totalDegree;
        var currentSum = 0.0;
        int? selectedNode;

        for (final entry in degrees.entries) {
          currentSum += entry.value;
          if (currentSum >= pick) {
            selectedNode = entry.key;
            break;
          }
        }

        if (selectedNode != null && !selectedTargets.contains(selectedNode)) {
          selectedTargets.add(selectedNode);
        }
      }

      // Add edges from i to selected targets
      for (final target in selectedTargets) {
        graph.addEdge(i, target, data: 1);
      }
    }

    return graph;
  }

  /// Generates a small-world graph using the Watts-Strogatz model.
  static SimpleGraph<void, int> wattsStrogatz(
    int n,
    int k,
    double beta, {
    GraphKind kind = GraphKind.undirected,
    int? seed,
  }) {
    final graph = kind == GraphKind.directed
        ? SimpleGraph<void, int>.directed()
        : SimpleGraph<void, int>.undirected();

    if (n <= k || k < 2 || beta < 0.0 || beta > 1.0) return graph;

    final rng = seed != null ? math.Random(seed) : math.Random();

    for (var i = 0; i < n; i++) {
      graph.addNode(i);
    }

    final kHalf = k ~/ 2;
    final latticeEdges = <(int, int)>[];

    for (var i = 0; i < n; i++) {
      for (var offset = 1; offset <= kHalf; offset++) {
        latticeEdges.add((i, (i + offset) % n));
      }
    }

    final used = <(int, int)>{};

    for (final edge in latticeEdges) {
      final (from, to) = edge;
      final edgeKey = kind == GraphKind.undirected
          ? (math.min(from, to), math.max(from, to))
          : (from, to);

      if (used.contains(edgeKey)) continue;
      used.add(edgeKey);

      if (rng.nextDouble() <= beta) {
        // Rewire
        final candidates = <int>[];
        for (var x = 0; x < n; x++) {
          if (x == from) continue;
          final candidateKey = kind == GraphKind.undirected
              ? (math.min(from, x), math.max(from, x))
              : (from, x);
          if (!used.contains(candidateKey)) {
            candidates.add(x);
          }
        }

        if (candidates.isEmpty) {
          graph.addEdge(from, to, data: 1);
        } else {
          final newTo = candidates[rng.nextInt(candidates.length)];
          final newEdgeKey = kind == GraphKind.undirected
              ? (math.min(from, newTo), math.max(from, newTo))
              : (from, newTo);
          used.add(newEdgeKey);
          graph.addEdge(from, newTo, data: 1);
        }
      } else {
        graph.addEdge(from, to, data: 1);
      }
    }

    return graph;
  }

  /// Generates a uniformly random tree on [n] nodes.
  static SimpleGraph<void, int> randomTree(
    int n, {
    GraphKind kind = GraphKind.undirected,
    int? seed,
  }) {
    final graph = kind == GraphKind.directed
        ? SimpleGraph<void, int>.directed()
        : SimpleGraph<void, int>.undirected();

    if (n <= 0) return graph;
    graph.addNode(0);
    if (n == 1) return graph;

    final rng = seed != null ? math.Random(seed) : math.Random();

    for (var i = 1; i < n; i++) {
      graph.addNode(i);
      final parent = rng.nextInt(i);
      graph.addEdge(i, parent, data: 1);
    }

    return graph;
  }

  /// Generates a random d-regular graph on [n] nodes.
  static SimpleGraph<void, int> randomRegular(
    int n,
    int d, {
    GraphKind kind = GraphKind.undirected,
    int? seed,
  }) {
    final graph = kind == GraphKind.directed
        ? SimpleGraph<void, int>.directed()
        : SimpleGraph<void, int>.undirected();

    if (n <= 0 || d < 0 || d >= n) return graph;
    if ((n * d) % 2 != 0) return graph; // Must be even

    if (d == 0) {
      for (var i = 0; i < n; i++) {
        graph.addNode(i);
      }
      return graph;
    }

    final rng = seed != null ? math.Random(seed) : math.Random();

    // Configuration model with retries
    for (var retry = 0; retry < 100; retry++) {
      final stubs = <int>[];
      for (var i = 0; i < n; i++) {
        for (var j = 0; j < d; j++) {
          stubs.add(i);
        }
      }

      stubs.shuffle(rng);

      final tempGraph = kind == GraphKind.directed
          ? SimpleGraph<void, int>.directed()
          : SimpleGraph<void, int>.undirected();

      for (var i = 0; i < n; i++) {
        tempGraph.addNode(i);
      }

      var success = true;
      for (var i = 0; i < stubs.length; i += 2) {
        final u = stubs[i];
        final v = stubs[i + 1];

        if (u == v || tempGraph.hasEdge(u, v)) {
          success = false;
          break;
        }

        tempGraph.addEdge(u, v, data: 1);
      }

      if (success) {
        return tempGraph;
      }
    }

    // Fallback: just return empty graph on failure
    for (var i = 0; i < n; i++) {
      graph.addNode(i);
    }
    return graph;
  }
}
