import '../model/roles.dart';
import '../model/graph_kind.dart';
import '../connectivity/components.dart';

/// Eulerian path and circuit algorithms using Hierholzer's algorithm.
abstract final class Eulerian {
  const Eulerian._();

  /// Checks if all nodes with degree > 0 are weakly connected.
  static bool _isConnected<N, E>(Bidirectional<N, E> graph) {
    final components = Components.weaklyConnectedComponents(graph);
    var nonIsolatedCount = 0;
    for (final comp in components) {
      var hasEdges = false;
      for (final node in comp) {
        if (graph.successors(node).isNotEmpty ||
            graph.predecessors(node).isNotEmpty) {
          hasEdges = true;
          break;
        }
      }
      if (hasEdges) {
        nonIsolatedCount++;
      }
    }
    return nonIsolatedCount <= 1;
  }

  /// Checks if the graph contains an Eulerian circuit.
  static bool hasEulerianCircuit<N, E>(Bidirectional<N, E> graph) {
    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) return false;

    if (graph.kind == GraphKind.undirected) {
      for (final node in nodes) {
        if (graph.successors(node).length % 2 != 0) return false;
      }
    } else {
      for (final node in nodes) {
        if (graph.successors(node).length != graph.predecessors(node).length) {
          return false;
        }
      }
    }
    return _isConnected(graph);
  }

  /// Checks if the graph contains an Eulerian path.
  static bool hasEulerianPath<N, E>(Bidirectional<N, E> graph) {
    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) return false;

    if (graph.kind == GraphKind.undirected) {
      var oddCount = 0;
      for (final node in nodes) {
        if (graph.successors(node).length % 2 != 0) oddCount++;
      }
      if (oddCount != 0 && oddCount != 2) return false;
    } else {
      var starts = 0;
      var ends = 0;
      for (final node in nodes) {
        final diff =
            graph.successors(node).length - graph.predecessors(node).length;
        if (diff == 1) {
          starts++;
        } else if (diff == -1) {
          ends++;
        } else if (diff != 0) {
          return false;
        }
      }
      if (!((starts == 0 && ends == 0) || (starts == 1 && ends == 1))) {
        return false;
      }
    }
    return _isConnected(graph);
  }

  /// Finds an Eulerian circuit in the graph using Hierholzer's algorithm.
  /// Returns null if no circuit exists.
  static List<int>? eulerianCircuit<N, E>(Bidirectional<N, E> graph) {
    if (!hasEulerianCircuit(graph)) return null;
    final start = graph.nodeIds.first;
    return _hierholzer(graph, start);
  }

  /// Finds an Eulerian path in the graph using Hierholzer's algorithm.
  /// Returns null if no path exists.
  static List<int>? eulerianPath<N, E>(Bidirectional<N, E> graph) {
    if (hasEulerianCircuit(graph)) {
      return eulerianCircuit(graph);
    }
    if (!hasEulerianPath(graph)) return null;

    int start = graph.nodeIds.first;
    if (graph.kind == GraphKind.undirected) {
      for (final node in graph.nodeIds) {
        if (graph.successors(node).length % 2 == 1) {
          start = node;
          break;
        }
      }
    } else {
      for (final node in graph.nodeIds) {
        if (graph.successors(node).length - graph.predecessors(node).length ==
            1) {
          start = node;
          break;
        }
      }
    }

    return _hierholzer(graph, start);
  }

  static List<int> _hierholzer<N, E>(Bidirectional<N, E> graph, int start) {
    // Hierholzer's algorithm
    final adj = <int, List<int>>{
      for (final u in graph.nodeIds) u: graph.successors(u).toList(),
    };

    final edgeCounts = <String, int>{};
    for (final u in graph.nodeIds) {
      for (final v in adj[u]!) {
        final key = '$u->$v';
        edgeCounts[key] = (edgeCounts[key] ?? 0) + 1;
      }
    }

    final path = <int>[];
    final stack = [start];

    while (stack.isNotEmpty) {
      final u = stack.last;
      var found = false;

      final neighbors = adj[u]!;
      while (neighbors.isNotEmpty) {
        final v = neighbors.removeLast();
        final key = '$u->$v';
        final count = edgeCounts[key] ?? 0;

        if (count > 0) {
          edgeCounts[key] = count - 1;
          if (graph.kind == GraphKind.undirected) {
            final revKey = '$v->$u';
            edgeCounts[revKey] = (edgeCounts[revKey] ?? 0) - 1;
          }
          stack.add(v);
          found = true;
          break;
        }
      }

      if (!found) {
        path.add(stack.removeLast());
      }
    }

    return path.reversed.toList();
  }
}
