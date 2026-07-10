/// Brandes' algorithm for betweenness centrality.
library;

///
/// Shared implementation of Dijkstra-based shortest-path discovery
/// and dependency accumulation used by betweenness centrality and
/// edge-betweenness-based community detection.
///
/// See Brandes (2001), "A Faster Algorithm for Betweenness Centrality"
/// Journal of Mathematical Sociology 25(2):163-177.

import '../internal/priority_queue.dart';
import '../model/roles.dart';
import '../model/weight_algebra.dart';
import '../pathfinding/a_star.dart';

/// The three artifacts produced by the discovery phase.
class BrandesDiscovery {
  /// Nodes in non-increasing order of distance from the source.
  final List<int> stack;

  /// Shortest-path predecessors for every node.
  final Map<int, List<int>> predecessors;

  /// Number of shortest paths from the source to each node.
  final Map<int, int> sigmas;

  const BrandesDiscovery(this.stack, this.predecessors, this.sigmas);
}

/// Shared Brandes shortest-path discovery + dependency accumulation.
abstract final class Brandes {
  const Brandes._();

  /// Run the discovery phase from [source].
  ///
  /// This is Dijkstra with additional tracking of:
  /// * shortest-path counts (sigma)
  /// * shortest-path predecessors (pred)
  /// * processing order (stack)
  static BrandesDiscovery runDiscovery<N, E>(
    WeightedWalkable<N, E> graph,
    int source, {
    WeightAlgebra<E>? algebra,
  }) {
    final alg = resolveAlgebra<E>(algebra);
    final pq = PriorityQueue<(double, E, int)>(
      (a, b) => alg.compare(a.$2, b.$2),
    );
    pq.push((alg.toDouble(alg.zero), alg.zero, source));

    final dist = <int, E>{source: alg.zero};
    final sigma = <int, int>{source: 1};
    final preds = <int, List<int>>{};
    final stack = <int>[];

    while (pq.isNotEmpty) {
      final (_, dV, v) = pq.pop()!;

      // Skip stale entries (lazy deletion)
      final best = dist[v];
      if (best != null && alg.compare(dV, best) > 0) continue;

      stack.add(v);

      for (final w in graph.successors(v)) {
        final weight = edgeValue(graph, v, w, alg);
        final newDist = alg.add(dV, weight);
        final oldDist = dist[w];

        if (oldDist == null || alg.compare(newDist, oldDist) < 0) {
          // Found a strictly shorter path
          dist[w] = newDist;
          sigma[w] = sigma[v] ?? 0;
          preds[w] = [v];
          pq.push((alg.toDouble(newDist), newDist, w));
        } else if (alg.compare(newDist, oldDist) == 0) {
          // Found an alternative shortest path
          sigma[w] = (sigma[w] ?? 0) + (sigma[v] ?? 0);
          preds[w] = [...(preds[w] ?? []), v];
        }
      }
    }

    return BrandesDiscovery(stack, preds, sigma);
  }

  /// Accumulate node-level dependency deltas for standard betweenness.
  ///
  /// Returns a map of `node_id => dependency_delta` for the single
  /// source that produced [discovery].
  static Map<int, double> accumulateNodeDependencies(
    BrandesDiscovery discovery,
  ) {
    final stack = discovery.stack;
    final preds = discovery.predecessors;
    final sigmas = discovery.sigmas;
    final delta = <int, double>{};

    for (var i = stack.length - 1; i >= 0; i--) {
      final v = stack[i];
      final sigmaV = sigmas[v]?.toDouble() ?? 0.0;
      final deltaV = delta[v] ?? 0.0;
      final vPreds = preds[v] ?? const <int>[];

      for (final u in vPreds) {
        final sigmaU = sigmas[u]?.toDouble() ?? 0.0;
        final c = (sigmaU / sigmaV) * (1.0 + deltaV);
        delta[u] = (delta[u] ?? 0.0) + c;
      }
    }

    return delta;
  }

  /// Accumulate edge-level dependency deltas for edge betweenness.
  ///
  /// Returns a map of `(from, to) => dependency_delta` for the single
  /// source. Undirected edges are canonicalised as `(min, max)`.
  static Map<(int, int), double> accumulateEdgeDependencies(
    BrandesDiscovery discovery,
  ) {
    final stack = discovery.stack;
    final preds = discovery.predecessors;
    final sigmas = discovery.sigmas;
    final nodeDelta = <int, double>{};
    final edgeDelta = <(int, int), double>{};

    for (var i = stack.length - 1; i >= 0; i--) {
      final v = stack[i];
      final sigmaV = sigmas[v]?.toDouble() ?? 0.0;
      final deltaV = nodeDelta[v] ?? 0.0;
      final vPreds = preds[v] ?? const <int>[];

      for (final u in vPreds) {
        final sigmaU = sigmas[u]?.toDouble() ?? 0.0;
        final c = (sigmaU / sigmaV) * (1.0 + deltaV);
        nodeDelta[u] = (nodeDelta[u] ?? 0.0) + c;

        final edge = u < v ? (u, v) : (v, u);
        edgeDelta[edge] = c;
      }
    }

    return edgeDelta;
  }
}
