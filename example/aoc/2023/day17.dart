import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
2413432311323
3215453535623
3255245654254
3446585845452
4546657867536
1438598798454
4457876987766
3637877979653
4654967986887
4564679986453
1224686864057
2222222222221
2222222222223
''';

class Day17State {
  final int x;
  final int y;
  final int dir; // 0: R, 1: L, 2: U, 3: D
  final int count;

  Day17State(this.x, this.y, this.dir, this.count);
}

void main() async {
  final (input, isSample) = await loadInput(
    year: 2023,
    day: 17,
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
  final grid = <(int, int), int>{};
  var maxY = lines.length - 1;
  var maxX = lines[0].length - 1;

  for (var y = 0; y <= maxY; y++) {
    final chars = lines[y].split('');
    for (var x = 0; x <= maxX; x++) {
      grid[(x, y)] = int.parse(chars[x]);
    }
  }

  (int, int) move(int x, int y, int dir) {
    return switch (dir) {
      0 => (x + 1, y),
      1 => (x - 1, y),
      2 => (x, y - 1),
      3 => (x, y + 1),
      _ => throw ArgumentError(),
    };
  }

  List<int> nextDirs(int dir, int count, int minTurn, int maxStraight) {
    if (dir == -1) return [0, 3];
    final result = <int>[];
    if (count < maxStraight) {
      result.add(dir);
    }
    if (count >= minTurn) {
      if (dir == 0 || dir == 1) {
        result.addAll([2, 3]);
      } else {
        result.addAll([0, 1]);
      }
    }
    return result;
  }

  int solvePath(int minTurn, int maxStraight) {
    final startState = Day17State(0, 0, -1, 0);

    final result = AStar.implicitAStarBy<Day17State, String>(
      from: startState,
      successors: (state) {
        final dirs = nextDirs(state.dir, state.count, minTurn, maxStraight);
        final res = <(Day17State, double)>[];
        for (final d in dirs) {
          final (nx, ny) = move(state.x, state.y, d);
          final cost = grid[(nx, ny)];
          if (cost != null) {
            final ncount = d == state.dir ? state.count + 1 : 1;
            res.add((Day17State(nx, ny, d, ncount), cost.toDouble()));
          }
        }
        return res;
      },
      visitedBy: (state) => '${state.x},${state.y},${state.dir},${state.count}',
      isGoal: (state) =>
          state.x == maxX && state.y == maxY && state.count >= minTurn,
      heuristic: (state) =>
          ((maxX - state.x).abs() + (maxY - state.y).abs()).toDouble(),
    );

    return result != null ? result.$2.toInt() : 0;
  }

  final p1 = solvePath(0, 3);
  final p2 = solvePath(4, 10);

  return (p1, p2);
}
