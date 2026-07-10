import '../internal/priority_queue.dart';
import '../model/roles.dart';
import '../model/weight_algebra.dart';
import '../path.dart';
import '_utils.dart';
import 'a_star.dart';
import 'strategy.dart';

/// Dijkstra's algorithm for single-source shortest paths.
///
/// Works with any edge type [E] via [WeightAlgebra<E>].
/// Defaults to [DoubleAlgebra] when [E] is `double`, preserving the
/// existing API without any code changes at call sites.
///
/// **Requirements:**
/// - All edge weights must be non-negative. If the graph contains negative edge
///   weights, the algorithm may produce incorrect results because it assumes that
///   a node's shortest path distance is finalized when it is popped from the priority queue.
///   For graphs with negative edge weights, use [BellmanFord] or [FloydWarshall].
///
/// ```dart
/// // Unchanged existing usage:
/// final path = Dijkstra.shortestPath(graph, 0, 5);
/// final dists = Dijkstra.singleSourceDistances(graph, 0);
///
/// // Custom algebra:
/// final path = Dijkstra.shortestPath(graph, 0, 5, algebra: RoadByKm.instance);
/// ```
class Dijkstra implements PointToPointStrategy {
  const Dijkstra();

  @override
  Path<E>? find<N, E>(
    WeightedWalkable<N, E> graph,
    int from,
    int to, {
    WeightAlgebra<E>? algebra,
  }) {
    return shortestPath(graph, from, to, algebra: algebra);
  }

  /// Finds the shortest path from [from] to [to].
  ///
  /// Delegates to [AStar.aStar] with a zero heuristic.
  ///
  /// **Time complexity:** O((V + E) log V)
  static Path<E>? shortestPath<N, E>(
    WeightedWalkable<N, E> graph,
    int from,
    int to, {
    WeightAlgebra<E>? algebra,
  }) {
    return AStar.aStar(
      graph,
      from,
      to,
      heuristic: (_, _) => 0.0,
      algebra: algebra,
    );
  }

  /// Computes single-source shortest distances from [from] to every
  /// reachable node.
  ///
  /// Returns a `Map<int, E>` of typed distances.  Returns an empty map when
  /// [from] is not in the graph.
  ///
  /// **Time complexity:** O((V + E) log V)
  static Map<int, E> singleSourceDistances<N, E>(
    WeightedWalkable<N, E> graph,
    int from, {
    WeightAlgebra<E>? algebra,
  }) {
    if (!graph.hasNode(from)) return {};
    final alg = resolveAlgebra<E>(algebra);

    final pq = PriorityQueue<(double dist, int node)>(
      (a, b) => a.$1.compareTo(b.$1),
    );
    pq.push((0.0, from));

    final distances = <int, double>{from: 0.0};
    final distTyped = <int, E>{from: alg.zero};

    while (pq.isNotEmpty) {
      final (dist, node) = pq.pop()!;

      final bestDist = distances[node];
      if (bestDist == null || dist > bestDist) continue;

      final typedDist = distTyped[node];
      if (typedDist == null) continue;

      for (final succ in graph.successors(node)) {
        final edgeRaw = edgeValue(graph, node, succ, alg);
        final newTyped = alg.add(typedDist, edgeRaw);
        final newDist = alg.toDouble(newTyped);

        final existingDist = distances[succ];
        if (existingDist == null || newDist < existingDist) {
          distances[succ] = newDist;
          distTyped[succ] = newTyped;
          pq.push((newDist, succ));
        }
      }
    }

    return distTyped;
  }

  /// Finds the **widest path** (maximum-capacity path) from [from] to [to].
  ///
  /// The width of a path is the minimum edge weight along it.
  ///
  /// **Time complexity:** O((V + E) log V)
  static Path<E>? widestPath<N, E>(
    WeightedWalkable<N, E> graph,
    int from,
    int to, {
    WeightAlgebra<E>? algebra,
  }) {
    final alg = resolveAlgebra<E>(algebra);
    if (!graph.hasNode(from) || !graph.hasNode(to)) return null;
    if (from == to) return Path([from], alg.infinity);

    final pq = PriorityQueue<(E width, int node)>(
      (a, b) => alg.compare(b.$1, a.$1),
    );
    pq.push((alg.infinity, from));

    final widths = <int, E>{from: alg.infinity};
    final predecessors = <int, int>{};

    while (pq.isNotEmpty) {
      final (width, node) = pq.pop()!;

      final bestWidth = widths[node];
      if (bestWidth == null || alg.compare(width, bestWidth) < 0) continue;

      if (node == to) {
        return Path(reconstructPath(predecessors, to), width);
      }

      for (final succ in graph.successors(node)) {
        final edgeRaw = edgeValue(graph, node, succ, alg);
        final candidate = alg.compare(width, edgeRaw) < 0 ? width : edgeRaw;
        final existing = widths[succ];

        if (existing == null || alg.compare(candidate, existing) > 0) {
          widths[succ] = candidate;
          predecessors[succ] = node;
          pq.push((candidate, succ));
        }
      }
    }

    return null;
  }

  /// Runs Dijkstra on an implicit state space.
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
