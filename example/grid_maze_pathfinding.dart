import 'package:yograph/yograph.dart';

void main() {
  print('=== GRID MAZE PATHFINDING WITH A* & MANHATTAN HEURISTIC ===\n');

  // Define a 2D ASCII maze layout:
  // 'S': Start
  // 'E': End
  // '.': Walkable pathway
  // '#': Unwalkable wall
  final mazeLayout = [
    ['S', '.', '.', '#', '.', '.', '.'],
    ['#', '#', '.', '#', '.', '#', '.'],
    ['.', '.', '.', '.', '.', '#', '.'],
    ['.', '#', '#', '#', '#', '#', '.'],
    ['.', '.', '.', '.', '.', '.', 'E'],
  ];

  print('Original Maze Map:');
  _printMaze(mazeLayout);
  print('');

  // 1. Build a GridGraph representing this maze
  // Movement is Cardinal only (Rook topology: Up, Down, Left, Right).
  // A cell can only connect if it is walkable (either '.', 'S', or 'E').
  final gridGraph = GridBuilder.from2DList(
    mazeLayout,
    canMove: GridBuilder.including(['.', 'S', 'E']),
  );

  // 2. Locate Start ('S') and End ('E') node IDs in the GridGraph
  final startId = gridGraph.findNode((cell) => cell == 'S');
  final endId = gridGraph.findNode((cell) => cell == 'E');

  if (startId == null || endId == null) {
    print('Error: Start or End cell not found in the grid map.');
    return;
  }

  final cols = gridGraph.cols;
  final startCoord = gridGraph.idToCoord(startId);
  final endCoord = gridGraph.idToCoord(endId);

  print('Start Point: ID $startId at coordinate $startCoord');
  print('End Point:   ID $endId at coordinate $endCoord\n');

  // 3. Compute the shortest path using A* Pathfinding
  // We use Manhattan distance as our perfect heuristic for cardinal movements!
  final pathResult = Pathfinding.shortestPath(
    gridGraph.toGraph(),
    startId,
    endId,
    strategy: AStar(
      heuristic: (node, goal) =>
          GridBuilder.manhattanDistance(node, goal, cols).toDouble(),
    ),
  );

  if (pathResult == null) {
    print('❌ No path could be found from Start to End!');
    return;
  }

  print('🎯 Path found successfully!');
  print('Path Length (Edge Cost): ${pathResult.weight}');
  print('Path Node Sequence: ${pathResult.nodes}\n');

  // 4. Render the solution path overlaying it back on the 2D layout
  final solvedMaze = List.generate(
    mazeLayout.length,
    (r) => List.of(mazeLayout[r]),
  );

  // Mark A* path nodes with '*' (except start and end)
  for (final nodeId in pathResult.nodes) {
    if (nodeId != startId && nodeId != endId) {
      final (r, c) = gridGraph.idToCoord(nodeId);
      solvedMaze[r][c] = '*';
    }
  }

  print('Solved Maze (Path marked with *):');
  _printMaze(solvedMaze);
}

void _printMaze(List<List<String>> map) {
  for (final row in map) {
    print('  ${row.join(' ')}');
  }
}
