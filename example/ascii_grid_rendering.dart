import 'package:yograph/yograph.dart';

void main() {
  print('=== GRID GRAPH ASCII & UNICODE RENDERING EXAMPLES ===\n');

  // ===========================================================================
  // 1. Classic vs Premium Unicode Side-by-Side (Fully Connected 3x3 Grid)
  // ===========================================================================
  print('--- 1. Fully Connected 3x3 Grid ---');
  final openGrid = GridBuilder.from2DList(
    List.generate(3, (_) => List.filled(3, '.')),
    canMove: GridBuilder.always(),
  );

  print('Classic ASCII (+, -, |) Output:');
  print(AsciiRenderer.gridToString(openGrid));
  print('');

  print('Premium Unicode (┌, ─, ┬, ┼) Output:');
  print(AsciiRenderer.gridToStringUnicode(openGrid));
  print('\n');

  // ===========================================================================
  // 2. Custom Walled Grid Structure (Passage Connectivity)
  // ===========================================================================
  print('--- 2. Custom Walled Grid Map (Blocked Connections) ---');
  // Define a simple 3x3 maze layout where some cells have walls '#'
  final mazeLayout = [
    ['.', '#', '.'],
    ['.', '#', '.'],
    ['.', '.', '.'],
  ];

  // Build grid graph where movement is only allowed between adjacent '.' cells
  final mazeGrid = GridBuilder.from2DList(
    mazeLayout,
    canMove: GridBuilder.walkable('.'),
  );

  // Map walls to solid blocks in occupants
  final mazeOccupants = <int, String>{};
  for (int r = 0; r < mazeGrid.rows; r++) {
    for (int c = 0; c < mazeGrid.cols; c++) {
      final id = mazeGrid.coordToId(r, c);
      if (mazeLayout[r][c] == '#') {
        mazeOccupants[id] = '█'; // Draw solid block for walls
      }
    }
  }

  print('Unicode Maze View (Walls dynamically shape borders!):');
  print(AsciiRenderer.gridToStringUnicode(mazeGrid, occupants: mazeOccupants));
  print('\n');

  // ===========================================================================
  // 3. Grid-Based Game Layout (Cell Occupants Placement)
  // ===========================================================================
  print('--- 3. Console Game Grid Layout (With Occupants) ---');
  final gameGrid = GridBuilder.from2DList(
    List.generate(4, (_) => List.filled(4, '.')),
    canMove: GridBuilder.always(),
  );

  // Position game entities at specific coordinates:
  // Player 'P' at {0, 0} (ID 0)
  // Gold Coins 'G' at {1, 2} (ID 6)
  // Goblin Monster 'M' at {3, 1} (ID 13)
  // Exit Portal 'E' at {3, 3} (ID 15)
  final entities = {0: 'P', 6: 'G', 13: 'M', 15: 'E'};

  print('Unicode Game Board (P = Player, G = Gold, M = Monster, E = Exit):');
  print(AsciiRenderer.gridToStringUnicode(gameGrid, occupants: entities));
}
