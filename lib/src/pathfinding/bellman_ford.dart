import '../model/roles.dart';
import '../path.dart';
import '_utils.dart';
import 'strategy.dart';

/// Result of a Bellman-Ford shortest-path query.
///
/// Three outcomes are possible:
/// * **Success** — [path] contains the shortest path and [hasNegativeCycle]
///   is `false`.
/// * **No path** — [path] is `null` and [hasNegativeCycle] is `false`.
/// * **Negative cycle** — [path] is `null` and [hasNegativeCycle] is `true`.
///
/// Use [isSuccess] to quickly check for a valid path.
class BellmanFordResult {
  /// The shortest path, or `null` when no path exists or a negative cycle
  /// was detected.
  final Path? path;

  /// `true` when a negative-weight cycle reachable from the source was
  /// detected.  In this case [path] is `null` and distances are undefined.
  final bool hasNegativeCycle;

  const BellmanFordResult._({this.path, required this.hasNegativeCycle});

  /// Successful query with a valid [path].
  factory BellmanFordResult.success(Path path) =>
      BellmanFordResult._(path: path, hasNegativeCycle: false);

  /// No path exists between the source and target.
  factory BellmanFordResult.noPath() =>
      const BellmanFordResult._(hasNegativeCycle: false);

  /// A negative cycle was detected; shortest paths are undefined.
  factory BellmanFordResult.negativeCycle() =>
      const BellmanFordResult._(hasNegativeCycle: true);

  /// `true` when a valid path was found.
  bool get isSuccess => path != null;

  @override
  String toString() {
    if (hasNegativeCycle) return 'BellmanFordResult(negativeCycle)';
    if (path == null) return 'BellmanFordResult(noPath)';
    return 'BellmanFordResult($path)';
  }
}

/// Bellman-Ford algorithm for single-source shortest paths.
///
/// Unlike Dijkstra, Bellman-Ford supports negative edge weights and can
/// detect negative cycles.  It runs in O(V × E) time.
///
/// ```dart
/// final result = BellmanFord.shortestPath(graph, 0, 3);
/// if (result.isSuccess) {
///   print(result.path!.weight);
/// } else if (result.hasNegativeCycle) {
///   print('Negative cycle detected!');
/// }
/// ```
class BellmanFord implements PointToPointStrategy {
  const BellmanFord();

  /// Strategy-compatible entry point.
  ///
  /// Throws [StateError] when a negative cycle is detected.
  @override
  Path? find<N, E>(
    WeightedWalkable<N, E> graph,
    int from,
    int to, {
    double zero = 0.0,
    double Function(double, double)? add,
    int Function(double, double)? compare,
  }) {
    final result = shortestPath(
      graph,
      from,
      to,
      zero: zero,
      add: add,
      compare: compare,
    );
    if (result.hasNegativeCycle) {
      throw StateError(
        'Negative cycle detected in graph. '
        'Use BellmanFord.shortestPath() to handle this case explicitly.',
      );
    }
    return result.path;
  }

  /// Finds the shortest path from [from] to [to] using Bellman-Ford.
  ///
  /// Returns a [BellmanFordResult] that distinguishes between success,
  /// no-path, and negative-cycle outcomes.
  ///
  /// **Time complexity:** O(V × E)
  static BellmanFordResult shortestPath<N, E>(
    WeightedWalkable<N, E> graph,
    int from,
    int to, {
    double zero = 0.0,
    double Function(double, double)? add,
    int Function(double, double)? compare,
  }) {
    if (!graph.hasNode(from) || !graph.hasNode(to)) {
      return BellmanFordResult.noPath();
    }
    if (from == to) {
      return BellmanFordResult.success(Path([from], zero));
    }

    final addFn = add ?? defaultAdd;
    final compareFn = compare ?? defaultCompare;

    final nodes = graph.nodeIds.toList();
    final nodeCount = nodes.length;

    final distances = <int, double>{from: zero};
    final predecessors = <int, int>{};

    // V-1 relaxation passes with early termination.
    for (var i = 0; i < nodeCount - 1; i++) {
      var changed = false;
      for (final u in nodes) {
        final distU = distances[u];
        if (distU == null) continue;

        for (final v in graph.successors(u)) {
          final weight = graph.edgeWeight(u, v);
          final newDist = addFn(distU, weight);
          final currentDist = distances[v];

          if (currentDist == null || compareFn(newDist, currentDist) < 0) {
            distances[v] = newDist;
            predecessors[v] = u;
            changed = true;
          }
        }
      }
      if (!changed) break;
    }

    // One more pass to detect negative cycles.
    for (final u in nodes) {
      final distU = distances[u];
      if (distU == null) continue;

      for (final v in graph.successors(u)) {
        final weight = graph.edgeWeight(u, v);
        final newDist = addFn(distU, weight);
        final currentDist = distances[v];

        if (currentDist == null || compareFn(newDist, currentDist) < 0) {
          return BellmanFordResult.negativeCycle();
        }
      }
    }

    final targetDist = distances[to];
    if (targetDist == null) {
      return BellmanFordResult.noPath();
    }

    return BellmanFordResult.success(
      Path(reconstructPath(predecessors, to), targetDist),
    );
  }

  /// Computes single-source shortest distances from [from] to every
  /// reachable node.
  ///
  /// Returns a map of node IDs to their shortest distance.  The map
  /// contains an entry for [from] (distance [zero]) and every reachable
  /// node.
  ///
  /// **Important:** If the graph contains a negative cycle reachable from
  /// [from], the returned distances are undefined.  Call
  /// [hasNegativeCycle] first if you need to guarantee correctness.
  ///
  /// **Time complexity:** O(V × E)
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

    final nodes = graph.nodeIds.toList();
    final nodeCount = nodes.length;

    final distances = <int, double>{from: zero};

    // V-1 relaxation passes with early termination.
    for (var i = 0; i < nodeCount - 1; i++) {
      var changed = false;
      for (final u in nodes) {
        final distU = distances[u];
        if (distU == null) continue;

        for (final v in graph.successors(u)) {
          final weight = graph.edgeWeight(u, v);
          final newDist = addFn(distU, weight);
          final currentDist = distances[v];

          if (currentDist == null || compareFn(newDist, currentDist) < 0) {
            distances[v] = newDist;
            changed = true;
          }
        }
      }
      if (!changed) break;
    }

    return distances;
  }

  /// Returns `true` when a negative-weight cycle reachable from [from]
  /// exists in the graph.
  ///
  /// **Time complexity:** O(V × E)
  static bool hasNegativeCycle<N, E>(
    WeightedWalkable<N, E> graph,
    int from, {
    double zero = 0.0,
    double Function(double, double)? add,
    int Function(double, double)? compare,
  }) {
    if (!graph.hasNode(from)) return false;

    final addFn = add ?? defaultAdd;
    final compareFn = compare ?? defaultCompare;

    final nodes = graph.nodeIds.toList();
    final nodeCount = nodes.length;

    final distances = <int, double>{from: zero};

    // V-1 relaxation passes.
    for (var i = 0; i < nodeCount - 1; i++) {
      for (final u in nodes) {
        final distU = distances[u];
        if (distU == null) continue;

        for (final v in graph.successors(u)) {
          final weight = graph.edgeWeight(u, v);
          final newDist = addFn(distU, weight);
          final currentDist = distances[v];

          if (currentDist == null || compareFn(newDist, currentDist) < 0) {
            distances[v] = newDist;
          }
        }
      }
    }

    // One more pass — any improvement means negative cycle.
    for (final u in nodes) {
      final distU = distances[u];
      if (distU == null) continue;

      for (final v in graph.successors(u)) {
        final weight = graph.edgeWeight(u, v);
        final newDist = addFn(distU, weight);
        final currentDist = distances[v];

        if (currentDist == null || compareFn(newDist, currentDist) < 0) {
          return true;
        }
      }
    }

    return false;
  }
}
