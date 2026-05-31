import '../aoc_helper.dart';

const sampleInput = '''
30373
25512
65332
33549
35390
''';

void main() async {
  final (input, isSample) = await loadInput(
    year: 2022,
    day: 8,
    sampleInput: sampleInput,
  );
  final stopwatch = Stopwatch()..start();
  final (p1, p2) = solve(input, isSample);
  stopwatch.stop();
  print('($p1, $p2)');
  print('Solved in ${stopwatch.elapsedMilliseconds}ms');
}

(int, int) solve(String rawInput, bool isSample) {
  final lines = getLines(rawInput);
  final grid = lines
      .map((line) => line.split('').map(int.parse).toList())
      .toList();

  return (solvePart1(grid), solvePart2(grid));
}

int solvePart1(List<List<int>> grid) {
  final rows = grid.length;
  final cols = grid[0].length;
  var count = 0;

  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      if (r == 0 || r == rows - 1 || c == 0 || c == cols - 1) {
        count++;
        continue;
      }

      final h = grid[r][c];
      var visible = false;

      for (final (dr, dc) in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
        var currR = r + dr;
        var currC = c + dc;
        var dirVisible = true;

        while (currR >= 0 && currR < rows && currC >= 0 && currC < cols) {
          if (grid[currR][currC] >= h) {
            dirVisible = false;
            break;
          }
          currR += dr;
          currC += dc;
        }

        if (dirVisible) {
          visible = true;
          break;
        }
      }

      if (visible) {
        count++;
      }
    }
  }

  return count;
}

int solvePart2(List<List<int>> grid) {
  final rows = grid.length;
  final cols = grid[0].length;
  var maxScore = 0;

  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      final h = grid[r][c];
      var score = 1;

      for (final (dr, dc) in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
        var currR = r + dr;
        var currC = c + dc;
        var dist = 0;

        while (currR >= 0 && currR < rows && currC >= 0 && currC < cols) {
          dist++;
          if (grid[currR][currC] >= h) {
            break;
          }
          currR += dr;
          currC += dc;
        }

        score *= dist;
      }

      if (score > maxScore) {
        maxScore = score;
      }
    }
  }

  return maxScore;
}
