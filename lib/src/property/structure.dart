/// Structural connectivity and shape predicates.
library;

import '../model/graph_kind.dart';
import '../model/roles.dart';
import '../disjoint_set.dart';
import '../connectivity/components.dart';
import '../connectivity/scc.dart';

/// Structural predicates for graphs.
///
/// All methods are pure functions that inspect the graph without
/// mutating it.
abstract final class Structure {
  const Structure._();

  // ========================================================================
  // Connectivity
  // ========================================================================

  /// Is the graph connected?
  ///
  /// For undirected graphs this means one connected component.
  /// For directed graphs this delegates to [stronglyConnected].
  static bool isConnected<N, E>(Bidirectional<N, E> graph) {
    if (graph.isEmpty) return true;
    if (graph.kind == GraphKind.undirected) {
      return Components.connectedComponents(graph).length == 1;
    }
    return isStronglyConnected(graph);
  }

  /// Is the graph strongly connected?
  ///
  /// For undirected graphs delegates to [isConnected].
  /// For directed graphs checks that the SCC decomposition yields a
  /// single component.
  static bool isStronglyConnected<N, E>(Bidirectional<N, E> graph) {
    if (graph.isEmpty) return true;
    if (graph.kind == GraphKind.undirected) {
      return isConnected(graph);
    }
    return SCC.tarjan(graph).length == 1;
  }

  /// Is the graph weakly connected?
  ///
  /// For undirected graphs delegates to [isConnected].
  /// For directed graphs checks that the weakly-connected decomposition
  /// yields a single component.
  static bool isWeaklyConnected<N, E>(Bidirectional<N, E> graph) {
    if (graph.isEmpty) return true;
    if (graph.kind == GraphKind.undirected) {
      return isConnected(graph);
    }
    return Components.weaklyConnectedComponents(graph).length == 1;
  }

  // ========================================================================
  // Trees & Forests
  // ========================================================================

  /// Is the graph a tree?
  ///
  /// An undirected tree has exactly `n - 1` edges, is connected, and has
  /// no cycles.
  static bool isTree<N, E>(Bidirectional<N, E> graph) {
    if (graph.kind != GraphKind.undirected) return false;
    final n = graph.nodeCount;
    if (n == 0) return false;
    // Count edges: in undirected graph each edge stored twice
    var edgeCount = 0;
    for (final node in graph.nodeIds) {
      edgeCount += graph.successors(node).length;
    }
    edgeCount ~/= 2;
    return edgeCount == n - 1 && isConnected(graph);
  }

  /// Is the graph a forest?
  ///
  /// An undirected forest has `n - c` edges where `c` is the number of
  /// connected components, and contains no cycles.
  static bool isForest<N, E>(Bidirectional<N, E> graph) {
    if (graph.kind != GraphKind.undirected) return false;
    final n = graph.nodeCount;
    if (n == 0) return true;
    var edgeCount = 0;
    for (final node in graph.nodeIds) {
      edgeCount += graph.successors(node).length;
    }
    edgeCount ~/= 2;
    final c = Components.connectedComponents(graph).length;
    return edgeCount == n - c;
  }

  /// Is the directed graph an arborescence?
  ///
  /// A directed arborescence has exactly `n - 1` edges, exactly one root
  /// (in-degree 0), and every other node has in-degree 1.
  static bool isArborescence<N, E>(Bidirectional<N, E> graph) {
    if (graph.kind != GraphKind.directed) return false;
    final n = graph.nodeCount;
    if (n == 0) return false;
    var edgeCount = 0;
    var rootCount = 0;
    for (final node in graph.nodeIds) {
      edgeCount += graph.successors(node).length;
      if (graph.inDegree(node) == 0) rootCount++;
      if (graph.inDegree(node) > 1) return false;
    }
    return edgeCount == n - 1 && rootCount == 1;
  }

  /// The root of an arborescence, or `null` if not an arborescence.
  static int? arborescenceRoot<N, E>(Bidirectional<N, E> graph) {
    if (graph.kind != GraphKind.directed) return null;
    int? root;
    for (final node in graph.nodeIds) {
      if (graph.inDegree(node) == 0) {
        if (root != null) return null; // multiple roots
        root = node;
      }
    }
    return root;
  }

  /// Is the directed graph a branching?
  ///
  /// A branching is a forest of arborescences: every node has in-degree
  /// ≤ 1 and there are no undirected cycles.
  static bool isBranching<N, E>(Bidirectional<N, E> graph) {
    if (graph.kind != GraphKind.directed) return false;
    for (final node in graph.nodeIds) {
      if (graph.inDegree(node) > 1) return false;
    }
    // Check no undirected cycles using union-find on edges
    final ds = DisjointSet<int>();
    for (final node in graph.nodeIds) {
      ds.add(node);
      for (final succ in graph.successors(node)) {
        ds.add(succ);
        if (ds.connected(node, succ)) return false;
        ds.union(node, succ);
      }
    }
    return true;
  }

  // ========================================================================
  // Regularity & Completeness
  // ========================================================================

  /// Is the graph complete?
  ///
  /// Every pair of distinct nodes is connected by an edge.
  static bool isComplete<N, E>(Bidirectional<N, E> graph) {
    final n = graph.nodeCount;
    if (n <= 1) return true;

    if (graph.kind == GraphKind.undirected) {
      final expected = n * (n - 1) ~/ 2;
      var edgeCount = 0;
      for (final node in graph.nodeIds) {
        edgeCount += graph.successors(node).length;
      }
      edgeCount ~/= 2;
      if (edgeCount != expected) return false;
      // Verify no self-loops
      for (final node in graph.nodeIds) {
        if (graph.successors(node).contains(node)) return false;
      }
      return true;
    } else {
      final expected = n * (n - 1);
      var edgeCount = 0;
      for (final node in graph.nodeIds) {
        edgeCount += graph.successors(node).length;
      }
      return edgeCount == expected;
    }
  }

  /// Is the graph [k]-regular?
  ///
  /// Every node has degree exactly [k]. For directed graphs this checks
  /// the total degree (in + out).
  static bool isRegular<N, E>(Bidirectional<N, E> graph, int k) {
    for (final node in graph.nodeIds) {
      final deg = graph.kind == GraphKind.undirected
          ? graph.successors(node).length
          : graph.successors(node).length + graph.predecessors(node).length;
      if (deg != k) return false;
    }
    return true;
  }

  /// Minimum degree among all nodes.
  static int minimumDegree<N, E>(Bidirectional<N, E> graph) {
    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) return 0;

    var min = graph.kind == GraphKind.undirected
        ? graph.successors(nodes.first).length
        : graph.successors(nodes.first).length +
              graph.predecessors(nodes.first).length;

    for (final node in nodes.skip(1)) {
      final deg = graph.kind == GraphKind.undirected
          ? graph.successors(node).length
          : graph.successors(node).length + graph.predecessors(node).length;
      if (deg < min) min = deg;
    }
    return min;
  }

  // ========================================================================
  // Chordality
  // ========================================================================

  /// Is the undirected graph chordal?
  ///
  /// A chordal graph is one in which every cycle of length ≥ 4 has a
  /// chord. Uses Maximum Cardinality Search (MCS) to compute a Perfect
  /// Elimination Order (PEO) and verifies it.
  ///
  /// Time complexity: **O(V + E)**.
  static bool isChordal<N, E>(Bidirectional<N, E> graph) {
    if (graph.kind != GraphKind.undirected) return false;
    final n = graph.nodeCount;
    if (n <= 2) return true;

    final nodes = graph.nodeIds.toList();

    // MCS: bucket queue by weight
    final weight = <int, int>{for (final v in nodes) v: 0};
    final order = <int>[];
    final numbered = <int>{};

    while (order.length < n) {
      // Find unnumbered node with max weight
      var maxW = -1;
      int? best;
      for (final v in nodes) {
        if (!numbered.contains(v) && weight[v]! > maxW) {
          maxW = weight[v]!;
          best = v;
        }
      }
      if (best == null) break;

      final v = best;
      numbered.add(v);
      order.add(v);

      for (final u in graph.successors(v)) {
        if (!numbered.contains(u)) {
          weight[u] = weight[u]! + 1;
        }
      }
    }

    // Verify PEO
    final position = <int, int>{};
    for (var i = 0; i < order.length; i++) {
      position[order[i]] = i;
    }

    for (final v in nodes) {
      final pv = position[v]!;
      int? parent;
      var parentPos = -1;

      // Find the earlier neighbor with the largest position
      for (final u in graph.successors(v)) {
        final pu = position[u]!;
        if (pu < pv && pu > parentPos) {
          parentPos = pu;
          parent = u;
        }
      }

      if (parent != null) {
        // All other earlier neighbors must be adjacent to parent
        for (final u in graph.successors(v)) {
          final pu = position[u]!;
          if (pu < pv && u != parent) {
            if (!graph.successors(parent).contains(u) &&
                !graph.successors(u).contains(parent)) {
              return false;
            }
          }
        }
      }
    }

    return true;
  }
}
