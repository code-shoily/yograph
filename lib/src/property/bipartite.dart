import 'dart:collection';
import '../model/roles.dart';

/// Bipartite graph analysis and matching algorithms.
abstract final class Bipartite {
  const Bipartite._();

  /// Determines if a graph is bipartite (2-colorable).
  static bool isBipartite<N, E>(Bidirectional<N, E> graph) {
    return partition(graph) != null;
  }

  /// Returns the two partitions of a bipartite graph, or null if not bipartite.
  ///
  /// Uses BFS with 2-coloring to detect bipartiteness and construct the partitions.
  /// Handles disconnected graphs by checking all components.
  static ({Set<int> left, Set<int> right})? partition<N, E>(
    Bidirectional<N, E> graph,
  ) {
    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) {
      return (left: <int>{}, right: <int>{});
    }

    final colors = <int, int>{}; // nodeId -> color (1 or 2)
    for (final node in nodes) {
      if (colors.containsKey(node)) continue;

      // BFS for this component
      final queue = Queue<int>()..add(node);
      colors[node] = 1;

      while (queue.isNotEmpty) {
        final u = queue.removeFirst();
        final currentColor = colors[u]!;
        final nextColor = currentColor == 1 ? 2 : 1;

        // Bipartiteness treat connections symmetrically (undirected check)
        final neighbors = graph.successors(u).toSet()
          ..addAll(graph.predecessors(u));

        for (final v in neighbors) {
          if (!colors.containsKey(v)) {
            colors[v] = nextColor;
            queue.add(v);
          } else if (colors[v] == currentColor) {
            return null; // Adjacent nodes have the same color, not bipartite
          }
        }
      }
    }

    final left = <int>{};
    final right = <int>{};
    colors.forEach((node, color) {
      if (color == 1) {
        left.add(node);
      } else {
        right.add(node);
      }
    });

    return (left: left, right: right);
  }

  /// Finds a 2-coloring of a graph if it is bipartite.
  /// Maps each nodeId to 0 or 1. Returns null if not bipartite.
  static Map<int, int>? coloring<N, E>(Bidirectional<N, E> graph) {
    final p = partition(graph);
    if (p == null) return null;
    final result = <int, int>{};
    for (final node in p.left) {
      result[node] = 0;
    }
    for (final node in p.right) {
      result[node] = 1;
    }
    return result;
  }

  /// Finds a maximum matching in a bipartite graph.
  ///
  /// A matching is a set of edges with no common vertices. A maximum matching
  /// has the largest possible number of edges.
  ///
  /// Uses the augmenting path algorithm (Hungarian algorithm for unweighted bipartite matching).
  /// Returns a list of matched pairs (left_node, right_node).
  static List<(int, int)> maximumMatching<N, E>(
    Bidirectional<N, E> graph,
    ({Set<int> left, Set<int> right}) partition,
  ) {
    final leftList = partition.left.toList();
    final rightSet = partition.right;

    final adj = <int, List<int>>{};
    for (final u in leftList) {
      final neighbors = graph.successors(u).toSet()
        ..addAll(graph.predecessors(u));
      adj[u] = neighbors.where((v) => rightSet.contains(v)).toList();
    }

    final matchR = <int, int>{}; // right_node -> left_node

    bool findAugmentingPath(int u, Set<int> visited) {
      final neighbors = adj[u] ?? const [];
      for (final v in neighbors) {
        if (visited.contains(v)) continue;
        visited.add(v);

        final matchL = matchR[v];
        if (matchL == null || findAugmentingPath(matchL, visited)) {
          matchR[v] = u;
          return true;
        }
      }
      return false;
    }

    for (final u in leftList) {
      findAugmentingPath(u, <int>{});
    }

    final matching = <(int, int)>[];
    matchR.forEach((v, u) {
      matching.add((u, v));
    });

    return matching;
  }

  /// Finds a stable matching given preference lists for two groups.
  ///
  /// Uses the Gale-Shapley algorithm to find a stable matching where no two people
  /// would both prefer each other over their current partners.
  ///
  /// The algorithm is "proposer-optimal" - it finds the best stable matching for
  /// the proposing group (left), and the worst stable matching for the receiving
  /// group (right).
  ///
  /// Returns a bidirectional mapping of matched pairs.
  static Map<Object, Object> stableMarriage<T extends Object, U extends Object>(
    Map<T, List<U>> leftPrefs,
    Map<U, List<T>> rightPrefs,
  ) {
    final rightPrefsIndexed = <U, Map<T, int>>{};
    rightPrefs.forEach((right, prefList) {
      final indexed = <T, int>{};
      for (var i = 0; i < prefList.length; i++) {
        indexed[prefList[i]] = i;
      }
      rightPrefsIndexed[right] = indexed;
    });

    final leftPrefsMutable = <T, List<U>>{
      for (final entry in leftPrefs.entries) entry.key: List.from(entry.value),
    };

    final freeLeft = leftPrefs.keys.toList();
    final matches = <U, T>{}; // right -> left

    while (freeLeft.isNotEmpty) {
      final left = freeLeft.removeLast();
      final prefs = leftPrefsMutable[left]!;
      if (prefs.isEmpty) continue;

      final preferred = prefs.removeAt(0);
      final currentLeft = matches[preferred];

      if (currentLeft == null) {
        matches[preferred] = left;
      } else {
        final rankMap = rightPrefsIndexed[preferred] ?? const {};
        final newRank = rankMap[left];
        final currentRank = rankMap[currentLeft];

        if (newRank != null && (currentRank == null || newRank < currentRank)) {
          matches[preferred] = left;
          freeLeft.add(currentLeft);
        } else {
          freeLeft.add(left);
        }
      }
    }

    final bidirectional = <Object, Object>{};
    matches.forEach((right, left) {
      bidirectional[left] = right;
      bidirectional[right] = left;
    });

    return bidirectional;
  }
}
