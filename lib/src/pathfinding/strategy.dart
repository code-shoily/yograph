import '../model/roles.dart';
import '../path.dart';

/// Strategy interface for point-to-point shortest-path algorithms.
///
/// Implementations encapsulate both the algorithm and any configuration
/// it needs (e.g. an A* heuristic).  The [Pathfinding.shortestPath] facade
/// accepts a [PointToPointStrategy] so callers can swap algorithms at
/// runtime.
///
/// ```dart
/// final path = Pathfinding.shortestPath(
///   graph, 0, 5,
///   strategy: AStar(heuristic: manhattan),
/// );
/// ```
abstract interface class PointToPointStrategy {
  /// Finds a path from [from] to [to] on [graph].
  ///
  /// Returns `null` when no path exists.
  Path? find<N, E>(
    WeightedWalkable<N, E> graph,
    int from,
    int to, {
    double zero,
    double Function(double, double)? add,
    int Function(double, double)? compare,
  });
}

/// Default weight combination: addition.
double defaultAdd(double a, double b) => a + b;

/// Default weight comparison: ascending order.
int defaultCompare(double a, double b) => a.compareTo(b);
