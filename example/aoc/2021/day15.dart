import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
1163751742
1381373672
2136511328
3694931569
7463417111
1319128137
1359912421
3125421639
1293138521
2311944581
''';

void main() async {
  final (input, isSample) = await loadInput(
    year: 2021,
    day: 15,
    sampleInput: sampleInput,
  );
  final stopwatch = Stopwatch()..start();
  final (p1, p2) = solve(input, isSample);
  stopwatch.stop();
  print('($p1, $p2)');
  print('Solved in ${stopwatch.elapsedMilliseconds}ms');
}

(int, int) solve(String rawInput, bool isSample) {
  final grid = parse(rawInput);
  return (solvePart1(grid), solvePart2(grid));
}

List<List<int>> parse(String input) {
  return getLines(
    input,
  ).map((line) => line.split('').map(int.parse).toList()).toList();
}

int solvePart1(List<List<int>> grid) {
  return _solveGrid(grid);
}

int solvePart2(List<List<int>> grid) {
  final bigGrid = _expandGrid(grid);
  return _solveGrid(bigGrid);
}

int _solveGrid(List<List<int>> gridData) {
  final rows = gridData.length;
  final cols = gridData[0].length;
  final target = _pack(rows - 1, cols - 1);

  Iterable<(int, double)> successors(int id) {
    final (r, c) = _unpack(id);
    final next = <(int, double)>[];

    if (r > 0) next.add((_pack(r - 1, c), gridData[r - 1][c].toDouble()));
    if (r < rows - 1) {
      next.add((_pack(r + 1, c), gridData[r + 1][c].toDouble()));
    }
    if (c > 0) next.add((_pack(r, c - 1), gridData[r][c - 1].toDouble()));
    if (c < cols - 1) {
      next.add((_pack(r, c + 1), gridData[r][c + 1].toDouble()));
    }

    return next;
  }

  bool isGoal(int id) => id == target;

  double heuristic(int id) {
    final (r, c) = _unpack(id);
    return ((rows - 1 - r).abs() + (cols - 1 - c).abs()).toDouble();
  }

  final result = AStar.implicitAStar<int>(
    from: _pack(0, 0),
    successors: successors,
    isGoal: isGoal,
    heuristic: heuristic,
  );

  return result?.$2.toInt() ?? -1;
}

List<List<int>> _expandGrid(List<List<int>> grid) {
  final rows = grid.length;
  final cols = grid[0].length;
  return List.generate(
    rows * 5,
    (r) => List.generate(cols * 5, (c) {
      final baseR = r % rows;
      final baseC = c % cols;
      final offset = (r ~/ rows) + (c ~/ cols);
      final val = grid[baseR][baseC] + offset;
      return val > 9 ? val - 9 : val;
    }),
  );
}

int _pack(int r, int c) => (r << 16) | c;

(int, int) _unpack(int id) => (id >> 16, id & 0xFFFF);
