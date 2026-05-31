/// K-core decomposition.
///
/// A k-core is the maximal subgraph where every node has degree ≥ k.
/// The core number of a node is the largest k for which it belongs to a
/// k-core.
library;

import '../model/graph_kind.dart';
import '../model/roles.dart';
import '../simple_graph.dart';

/// K-core decomposition algorithms.
abstract final class KCore {
  const KCore._();

  /// Returns the maximal subgraph where every node has degree ≥ [k].
  ///
  /// Nodes with fewer than [k] neighbors are iteratively pruned.
  ///
  /// Time complexity: **O(V + E)**.
  static SimpleGraph<N, E> detect<N, E>(Bidirectional<N, E> graph, int k) {
    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) {
      return graph.kind == GraphKind.undirected
          ? SimpleGraph<N, E>.undirected()
          : SimpleGraph<N, E>.directed();
    }

    final degrees = <int, int>{};
    final queue = <int>[];
    final removed = <int>{};

    for (final node in nodes) {
      final deg = _degree(graph, node);
      degrees[node] = deg;
      if (deg < k) {
        queue.add(node);
        removed.add(node);
      }
    }

    var head = 0;
    while (head < queue.length) {
      final u = queue[head++];
      for (final v in graph.successors(u)) {
        if (removed.contains(v)) continue;
        final newDeg = degrees[v]! - 1;
        degrees[v] = newDeg;
        if (newDeg < k && !removed.contains(v)) {
          queue.add(v);
          removed.add(v);
        }
      }
      if (graph.kind == GraphKind.directed) {
        for (final v in graph.predecessors(u)) {
          if (removed.contains(v)) continue;
          final newDeg = degrees[v]! - 1;
          degrees[v] = newDeg;
          if (newDeg < k && !removed.contains(v)) {
            queue.add(v);
            removed.add(v);
          }
        }
      }
    }

    final remaining = nodes.where((n) => !removed.contains(n)).toSet();
    final subgraph = graph.kind == GraphKind.undirected
        ? SimpleGraph<N, E>.undirected()
        : SimpleGraph<N, E>.directed();

    for (final u in remaining) {
      subgraph.addNode(u);
      for (final v in graph.successors(u)) {
        if (remaining.contains(v) && graph.hasEdge(u, v)) {
          final data = graph.edgeData(u, v);
          subgraph.addEdge(u, v, data: data);
        }
      }
    }

    return subgraph;
  }

  /// Core number for every node.
  ///
  /// The core number is the largest k such that the node belongs to a
  /// k-core.
  ///
  /// Time complexity: **O(V + E)**.
  static Map<int, int> coreNumbers<N, E>(Bidirectional<N, E> graph) {
    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) return {};

    final degrees = <int, int>{};
    for (final node in nodes) {
      degrees[node] = _degree(graph, node);
    }

    // Bucket sort by degree
    final maxDeg = degrees.values.fold(0, (a, b) => a > b ? a : b);
    final buckets = List<List<int>>.generate(maxDeg + 1, (_) => []);
    for (final entry in degrees.entries) {
      buckets[entry.value].add(entry.key);
    }

    final binStart = List<int>.generate(maxDeg + 1, (i) => 0);
    var count = 0;
    for (var d = 0; d <= maxDeg; d++) {
      binStart[d] = count;
      count += buckets[d].length;
    }

    final pos = <int, int>{};
    final vert = List<int>.filled(nodes.length, 0);
    for (var d = 0; d <= maxDeg; d++) {
      for (final v in buckets[d]) {
        pos[v] = binStart[d];
        vert[binStart[d]] = v;
        binStart[d]++;
      }
    }

    // Restore binStart
    var acc = 0;
    for (var d = 0; d <= maxDeg; d++) {
      final size = buckets[d].length;
      binStart[d] = acc;
      acc += size;
    }

    final core = <int, int>{};

    for (var i = 0; i < nodes.length; i++) {
      final v = vert[i];
      core[v] = degrees[v]!;

      for (final u in _neighbors(graph, v)) {
        if (degrees[u]! > degrees[v]!) {
          final du = degrees[u]!;
          final pu = pos[u]!;
          final pw = binStart[du];
          final w = vert[pw];

          if (u != w) {
            pos[u] = pw;
            pos[w] = pu;
            vert[pu] = w;
            vert[pw] = u;
          }

          binStart[du]++;
          degrees[u] = du - 1;
        }
      }
    }

    return core;
  }

  /// Degeneracy — the maximum core number in the graph.
  ///
  /// Time complexity: **O(V + E)**.
  static int degeneracy<N, E>(Bidirectional<N, E> graph) {
    final cores = coreNumbers(graph);
    if (cores.isEmpty) return 0;
    return cores.values.reduce((a, b) => a > b ? a : b);
  }

  /// Shell decomposition — groups nodes by their core number.
  ///
  /// Returns a map `core_number => [nodes]`.
  ///
  /// Time complexity: **O(V + E)**.
  static Map<int, List<int>> shellDecomposition<N, E>(
    Bidirectional<N, E> graph,
  ) {
    final cores = coreNumbers(graph);
    final shells = <int, List<int>>{};
    for (final entry in cores.entries) {
      shells.putIfAbsent(entry.value, () => []).add(entry.key);
    }
    return shells;
  }

  // ========================================================================
  // Helpers
  // ========================================================================

  static int _degree<N, E>(Bidirectional<N, E> graph, int node) {
    if (graph.kind == GraphKind.undirected) {
      return graph.successors(node).length;
    }
    return graph.successors(node).length + graph.predecessors(node).length;
  }

  static Set<int> _neighbors<N, E>(Bidirectional<N, E> graph, int node) {
    final neighbors = <int>{...graph.successors(node)};
    if (graph.kind == GraphKind.directed) {
      neighbors.addAll(graph.predecessors(node));
    }
    return neighbors;
  }
}
