import '../model/roles.dart';
import '../model/weight_algebra.dart';
import '../path.dart';

/// Strategy interface for point-to-point shortest-path algorithms.
///
/// Implementations encapsulate both the algorithm and any configuration
/// it needs (e.g. an A* heuristic).  The [Pathfinding.shortestPath] facade
/// accepts a [PointToPointStrategy] so callers can swap algorithms at
/// runtime.
///
/// The [WeightAlgebra] parameter allows algorithms to work with any edge
/// data type — not just `double` — mirroring the Elixir ring protocol pattern.
///
/// ```dart
/// final path = Pathfinding.shortestPath(
///   graph, 0, 5,
///   strategy: AStar(heuristic: manhattan),
///   algebra: RoadByKm.instance,
/// );
/// ```
abstract interface class PointToPointStrategy {
  /// Finds a path from [from] to [to] on [graph].
  ///
  /// Returns `null` when no path exists.
  Path<E>? find<N, E>(
    WeightedWalkable<N, E> graph,
    int from,
    int to, {
    WeightAlgebra<E> algebra,
  });
}
