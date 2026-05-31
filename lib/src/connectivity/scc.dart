/// Strongly-connected components.
///
/// Tarjan's single-pass DFS and Kosaraju's two-pass DFS.
library;

import '../model/roles.dart';

/// Strongly-connected component algorithms.
abstract final class SCC {
  const SCC._();

  // ========================================================================
  // Tarjan
  // ========================================================================

  /// Tarjan's strongly-connected components.
  ///
  /// Returns a list of SCCs, each a list of node IDs. The SCCs are in
  /// reverse topological order (dependencies before dependents).
  ///
  /// Time complexity: **O(V + E)**.
  static List<List<int>> tarjan<N, E>(Bidirectional<N, E> graph) {
    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) return [];

    var index = 0;
    final ids = <int, int>{};
    final low = <int, int>{};
    final onStack = <int>{};
    final stack = <int>[];
    final sccs = <List<int>>[];

    void strongConnect(int v) {
      ids[v] = index;
      low[v] = index;
      index++;
      stack.add(v);
      onStack.add(v);

      for (final w in graph.successors(v)) {
        if (!ids.containsKey(w)) {
          strongConnect(w);
          low[v] = low[v]! < low[w]! ? low[v]! : low[w]!;
        } else if (onStack.contains(w)) {
          low[v] = low[v]! < ids[w]! ? low[v]! : ids[w]!;
        }
      }

      if (low[v] == ids[v]) {
        final scc = <int>[];
        int w;
        do {
          w = stack.removeLast();
          onStack.remove(w);
          scc.add(w);
        } while (w != v);
        sccs.add(scc);
      }
    }

    for (final v in nodes) {
      if (!ids.containsKey(v)) {
        strongConnect(v);
      }
    }

    return sccs;
  }

  // ========================================================================
  // Kosaraju
  // ========================================================================

  /// Kosaraju's strongly-connected components.
  ///
  /// Two-pass DFS: first on the original graph to determine finish order,
  /// then on the transposed graph in reverse finish order.
  ///
  /// Returns a list of SCCs in reverse topological order.
  ///
  /// Time complexity: **O(V + E)**.
  static List<List<int>> kosaraju<N, E>(Bidirectional<N, E> graph) {
    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) return [];

    // First pass: DFS on original graph to get finish order
    final visited = <int>{};
    final finishOrder = <int>[];

    void dfs1(int v) {
      visited.add(v);
      for (final w in graph.successors(v)) {
        if (!visited.contains(w)) {
          dfs1(w);
        }
      }
      finishOrder.add(v);
    }

    for (final v in nodes) {
      if (!visited.contains(v)) {
        dfs1(v);
      }
    }

    // Second pass: DFS on transposed graph in reverse finish order
    visited.clear();
    final sccs = <List<int>>[];

    void dfs2(int v, List<int> scc) {
      visited.add(v);
      scc.add(v);
      for (final w in graph.predecessors(v)) {
        if (!visited.contains(w)) {
          dfs2(w, scc);
        }
      }
    }

    for (var i = finishOrder.length - 1; i >= 0; i--) {
      final v = finishOrder[i];
      if (!visited.contains(v)) {
        final scc = <int>[];
        dfs2(v, scc);
        sccs.add(scc);
      }
    }

    return sccs;
  }
}
