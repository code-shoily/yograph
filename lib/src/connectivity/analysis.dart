/// Bridge and articulation-point detection.
///
/// Single DFS with discovery times and low-link values.
library;

import '../model/traversable.dart';

/// Result of [Analysis.analyze].
class ConnectivityAnalysis {
  /// Bridges as canonicalised `(min, max)` pairs.
  final List<(int, int)> bridges;

  /// Articulation points.
  final Set<int> articulationPoints;

  const ConnectivityAnalysis({
    required this.bridges,
    required this.articulationPoints,
  });
}

/// Bridge and articulation-point detection.
abstract final class Analysis {
  const Analysis._();

  /// Find all bridges and articulation points in an undirected graph.
  ///
  /// Uses a single DFS with discovery times and low-link values.
  ///
  /// * **Bridge**: an edge whose removal increases the number of connected
  ///   components. Detected when `low[neighbor] > disc[node]`.
  /// * **Articulation point**: a node whose removal increases the number of
  ///   connected components.
  ///
  /// Bridges are canonicalised as `(min, max)` and sorted.
  ///
  /// Time complexity: **O(V + E)**.
  static ConnectivityAnalysis analyze<N, E>(Traversable graph) {
    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) {
      return const ConnectivityAnalysis(bridges: [], articulationPoints: {});
    }

    final disc = <int, int>{};
    final low = <int, int>{};
    final parent = <int, int?>{};
    final bridges = <(int, int)>[];
    final ap = <int>{};
    var time = 0;

    void dfs(int u) {
      disc[u] = time;
      low[u] = time;
      time++;

      var childCount = 0;

      for (final v in graph.successors(u)) {
        if (!disc.containsKey(v)) {
          childCount++;
          parent[v] = u;
          dfs(v);

          low[u] = low[u]! < low[v]! ? low[u]! : low[v]!;

          // Bridge condition
          if (low[v]! > disc[u]!) {
            bridges.add(u < v ? (u, v) : (v, u));
          }

          // Articulation point (non-root)
          if (parent[u] != null && low[v]! >= disc[u]!) {
            ap.add(u);
          }
        } else if (v != parent[u]) {
          // Back edge
          low[u] = low[u]! < disc[v]! ? low[u]! : disc[v]!;
        }
      }

      // Articulation point (root)
      if (parent[u] == null && childCount > 1) {
        ap.add(u);
      }
    }

    for (final node in nodes) {
      if (!disc.containsKey(node)) {
        dfs(node);
      }
    }

    bridges.sort((a, b) {
      final cmp = a.$1.compareTo(b.$1);
      return cmp != 0 ? cmp : a.$2.compareTo(b.$2);
    });

    return ConnectivityAnalysis(bridges: bridges, articulationPoints: ap);
  }
}
