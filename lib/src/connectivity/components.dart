/// Connected and weakly-connected components.
library;

import '../model/roles.dart';
import '../model/traversable.dart';

/// Component-finding algorithms for undirected and directed graphs.
abstract final class Components {
  const Components._();

  /// Connected components of an undirected graph.
  ///
  /// Follows [Traversable.successors]; for an undirected graph this visits
  /// every neighbor and therefore yields true connected components.
  ///
  /// Time complexity: **O(V + E)**.
  static List<List<int>> connectedComponents<N, E>(Traversable graph) {
    final nodes = graph.nodeIds.toList();
    final visited = <int>{};
    final components = <List<int>>[];

    for (final start in nodes) {
      if (visited.contains(start)) continue;
      final component = <int>[];
      final stack = [start];
      visited.add(start);

      while (stack.isNotEmpty) {
        final node = stack.removeLast();
        component.add(node);
        for (final neighbor in graph.successors(node)) {
          if (!visited.contains(neighbor)) {
            visited.add(neighbor);
            stack.add(neighbor);
          }
        }
      }
      components.add(component);
    }

    return components;
  }

  /// Weakly-connected components of a directed graph.
  ///
  /// Treats the graph as undirected by traversing both successors and
  /// predecessors during the DFS.
  ///
  /// Time complexity: **O(V + E)**.
  static List<List<int>> weaklyConnectedComponents<N, E>(
    Bidirectional<N, E> graph,
  ) {
    final nodes = graph.nodeIds.toList();
    final visited = <int>{};
    final components = <List<int>>[];

    for (final start in nodes) {
      if (visited.contains(start)) continue;
      final component = <int>[];
      final stack = [start];
      visited.add(start);

      while (stack.isNotEmpty) {
        final node = stack.removeLast();
        component.add(node);
        for (final neighbor in graph.successors(node)) {
          if (!visited.contains(neighbor)) {
            visited.add(neighbor);
            stack.add(neighbor);
          }
        }
        for (final neighbor in graph.predecessors(node)) {
          if (!visited.contains(neighbor)) {
            visited.add(neighbor);
            stack.add(neighbor);
          }
        }
      }
      components.add(component);
    }

    return components;
  }
}
