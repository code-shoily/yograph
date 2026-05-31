import '../model/roles.dart';
import '../model/graph_kind.dart';
import '../traversal/traversal.dart';

/// Graph cyclicity and Directed Acyclic Graph (DAG) analysis.
abstract final class Cyclicity {
  const Cyclicity._();

  /// Checks if the graph is acyclic.
  static bool isAcyclic<N, E>(Bidirectional<N, E> graph) {
    return !isCyclic(graph);
  }

  /// Checks if the graph contains at least one cycle.
  static bool isCyclic<N, E>(Bidirectional<N, E> graph) {
    if (graph.kind == GraphKind.directed) {
      return topologicalSort(graph) == null;
    } else {
      final visited = <int>{};
      final nodes = graph.nodeIds.toList();

      bool dfs(int u, int? parent) {
        visited.add(u);
        for (final v in graph.successors(u)) {
          if (v == parent) continue;
          if (visited.contains(v)) return true;
          if (dfs(v, u)) return true;
        }
        return false;
      }

      for (final node in nodes) {
        if (!visited.contains(node)) {
          if (dfs(node, null)) return true;
        }
      }
      return false;
    }
  }
}
