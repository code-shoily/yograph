import '../internal/priority_queue.dart';
import '../model/roles.dart';
import '../path.dart';
import 'a_star.dart';
import 'strategy.dart';

/// Dijkstra's algorithm for single-source shortest paths.
///
/// Dijkstra finds the shortest path from a source node to all other
/// reachable nodes in a graph with non-negative edge weights.
///
/// ```dart
/// final path = Dijkstra.shortestPath(graph, 0, 5);
/// final dists = Dijkstra.singleSourceDistances(graph, 0);
/// ```
class Dijkstra implements PointToPointStrategy {
  const Dijkstra();

  @override
  Path? find<N, E>(
    WeightedWalkable<N, E> graph,
    int from,
    int to, {
    double zero = 0.0,
    double Function(double, double)? add,
    int Function(double, double)? compare,
  }) {
    return shortestPath(
      graph,
      from,
      to,
      zero: zero,
      add: add,
      compare: compare,
    );
  }

  /// Finds the shortest path from [from] to [to].
  ///
  /// Delegates to [AStar.aStar] with a zero heuristic, since Dijkstra is
  /// mathematically equivalent to A* with `heuristic(_, _) == 0`.
  ///
  /// Returns `null` when [from] or [to] does not exist, or when no path
  /// connects them.
  ///
  /// **Time complexity:** O((V + E) log V)
  static Path? shortestPath<N, E>(
    WeightedWalkable<N, E> graph,
    int from,
    int to, {
    double zero = 0.0,
    double Function(double, double)? add,
    int Function(double, double)? compare,
  }) {
    return AStar.aStar(
      graph,
      from,
      to,
      heuristic: (_, _) => zero,
      zero: zero,
      add: add,
      compare: compare,
    );
  }

  /// Computes single-source shortest distances from [from] to every
  /// reachable node.
  ///
  /// The returned map contains an entry for every node reachable from
  /// [from], including [from] itself (with distance [zero]).
  ///
  /// Returns an empty map when [from] is not present in the graph.
  ///
  /// **Time complexity:** O((V + E) log V)
  static Map<int, double> singleSourceDistances<N, E>(
    WeightedWalkable<N, E> graph,
    int from, {
    double zero = 0.0,
    double Function(double, double)? add,
    int Function(double, double)? compare,
  }) {
    if (!graph.hasNode(from)) return {};

    final addFn = add ?? defaultAdd;
    final compareFn = compare ?? defaultCompare;

    final pq = PriorityQueue<(double dist, int node)>(
      (a, b) => compareFn(a.$1, b.$1),
    );
    pq.push((zero, from));

    final distances = <int, double>{from: zero};

    while (pq.isNotEmpty) {
      final (dist, node) = pq.pop()!;

      final bestDist = distances[node];
      if (bestDist == null || compareFn(dist, bestDist) > 0) continue;

      for (final succ in graph.successors(node)) {
        final edgeCost = graph.edgeWeight(node, succ);
        final newDist = addFn(dist, edgeCost);

        final existingDist = distances[succ];
        if (existingDist == null || compareFn(newDist, existingDist) < 0) {
          distances[succ] = newDist;
          pq.push((newDist, succ));
        }
      }
    }

    return distances;
  }

  /// Finds the **widest path** (maximum-capacity path) from [from] to [to].
  ///
  /// The width of a path is the minimum edge weight along it.  This
  /// algorithm maximises that bottleneck.
  ///
  /// Returns `null` when [from] or [to] does not exist, or when no path
  /// connects them.
  ///
  /// **Time complexity:** O((V + E) log V)
  static Path? widestPath<N, E>(
    WeightedWalkable<N, E> graph,
    int from,
    int to,
  ) {
    return AStar.aStar(
      graph,
      from,
      to,
      heuristic: (_, _) => double.infinity,
      zero: double.infinity,
      add: (a, b) => a < b ? a : b,
      compare: (a, b) => b.compareTo(a),
    );
  }

  /// Runs Dijkstra on an implicit state space.
  ///
  /// Equivalent to [AStar.implicitAStar] with a zero heuristic.
  static (S state, double cost)? implicitDijkstra<S>({
    required S from,
    required Iterable<(S, double)> Function(S) successors,
    required bool Function(S) isGoal,
    double zero = 0.0,
    double Function(double, double)? add,
    int Function(double, double)? compare,
  }) {
    return AStar.implicitAStarBy(
      from: from,
      successors: successors,
      visitedBy: (s) => s,
      isGoal: isGoal,
      heuristic: (_) => zero,
      zero: zero,
      add: add,
      compare: compare,
    );
  }

  /// Runs Dijkstra on an implicit state space with a custom deduplication key.
  ///
  /// Equivalent to [AStar.implicitAStarBy] with a zero heuristic.
  static (S state, double cost)? implicitDijkstraBy<S, K>({
    required S from,
    required Iterable<(S, double)> Function(S) successors,
    required K Function(S) visitedBy,
    required bool Function(S) isGoal,
    double zero = 0.0,
    double Function(double, double)? add,
    int Function(double, double)? compare,
  }) {
    return AStar.implicitAStarBy(
      from: from,
      successors: successors,
      visitedBy: visitedBy,
      isGoal: isGoal,
      heuristic: (_) => zero,
      zero: zero,
      add: add,
      compare: compare,
    );
  }
}
