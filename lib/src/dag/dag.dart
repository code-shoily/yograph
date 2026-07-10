import '../model/graph_kind.dart';
import '../model/roles.dart';
import '../model/weight_algebra.dart';
import '../path.dart';
import '../pathfinding/a_star.dart';
import '../property/cyclicity.dart';
import '../traversal/traversal.dart';

/// Directed-acyclic-graph utilities.
///
/// All methods in this class assume the input graph is a DAG.  If the graph
/// is undirected or contains a directed cycle, the methods that require a
/// topological order return `null`.
///
/// The algorithms run in linear time when possible, using a topological
/// ordering as the basis for dynamic programming.
abstract final class DAG {
  DAG._();

  /// Returns `true` when [graph] is directed and acyclic.
  static bool isDag<N, E>(Bidirectional<N, E> graph) =>
      graph.kind == GraphKind.directed && Cyclicity.isAcyclic(graph);

  /// Returns a topological ordering of the DAG, or `null` if the graph is
  /// not a DAG.
  ///
  /// This is a convenience wrapper around [topologicalSort].
  static List<int>? topologicalOrder<N, E>(Bidirectional<N, E> graph) =>
      isDag(graph) ? topologicalSort(graph) : null;

  /// Partitions the nodes of a DAG into generations.
  ///
  /// Each generation contains the nodes that can be processed after all
  /// previous generations have been removed.  Nodes in the same generation
  /// are independent of one another.  Returns `null` when [graph] is not a
  /// DAG.
  ///
  /// **Time complexity:** O(V + E)
  static List<List<int>>? topologicalGenerations<N, E>(
    Bidirectional<N, E> graph,
  ) {
    if (!isDag(graph)) return null;

    final inDegrees = <int, int>{
      for (final id in graph.nodeIds) id: graph.inDegree(id),
    };

    final generations = <List<int>>[];
    var current = <int>[
      for (final id in graph.nodeIds)
        if (inDegrees[id] == 0) id,
    ];

    while (current.isNotEmpty) {
      current.sort();
      generations.add(List<int>.from(current));

      final next = <int>[];
      for (final node in current) {
        for (final succ in graph.successors(node)) {
          final newDegree = (inDegrees[succ]! - 1);
          inDegrees[succ] = newDegree;
          if (newDegree == 0) next.add(succ);
        }
      }
      current = next;
    }

    return generations;
  }

  /// Returns the global critical path of a DAG.
  ///
  /// The path is a list of node IDs from some source to some sink with
  /// maximum total edge weight.  For unweighted graphs this is the longest
  /// path by edge count.  Returns `null` when [graph] is not a DAG; returns
  /// an empty list for an empty graph.
  ///
  /// **Time complexity:** O(V + E)
  static List<int>? longestPath<N, E>(
    Bidirectional<N, E> graph, {
    WeightAlgebra<E>? algebra,
  }) {
    if (!isDag(graph)) return null;
    final alg = resolveAlgebra<E>(algebra);
    final order = topologicalSort(graph)!;

    final distances = <int, E>{for (final id in graph.nodeIds) id: alg.zero};
    final predecessors = <int, int>{};

    for (final node in order) {
      final dist = distances[node];
      if (dist == null) continue;
      for (final succ in graph.successors(node)) {
        final weight = edgeValue(graph, node, succ, alg);
        final newDist = alg.add(dist, weight);
        final existingDist = distances[succ];
        if (existingDist == null || alg.compare(newDist, existingDist) > 0) {
          distances[succ] = newDist;
          predecessors[succ] = node;
        }
      }
    }

    if (graph.nodeCount == 0) return const [];

    var bestNode = graph.nodeIds.first;
    for (final entry in distances.entries) {
      final bestDist = distances[bestNode];
      if (bestDist != null && alg.compare(entry.value, bestDist) > 0) {
        bestNode = entry.key;
      }
    }

    return _reconstructNodeList(predecessors, bestNode);
  }

  /// Returns the longest path from [from] to [to] in a DAG.
  ///
  /// Returns `null` when [graph] is not a DAG, when either endpoint is
  /// missing, or when no path connects them.
  ///
  /// **Time complexity:** O(V + E)
  static Path<E>? longestPathNodes<N, E>(
    Bidirectional<N, E> graph,
    int from,
    int to, {
    WeightAlgebra<E>? algebra,
  }) {
    if (!isDag(graph)) return null;
    if (!graph.hasNode(from) || !graph.hasNode(to)) return null;
    final alg = resolveAlgebra<E>(algebra);
    if (from == to) return Path([from], alg.zero);

    final order = _orderFrom(graph, from);
    if (order == null) return null;

    final distances = <int, E>{from: alg.zero};
    final predecessors = <int, int>{};

    for (final node in order) {
      final dist = distances[node];
      if (dist == null) continue;

      for (final succ in graph.successors(node)) {
        final weight = edgeValue(graph, node, succ, alg);
        final newDist = alg.add(dist, weight);
        final currentDist = distances[succ];
        if (currentDist == null || alg.compare(newDist, currentDist) > 0) {
          distances[succ] = newDist;
          predecessors[succ] = node;
        }
      }
    }

    final targetDist = distances[to];
    if (targetDist == null) return null;

    return Path(_reconstructNodeList(predecessors, to), targetDist);
  }

  /// Returns the shortest path from [from] to [to] in a DAG.
  ///
  /// Returns `null` when [graph] is not a DAG, when either endpoint is
  /// missing, or when no path connects them.
  ///
  /// **Time complexity:** O(V + E)
  static Path<E>? shortestPath<N, E>(
    Bidirectional<N, E> graph,
    int from,
    int to, {
    WeightAlgebra<E>? algebra,
  }) {
    if (!isDag(graph)) return null;
    if (!graph.hasNode(from) || !graph.hasNode(to)) return null;
    final alg = resolveAlgebra<E>(algebra);
    if (from == to) return Path([from], alg.zero);

    final order = _orderFrom(graph, from);
    if (order == null) return null;

    final distances = <int, E>{from: alg.zero};
    final predecessors = <int, int>{};

    for (final node in order) {
      final dist = distances[node];
      if (dist == null) continue;

      for (final succ in graph.successors(node)) {
        final weight = edgeValue(graph, node, succ, alg);
        final newDist = alg.add(dist, weight);
        final currentDist = distances[succ];
        if (currentDist == null || alg.compare(newDist, currentDist) < 0) {
          distances[succ] = newDist;
          predecessors[succ] = node;
        }
      }
    }

    final targetDist = distances[to];
    if (targetDist == null) return null;

    return Path(_reconstructNodeList(predecessors, to), targetDist);
  }

  /// Computes single-source shortest distances from [from] in a DAG.
  ///
  /// The returned map contains an entry for [from] (distance [zero]) and
  /// every node reachable from it.  Returns an empty map when [from] is
  /// missing or when [graph] is not a DAG.
  ///
  /// **Time complexity:** O(V + E)
  static Map<int, E> singleSourceDistances<N, E>(
    Bidirectional<N, E> graph,
    int from, {
    WeightAlgebra<E>? algebra,
  }) {
    if (!isDag(graph)) return const {};
    if (!graph.hasNode(from)) return const {};
    final alg = resolveAlgebra<E>(algebra);

    final order = _orderFrom(graph, from);
    if (order == null) return const {};

    final distances = <int, E>{from: alg.zero};

    for (final node in order) {
      final dist = distances[node];
      if (dist == null) continue;

      for (final succ in graph.successors(node)) {
        final weight = edgeValue(graph, node, succ, alg);
        final newDist = alg.add(dist, weight);
        final currentDist = distances[succ];
        if (currentDist == null || alg.compare(newDist, currentDist) < 0) {
          distances[succ] = newDist;
        }
      }
    }

    return distances;
  }

  /// Returns all source nodes of the DAG (in-degree 0), sorted.
  ///
  /// Returns `null` when [graph] is not a DAG.
  static List<int>? sources<N, E>(Bidirectional<N, E> graph) {
    if (!isDag(graph)) return null;
    final result = <int>[
      for (final id in graph.nodeIds)
        if (graph.inDegree(id) == 0) id,
    ];
    result.sort();
    return result;
  }

  /// Returns all sink nodes of the DAG (no outgoing edges), sorted.
  ///
  /// Returns `null` when [graph] is not a DAG.
  static List<int>? sinks<N, E>(Bidirectional<N, E> graph) {
    if (!isDag(graph)) return null;
    final result = <int>[
      for (final id in graph.nodeIds)
        if (graph.successors(id).isEmpty) id,
    ];
    result.sort();
    return result;
  }

  /// Returns all ancestors of [node], including [node] itself.
  ///
  /// Returns `null` when [graph] is not a DAG or when [node] is missing.
  static List<int>? ancestors<N, E>(Bidirectional<N, E> graph, int node) {
    if (!isDag(graph)) return null;
    if (!graph.hasNode(node)) return null;

    final visited = <int>{node};
    final queue = [node];

    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      for (final pred in graph.predecessors(current)) {
        if (visited.add(pred)) queue.add(pred);
      }
    }

    return visited.toList()..sort();
  }

  /// Returns all descendants of [node], including [node] itself.
  ///
  /// Returns `null` when [graph] is not a DAG or when [node] is missing.
  static List<int>? descendants<N, E>(Bidirectional<N, E> graph, int node) {
    if (!isDag(graph)) return null;
    if (!graph.hasNode(node)) return null;

    final visited = <int>{node};
    final queue = [node];

    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      for (final succ in graph.successors(current)) {
        if (visited.add(succ)) queue.add(succ);
      }
    }

    return visited.toList()..sort();
  }

  /// Returns the lowest common ancestors of [a] and [b].
  ///
  /// A node is a lowest common ancestor if it is an ancestor of both [a]
  /// and [b], and no other common ancestor can reach it.  The result is
  /// sorted.  Returns `null` when [graph] is not a DAG or when either node
  /// is missing.
  ///
  /// **Time complexity:** O(V × (V + E)) worst case; typically much smaller.
  static List<int>? lowestCommonAncestors<N, E>(
    Bidirectional<N, E> graph,
    int a,
    int b,
  ) {
    if (!isDag(graph)) return null;
    if (!graph.hasNode(a) || !graph.hasNode(b)) return null;

    final ancestorsA = ancestors(graph, a)!;
    final ancestorsB = ancestors(graph, b)!;

    final common = <int>{...ancestorsA}..retainAll(ancestorsB);
    if (common.isEmpty) return const [];

    final result = <int>[];
    for (final candidate in common) {
      var dominated = false;
      for (final other in common) {
        if (other == candidate) continue;
        if (_canReach(graph, candidate, other)) {
          dominated = true;
          break;
        }
      }
      if (!dominated) result.add(candidate);
    }

    return result..sort();
  }

  /// Counts the number of distinct paths from [from] to [to] in a DAG.
  ///
  /// Returns `0` when [graph] is not a DAG, when either endpoint is missing,
  /// or when no path exists.  Returns `1` when [from] == [to] and the node
  /// exists.
  ///
  /// **Time complexity:** O(V + E)
  static int pathCount<N, E>(Bidirectional<N, E> graph, int from, int to) {
    if (!isDag(graph)) return 0;
    if (!graph.hasNode(from) || !graph.hasNode(to)) return 0;
    if (from == to) return 1;

    final order = _orderFrom(graph, from);
    if (order == null) return 0;

    final counts = <int, int>{from: 1};

    for (final node in order) {
      final count = counts[node];
      if (count == null) continue;

      for (final succ in graph.successors(node)) {
        counts[succ] = (counts[succ] ?? 0) + count;
      }
    }

    return counts[to] ?? 0;
  }

  /// Returns the suffix of a topological order starting at [from], or `null`
  /// if [from] is not present.
  static List<int>? _orderFrom<N, E>(Bidirectional<N, E> graph, int from) {
    final order = topologicalSort(graph);
    if (order == null) return null;

    final index = order.indexOf(from);
    if (index < 0) return null;

    return order.sublist(index);
  }

  /// Reconstructs a path by following predecessors back until there is none.
  static List<int> _reconstructNodeList(
    Map<int, int> predecessors,
    int target,
  ) {
    final path = <int>[target];
    var current = target;
    while (predecessors.containsKey(current)) {
      current = predecessors[current]!;
      path.add(current);
    }
    return path.reversed.toList();
  }

  /// Returns `true` when there is a directed path from [from] to [to].
  static bool _canReach<N, E>(Bidirectional<N, E> graph, int from, int to) {
    final visited = <int>{};
    final queue = [from];

    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (current == to) return true;
      if (!visited.add(current)) continue;

      for (final succ in graph.successors(current)) {
        if (!visited.contains(succ)) queue.add(succ);
      }
    }

    return false;
  }
}
