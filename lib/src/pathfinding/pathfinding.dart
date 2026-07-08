export 'a_star.dart';
export 'bellman_ford.dart';
export 'bidirectional.dart';
export 'dijkstra.dart';
export 'floyd_warshall.dart';
export 'johnson.dart';
export 'strategy.dart';
export 'yen.dart';

import '../model/roles.dart';
import '../path.dart';
import 'dijkstra.dart';
import 'strategy.dart';

/// Facade for point-to-point shortest-path queries.
///
/// [Pathfinding.shortestPath] accepts a configurable [PointToPointStrategy]
/// so callers can swap algorithms at runtime.  The default strategy is
/// [Dijkstra].
///
/// Algorithm-specific APIs (e.g. [Dijkstra.singleSourceDistances],
/// [AStar.implicitAStar]) are available directly on the respective class.
///
/// ```dart
/// // Default Dijkstra
/// final p1 = Pathfinding.shortestPath(graph, 0, 5);
///
/// // Explicit A* with heuristic
/// final p2 = Pathfinding.shortestPath(
///   graph, 0, 5,
///   strategy: AStar(heuristic: manhattan),
/// );
/// ```
abstract final class Pathfinding {
  /// Finds the shortest path from [from] to [to] using the given [strategy].
  ///
  /// Returns `null` when [from] or [to] does not exist, or when no path
  /// connects them.
  static Path? shortestPath<N, E>(
    WeightedWalkable<N, E> graph,
    int from,
    int to, {
    PointToPointStrategy strategy = const Dijkstra(),
    double zero = 0.0,
    double Function(double, double)? add,
    int Function(double, double)? compare,
  }) => strategy.find(graph, from, to, zero: zero, add: add, compare: compare);
}
