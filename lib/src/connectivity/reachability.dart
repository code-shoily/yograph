/// Reachability counting — exact ancestor / descendant counts.
///
/// For DAGs the algorithm uses dynamic programming on a topological order.
/// For cyclic graphs it first condenses SCCs into a DAG and then applies
/// the same DP.
library;

import '../model/roles.dart';
import '../simple_graph.dart';
import '../traversal/traversal.dart';
import 'scc.dart';

/// Exact reachability counts.
abstract final class Reachability {
  const Reachability._();

  /// Count ancestors or descendants for every node.
  ///
  /// * [direction] = ` ancestors`  → number of nodes that can reach this node.
  /// * [direction] = `descendants` → number of nodes reachable from this node.
  ///
  /// Time complexity: **O(V + E)** for DAGs, **O(V + E)** for general
  /// directed graphs (condensation + DP).
  static Map<int, int> counts<N, E>(
    Bidirectional<N, E> graph, {
    required ReachabilityDirection direction,
  }) {
    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) return {};

    // Try DAG fast path
    final topo = topologicalSort(graph);
    if (topo != null) {
      return _countsDag(graph, topo, direction);
    }

    // Cyclic graph: condense to DAG of SCCs
    return _countsCyclic(graph, direction);
  }

  // ========================================================================
  // DAG fast path
  // ========================================================================

  static Map<int, int> _countsDag<N, E>(
    Bidirectional<N, E> graph,
    List<int> topo,
    ReachabilityDirection direction,
  ) {
    final counts = <int, int>{};

    if (direction == ReachabilityDirection.descendants) {
      // Process in reverse topological order
      final reach = <int, Set<int>>{};
      for (var i = topo.length - 1; i >= 0; i--) {
        final v = topo[i];
        final r = <int>{...graph.successors(v)};
        for (final w in graph.successors(v)) {
          if (reach.containsKey(w)) {
            r.addAll(reach[w]!);
          }
        }
        reach[v] = r;
        counts[v] = r.length;
      }
    } else {
      // Ancestors: process in topological order
      final reach = <int, Set<int>>{};
      for (final v in topo) {
        final r = <int>{...graph.predecessors(v)};
        for (final w in graph.predecessors(v)) {
          if (reach.containsKey(w)) {
            r.addAll(reach[w]!);
          }
        }
        reach[v] = r;
        counts[v] = r.length;
      }
    }

    return counts;
  }

  // ========================================================================
  // Cyclic graph via SCC condensation
  // ========================================================================

  static Map<int, int> _countsCyclic<N, E>(
    Bidirectional<N, E> graph,
    ReachabilityDirection direction,
  ) {
    final sccs = SCC.tarjan(graph);
    final nodeToScc = <int, int>{};
    for (var i = 0; i < sccs.length; i++) {
      for (final node in sccs[i]) {
        nodeToScc[node] = i;
      }
    }

    // Build condensation DAG
    final cond = SimpleGraph<int, void>.directed();
    for (var i = 0; i < sccs.length; i++) {
      cond.addNode(i);
    }

    for (var i = 0; i < sccs.length; i++) {
      for (final u in sccs[i]) {
        for (final v in graph.successors(u)) {
          final j = nodeToScc[v]!;
          if (i != j && !cond.hasEdge(i, j)) {
            cond.addEdge(i, j);
          }
        }
      }
    }

    // Topologically sort the condensation DAG
    final topo = topologicalSort(cond);
    if (topo == null) {
      // Should not happen — condensation is always a DAG
      return {};
    }

    // DP on condensation DAG
    final sccReach = <int, Set<int>>{};
    if (direction == ReachabilityDirection.descendants) {
      for (var i = topo.length - 1; i >= 0; i--) {
        final v = topo[i];
        final r = <int>{...cond.successors(v)};
        for (final w in cond.successors(v)) {
          if (sccReach.containsKey(w)) {
            r.addAll(sccReach[w]!);
          }
        }
        sccReach[v] = r;
      }
    } else {
      for (final v in topo) {
        final r = <int>{...cond.predecessors(v)};
        for (final w in cond.predecessors(v)) {
          if (sccReach.containsKey(w)) {
            r.addAll(sccReach[w]!);
          }
        }
        sccReach[v] = r;
      }
    }

    // Map back to original nodes
    final counts = <int, int>{};
    for (final entry in nodeToScc.entries) {
      final node = entry.key;
      final sccIndex = entry.value;
      final sccSize = sccs[sccIndex].length;
      final reachableSccs = sccReach[sccIndex] ?? const <int>{};
      var count = 0;
      for (final rs in reachableSccs) {
        count += sccs[rs].length;
      }
      if (direction == ReachabilityDirection.descendants) {
        count += sccSize - 1; // internal reachable nodes
      } else {
        count += sccSize - 1; // internal reachable nodes
      }
      counts[node] = count;
    }

    return counts;
  }
}

/// Direction for [Reachability.counts].
enum ReachabilityDirection { ancestors, descendants }
