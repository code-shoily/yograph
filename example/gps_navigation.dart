/// GPS navigation with A* search.
///
/// Finds the shortest route on a road network using A* with a
/// straight-line-distance heuristic. Run with:
///   dart run example/gps_navigation.dart
library;

import 'package:yograph/yograph.dart';

/// Simple (x, y) coordinate for each intersection.
class Point {
  final double x;
  final double y;
  const Point(this.x, this.y);

  double distanceTo(Point other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return dx * dx + dy * dy;
  }
}

void main() {
  // Intersection IDs and their GPS coordinates
  final coords = <int, Point>{
    0: const Point(0, 0),   // Home
    1: const Point(2, 1),   // Oak St
    2: const Point(1, 3),   // Pine St
    3: const Point(4, 2),   // Elm St
    4: const Point(3, 5),   // Downtown
  };

  // Build a directed road network with travel times in minutes
  final graph = SimpleGraph<String, int>.directed()
    ..addEdge(0, 1, data: 5)
    ..addEdge(0, 2, data: 8)
    ..addEdge(1, 2, data: 2)
    ..addEdge(1, 3, data: 6)
    ..addEdge(2, 3, data: 3)
    ..addEdge(2, 4, data: 4)
    ..addEdge(3, 4, data: 2);

  const home = 0;
  const downtown = 4;

  // A* with straight-line-distance heuristic (squared, no sqrt needed)
  final path = Pathfinding.shortestPath(
    graph,
    home,
    downtown,
    strategy: AStar(
      heuristic: (node, goal) =>
          coords[node]!.distanceTo(coords[goal]!),
    ),
  );

  print('Fastest route from Home to Downtown:');
  print(path); // e.g. Path(0 -> 2 -> 4, weight: 12.0)

  // Compare with Dijkstra (no heuristic)
  final dijkstraPath = Pathfinding.shortestPath(graph, home, downtown);
  print('Dijkstra agrees: ${dijkstraPath?.nodes}');
}
