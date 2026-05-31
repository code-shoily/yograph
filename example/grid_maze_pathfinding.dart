import 'package:yograph/yograph.dart';

void main() {
  print('=== GRID MAZE PATHFINDING WITH A* & PREMIUM UNICODE RENDERING ===\n');

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

  // 1. Build a GridGraph representing this maze
  // Movement is Cardinal only (Rook topology).
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

  // Map initial occupants to render the original maze
  final initialOccupants = <int, String>{};
  for (int r = 0; r < gridGraph.rows; r++) {
    for (int c = 0; c < gridGraph.cols; c++) {
      final id = gridGraph.coordToId(r, c);
      final value = gridGraph.getCell(r, c);
      if (value == '#') {
        initialOccupants[id] = '█'; // Solid block for walls
      } else if (value == 'S' || value == 'E') {
        initialOccupants[id] = value!;
      }
    }
  }

  print('Original Maze Map (Unicode Box-Drawing):');
  print(
    AsciiRenderer.gridToStringUnicode(gridGraph, occupants: initialOccupants),
  );
  print('');

  print('Start Point: ID $startId at coordinate $startCoord');
  print('End Point:   ID $endId at coordinate $endCoord\n');

  // 3. Compute the shortest path using A* Pathfinding
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

  // 4. Render the solution path overlaying it back on the grid
  final solvedOccupants = Map<int, String>.of(initialOccupants);
  for (final nodeId in pathResult.nodes) {
    if (nodeId != startId && nodeId != endId) {
      solvedOccupants[nodeId] = '●'; // Dot representing the path steps
    }
  }

  print('Solved Maze (Path steps marked with ●):');
  print(
    AsciiRenderer.gridToStringUnicode(gridGraph, occupants: solvedOccupants),
  );
}
