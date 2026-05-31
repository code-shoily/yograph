import '../aoc_helper.dart';

const sampleInput = '''
MMMSXXMASM
MSAMXMSMSA
AMXSXMAAMM
MSAMASMSMX
XMASAMXAMM
XXAMMXXAMA
SMSMSASXSS
SAXAMASAAA
MAMMMXMMMM
MXMXAXMASX
''';

void main() async {
  final (input, isSample) = await loadInput(
    year: 2024,
    day: 4,
    sampleInput: sampleInput,
  );
  final stopwatch = Stopwatch()..start();
  final (p1, p2) = solve(input, isSample);
  stopwatch.stop();
  print('($p1, $p2)');
  print('Solved in ${stopwatch.elapsedMilliseconds}ms');
}

(int, int) solve(String rawInput, bool isSample) {
  final grid = getLines(rawInput);
  return (solvePart1(grid), solvePart2(grid));
}

int solvePart1(List<String> grid) {
  final rows = grid.length;
  final cols = grid[0].length;
  var count = 0;

  final directions = const [
    (-1, -1),
    (0, -1),
    (1, -1),
    (-1, 0),
    (1, 0),
    (-1, 1),
    (0, 1),
    (1, 1),
  ];

  for (var y = 0; y < rows; y++) {
    for (var x = 0; x < cols; x++) {
      if (grid[y][x] == 'X') {
        for (final (dx, dy) in directions) {
          if (_charAt(grid, x + dx, y + dy) == 'M' &&
              _charAt(grid, x + 2 * dx, y + 2 * dy) == 'A' &&
              _charAt(grid, x + 3 * dx, y + 3 * dy) == 'S') {
            count++;
          }
        }
      }
    }
  }

  return count;
}

int solvePart2(List<String> grid) {
  final rows = grid.length;
  final cols = grid[0].length;
  var count = 0;

  for (var y = 0; y < rows; y++) {
    for (var x = 0; x < cols; x++) {
      if (grid[y][x] == 'A') {
        final tl = _charAt(grid, x - 1, y - 1);
        final br = _charAt(grid, x + 1, y + 1);
        final tr = _charAt(grid, x + 1, y - 1);
        final bl = _charAt(grid, x - 1, y + 1);

        if (_isValidDiag(tl, br) && _isValidDiag(tr, bl)) {
          count++;
        }
      }
    }
  }

  return count;
}

String? _charAt(List<String> grid, int x, int y) {
  if (y < 0 || y >= grid.length) return null;
  final row = grid[y];
  if (x < 0 || x >= row.length) return null;
  return row[x];
}

bool _isValidDiag(String? a, String? b) {
  if (a == 'M' && b == 'S') return true;
  if (a == 'S' && b == 'M') return true;
  return false;
}
