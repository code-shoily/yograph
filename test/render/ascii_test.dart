import 'package:test/test.dart';
import 'package:yograph/yograph.dart';

void main() {
  group('AsciiRenderer Tests', () {
    test('renders empty grids as empty string', () {
      final grid = GridBuilder.from2DList(<List<int>>[]);
      expect(AsciiRenderer.gridToString(grid), isEmpty);
      expect(AsciiRenderer.gridToStringUnicode(grid), isEmpty);
    });

    test('renders basic 2x2 undirected grid with + - | correctly', () {
      final grid = GridBuilder.from2DList(
        [
          ['.', '.'],
          ['.', '.'],
        ],
        directed: false,
        canMove: GridBuilder.always(),
      );

      final ascii = AsciiRenderer.gridToString(grid);

      // With open connections, the inner walls are removed
      expect(ascii, contains('+---+---+'));
      expect(ascii, contains('|       |'));
      expect(ascii, contains('+   +   +'));

      // Check with custom occupants
      final asciiWithOccupants = AsciiRenderer.gridToString(
        grid,
        occupants: {0: 'A', 3: 'B'},
      );
      expect(asciiWithOccupants, contains('| A     |'));
      expect(asciiWithOccupants, contains('|     B |'));
    });

    test('renders premium 2x2 Unicode box-drawing correctly', () {
      final grid = GridBuilder.from2DList(
        [
          ['.', '.'],
          ['.', '.'],
        ],
        directed: false,
        canMove: GridBuilder.always(),
      );

      final unicode = AsciiRenderer.gridToStringUnicode(grid);

      // With open connections, the inner borders are removed
      expect(unicode, contains('┌───────┐'));
      expect(unicode, contains('│       │'));
      expect(unicode, contains('└───────┘'));

      // Check occupants
      final unicodeWithOccupants = AsciiRenderer.gridToStringUnicode(
        grid,
        occupants: {0: 'S', 3: 'E'},
      );
      expect(unicodeWithOccupants, contains('│ S     │'));
      expect(unicodeWithOccupants, contains('│     E │'));
    });

    test(
      'renders vertical and horizontal walls when connectivity is blocked',
      () {
        // 2x2 grid where all steps are blocked
        final maze = [
          ['.', '.'],
          ['.', '.'],
        ];

        final grid = GridBuilder.from2DList(maze, canMove: (from, to) => false);

        final unicode = AsciiRenderer.gridToStringUnicode(grid);

        // Fully walled off (all intersections and borders present)
        expect(unicode, contains('┌───┬───┐'));
        expect(unicode, contains('│   │   │'));
        expect(unicode, contains('├───┼───┤'));
        expect(unicode, contains('└───┴───┘'));
      },
    );
  });
}
