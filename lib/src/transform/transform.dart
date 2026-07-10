import '../model/graph_kind.dart';
import '../model/mutable.dart';
import '../model/roles.dart';
import '../property/cyclicity.dart';
import '../simple_graph.dart';
import '../traversal/traversal.dart';

/// Graph transformations.
///
/// This module provides structural transformations such as transitive closure
/// and transitive reduction.  Additional operations (subgraphs, unions,
/// products, etc.) may be added here over time.
abstract final class Transform {
  Transform._();

  /// Computes the transitive closure of [graph].
  ///
  /// Returns a reachability map where `result[u]` contains every node
  /// reachable from [u], including [u] itself.
  ///
  /// For DAGs the algorithm runs in `O(V + E)` by processing nodes in reverse
  /// topological order.  For cyclic graphs it falls back to a BFS from every
  /// node, which is `O(V × (V + E))`.
  ///
  /// **Time complexity:** `O(V + E)` for DAGs, `O(V × (V + E))` for cyclic graphs
  static Map<int, Set<int>> transitiveClosure<N, E>(Bidirectional<N, E> graph) {
    if (graph.nodeCount == 0) return const {};

    if (graph.kind == GraphKind.directed && Cyclicity.isAcyclic(graph)) {
      return _transitiveClosureDag(graph);
    }

    return _transitiveClosureGeneral(graph);
  }

  static Map<int, Set<int>> _transitiveClosureDag<N, E>(
    Bidirectional<N, E> graph,
  ) {
    final order = topologicalSort(graph)!;
    final closure = <int, Set<int>>{};

    for (var i = order.length - 1; i >= 0; i--) {
      final u = order[i];
      final reachable = <int>{u};
      for (final v in graph.successors(u)) {
        reachable.add(v);
        reachable.addAll(closure[v] ?? const {});
      }
      closure[u] = reachable;
    }

    return closure;
  }

  static Map<int, Set<int>> _transitiveClosureGeneral<N, E>(
    Bidirectional<N, E> graph,
  ) {
    final closure = <int, Set<int>>{};

    for (final start in graph.nodeIds) {
      final reachable = <int>{start};
      final queue = [start];
      final visited = <int>{start};

      while (queue.isNotEmpty) {
        final u = queue.removeLast();
        for (final v in graph.successors(u)) {
          if (visited.add(v)) {
            reachable.add(v);
            queue.add(v);
          }
        }
      }

      closure[start] = reachable;
    }

    return closure;
  }

  /// Computes the transitive reduction of a DAG.
  ///
  /// Returns a new graph containing only the edges of [graph] that are
  /// not implied by other paths.  Returns `null` when [graph] is not a DAG or
  /// is undirected.
  ///
  /// By default the result is a [SimpleGraph].  Pass [createGraph] to use a
  /// custom mutable graph backend instead.
  ///
  /// **Time complexity:** `O(V × E)`
  static Mutable<N, E>? transitiveReduction<N, E>(
    Bidirectional<N, E> graph, {
    GraphCreator<N, E>? createGraph,
  }) {
    if (graph.kind != GraphKind.directed || !Cyclicity.isAcyclic(graph)) {
      return null;
    }

    final nodes = graph.nodeIds.toList();
    final creator = createGraph ?? (_) => SimpleGraph<N, E>.directed();

    if (nodes.isEmpty) {
      return creator(GraphKind.directed);
    }

    final closure = _transitiveClosureDag(graph);
    final reduced = creator(GraphKind.directed);

    // Copy all nodes with their data.
    for (final u in nodes) {
      reduced.addNode(u, data: graph.nodeData(u));
    }

    for (final u in nodes) {
      final successors = graph.successors(u).toList();
      for (final v in successors) {
        // Edge u -> v is redundant if some other successor w of u can reach v.
        var redundant = false;
        for (final w in successors) {
          if (w == v) continue;
          if ((closure[w] ?? const {}).contains(v)) {
            redundant = true;
            break;
          }
        }
        if (!redundant) {
          reduced.addEdge(u, v, data: graph.edgeData(u, v));
        }
      }
    }

    return reduced;
  }
}
