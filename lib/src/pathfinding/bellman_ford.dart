import '../model/roles.dart';
import '../model/weight_algebra.dart';
import '../path.dart';
import '_utils.dart';
import 'a_star.dart';
import 'strategy.dart';

/// Result of a Bellman-Ford shortest-path query.
///
/// Three outcomes are possible:
/// * **Success** — [path] contains the shortest path.
/// * **No path** — [path] is `null` and [hasNegativeCycle] is `false`.
/// * **Negative cycle** — [path] is `null` and [hasNegativeCycle] is `true`.
class BellmanFordResult<E> {
  final Path<E>? path;
  final bool hasNegativeCycle;

  const BellmanFordResult._({this.path, required this.hasNegativeCycle});

  factory BellmanFordResult.success(Path<E> path) =>
      BellmanFordResult._(path: path, hasNegativeCycle: false);

  factory BellmanFordResult.noPath() =>
      BellmanFordResult._(path: null, hasNegativeCycle: false);

  factory BellmanFordResult.negativeCycle() =>
      BellmanFordResult._(path: null, hasNegativeCycle: true);

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
/// Unlike Dijkstra, supports negative edge weights and detects negative cycles.
/// Works with any edge type [E] through [WeightAlgebra<E>].
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

  /// Strategy-compatible entry point. Throws [StateError] on negative cycle.
  @override
  Path<E>? find<N, E>(
    WeightedWalkable<N, E> graph,
    int from,
    int to, {
    WeightAlgebra<E>? algebra,
  }) {
    final result = shortestPath(graph, from, to, algebra: algebra);
    if (result.hasNegativeCycle) {
      throw StateError(
        'Negative cycle detected. Use BellmanFord.shortestPath() to handle explicitly.',
      );
    }
    return result.path;
  }

  /// Finds the shortest path from [from] to [to].
  ///
  /// **Time complexity:** O(V × E)
  static BellmanFordResult<E> shortestPath<N, E>(
    WeightedWalkable<N, E> graph,
    int from,
    int to, {
    WeightAlgebra<E>? algebra,
  }) {
    if (!graph.hasNode(from) || !graph.hasNode(to)) {
      return BellmanFordResult.noPath();
    }
    final alg = resolveAlgebra<E>(algebra);
    if (from == to) {
      return BellmanFordResult.success(Path([from], alg.zero));
    }

    final nodes = graph.nodeIds.toList();
    final distances = <int, double>{from: alg.toDouble(alg.zero)};
    final distTyped = <int, E>{from: alg.zero};
    final predecessors = <int, int>{};

    for (var i = 0; i < nodes.length - 1; i++) {
      var changed = false;
      for (final u in nodes) {
        final distU = distances[u];
        final typedU = distTyped[u];
        if (distU == null || typedU == null) continue;
        for (final v in graph.successors(u)) {
          final raw = edgeValue(graph, u, v, alg);
          final newTyped = alg.add(typedU, raw);
          final newDist = alg.toDouble(newTyped);
          final cur = distances[v];
          if (cur == null || newDist < cur) {
            distances[v] = newDist;
            distTyped[v] = newTyped;
            predecessors[v] = u;
            changed = true;
          }
        }
      }
      if (!changed) break;
    }

    // Negative cycle detection pass.
    for (final u in nodes) {
      final distU = distances[u];
      final typedU = distTyped[u];
      if (distU == null || typedU == null) continue;
      for (final v in graph.successors(u)) {
        final raw = edgeValue(graph, u, v, alg);
        final newTyped = alg.add(typedU, raw);
        final curTyped = distTyped[v];
        if (curTyped == null || alg.compare(newTyped, curTyped) < 0) {
          return BellmanFordResult.negativeCycle();
        }
      }
    }

    final targetTyped = distTyped[to];
    if (targetTyped == null) return BellmanFordResult.noPath();
    return BellmanFordResult.success(
      Path(reconstructPath(predecessors, to), targetTyped),
    );
  }

  /// Single-source distances from [from] to all reachable nodes.
  ///
  /// **Time complexity:** O(V × E)
  static Map<int, E> singleSourceDistances<N, E>(
    WeightedWalkable<N, E> graph,
    int from, {
    WeightAlgebra<E>? algebra,
  }) {
    if (!graph.hasNode(from)) return {};
    final alg = resolveAlgebra<E>(algebra);

    final nodes = graph.nodeIds.toList();
    final distances = <int, double>{from: alg.toDouble(alg.zero)};
    final distTyped = <int, E>{from: alg.zero};

    for (var i = 0; i < nodes.length - 1; i++) {
      var changed = false;
      for (final u in nodes) {
        final distU = distances[u];
        final typedU = distTyped[u];
        if (distU == null || typedU == null) continue;
        for (final v in graph.successors(u)) {
          final raw = edgeValue(graph, u, v, alg);
          final newTyped = alg.add(typedU, raw);
          final newDist = alg.toDouble(newTyped);
          final cur = distances[v];
          if (cur == null || newDist < cur) {
            distances[v] = newDist;
            distTyped[v] = newTyped;
            changed = true;
          }
        }
      }
      if (!changed) break;
    }
    return distTyped;
  }

  /// Returns `true` when a negative-weight cycle reachable from [from] exists.
  ///
  /// **Time complexity:** O(V × E)
  static bool hasNegativeCycle<N, E>(
    WeightedWalkable<N, E> graph,
    int from, {
    WeightAlgebra<E>? algebra,
  }) {
    if (!graph.hasNode(from)) return false;
    final alg = resolveAlgebra<E>(algebra);
    final nodes = graph.nodeIds.toList();
    final distances = <int, double>{from: alg.toDouble(alg.zero)};
    final distTyped = <int, E>{from: alg.zero};

    for (var i = 0; i < nodes.length - 1; i++) {
      for (final u in nodes) {
        final distU = distances[u];
        final typedU = distTyped[u];
        if (distU == null || typedU == null) continue;
        for (final v in graph.successors(u)) {
          final raw = edgeValue(graph, u, v, alg);
          final newTyped = alg.add(typedU, raw);
          final newDist = alg.toDouble(newTyped);
          final cur = distances[v];
          if (cur == null || newDist < cur) {
            distances[v] = newDist;
            distTyped[v] = newTyped;
          }
        }
      }
    }
    for (final u in nodes) {
      final distU = distances[u];
      final typedU = distTyped[u];
      if (distU == null || typedU == null) continue;
      for (final v in graph.successors(u)) {
        final raw = edgeValue(graph, u, v, alg);
        final newTyped = alg.add(typedU, raw);
        final curTyped = distTyped[v];
        if (curTyped == null || alg.compare(newTyped, curTyped) < 0) {
          return true;
        }
      }
    }
    return false;
  }
}
