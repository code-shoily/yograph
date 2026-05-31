import '../model/roles.dart';
import 'strategy.dart';

/// Result of a Floyd-Warshall all-pairs shortest-path query.
///
/// * **Success** — [distances] contains the full matrix and
///   [hasNegativeCycle] is `false`.
/// * **Negative cycle** — [distances] is `null` and [hasNegativeCycle] is
///   `true`.
///
/// Use [distance] for convenient lookups.
class FloydWarshallResult {
  /// Distance matrix mapping `(from, to)` to shortest distance.
  /// `null` when a negative cycle was detected.
  final Map<(int, int), double>? distances;

  /// `true` when a negative-weight cycle exists in the graph.
  final bool hasNegativeCycle;

  const FloydWarshallResult._({this.distances, required this.hasNegativeCycle});

  /// Successful query with a valid distance matrix.
  factory FloydWarshallResult.success(Map<(int, int), double> distances) =>
      FloydWarshallResult._(distances: distances, hasNegativeCycle: false);

  /// A negative cycle was detected; the distance matrix is undefined.
  factory FloydWarshallResult.negativeCycle() =>
      const FloydWarshallResult._(hasNegativeCycle: true);

  /// Returns the shortest distance from [from] to [to], or `null` when
  /// no path exists or a negative cycle was detected.
  double? distance(int from, int to) => distances?[(from, to)];

  @override
  String toString() {
    if (hasNegativeCycle) return 'FloydWarshallResult(negativeCycle)';
    return 'FloydWarshallResult(${distances?.length} entries)';
  }
}

/// Floyd-Warshall algorithm for all-pairs shortest paths.
///
/// Computes shortest paths between every pair of nodes in a single
/// O(V³) execution.  Best suited for dense graphs or when many
/// all-pairs queries are needed.
///
/// ```dart
/// final result = FloydWarshall.allPairs(graph);
/// if (!result.hasNegativeCycle) {
///   print(result.distance(0, 5)); // shortest 0→5 distance
/// }
/// ```
class FloydWarshall {
  FloydWarshall._();

  /// Computes shortest paths between all pairs of nodes.
  ///
  /// Returns a [FloydWarshallResult] containing the full distance matrix,
  /// or indicating a negative cycle.
  ///
  /// **Time complexity:** O(V³)
  ///
  /// **Space complexity:** O(V²)
  static FloydWarshallResult allPairs<N, E>(
    WeightedWalkable<N, E> graph, {
    double zero = 0.0,
    double Function(double, double)? add,
    int Function(double, double)? compare,
  }) {
    final addFn = add ?? defaultAdd;
    final compareFn = compare ?? defaultCompare;

    final nodes = graph.nodeIds.toList();
    final dist = <(int, int), double>{};

    // Initialize: dist[i][i] = zero
    for (final i in nodes) {
      dist[(i, i)] = zero;
    }

    // Initialize: dist[i][j] = weight(i, j)
    for (final i in nodes) {
      for (final j in graph.successors(i)) {
        final w = graph.edgeWeight(i, j);
        final key = (i, j);
        final existing = dist[key];
        if (existing == null || compareFn(w, existing) < 0) {
          dist[key] = w;
        }
      }
    }

    // Main triple loop: for each k, i, j relax via k
    for (final k in nodes) {
      for (final i in nodes) {
        final distIK = dist[(i, k)];
        if (distIK == null) continue;

        for (final j in nodes) {
          final distKJ = dist[(k, j)];
          if (distKJ == null) continue;

          final newDist = addFn(distIK, distKJ);
          final key = (i, j);
          final current = dist[key];

          if (current == null || compareFn(newDist, current) < 0) {
            dist[key] = newDist;
          }
        }
      }
    }

    // Negative cycle detection: any dist[i][i] < zero
    for (final i in nodes) {
      final d = dist[(i, i)];
      if (d != null && compareFn(d, zero) < 0) {
        return FloydWarshallResult.negativeCycle();
      }
    }

    return FloydWarshallResult.success(dist);
  }

  /// Returns `true` when the graph contains a negative-weight cycle.
  ///
  /// This is more efficient than running the full algorithm — it returns
  /// as soon as a negative cycle is detected during the k iterations.
  ///
  /// **Time complexity:** O(V³) worst case, but typically faster due to
  /// early exit.
  static bool hasNegativeCycle<N, E>(
    WeightedWalkable<N, E> graph, {
    double zero = 0.0,
    double Function(double, double)? add,
    int Function(double, double)? compare,
  }) {
    final addFn = add ?? defaultAdd;
    final compareFn = compare ?? defaultCompare;

    final nodes = graph.nodeIds.toList();
    final dist = <(int, int), double>{};

    for (final i in nodes) {
      dist[(i, i)] = zero;
    }

    for (final i in nodes) {
      for (final j in graph.successors(i)) {
        final w = graph.edgeWeight(i, j);
        final key = (i, j);
        final existing = dist[key];
        if (existing == null || compareFn(w, existing) < 0) {
          dist[key] = w;
        }
      }
    }

    for (final k in nodes) {
      for (final i in nodes) {
        final distIK = dist[(i, k)];
        if (distIK == null) continue;

        for (final j in nodes) {
          final distKJ = dist[(k, j)];
          if (distKJ == null) continue;

          final newDist = addFn(distIK, distKJ);
          final key = (i, j);
          final current = dist[key];

          if (current == null || compareFn(newDist, current) < 0) {
            dist[key] = newDist;
          }
        }
      }

      // Early-exit check after each k iteration.
      for (final i in nodes) {
        final d = dist[(i, i)];
        if (d != null && compareFn(d, zero) < 0) {
          return true;
        }
      }
    }

    return false;
  }
}
