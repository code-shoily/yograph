import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
#.######
#>>.<^<#
#.<..<<#
#>v.><>#
#<^v^^>#
######.#
''';

class Day24State {
  final int x;
  final int y;
  final int t;

  Day24State(this.x, this.y, this.t);
}

void main() async {
  final (input, isSample) = await loadInput(
    year: 2022,
    day: 24,
    sampleInput: sampleInput,
  );
  final stopwatch = Stopwatch()..start();
  final (p1, p2) = solve(input, isSample);
  stopwatch.stop();
  print('($p1, $p2)');
  print('Solved in ${stopwatch.elapsedMilliseconds}ms');
}

int gcd(int a, int b) => b == 0 ? a : gcd(b, a % b);
int lcm(int a, int b) => (a * b) ~/ gcd(a, b);
int remEuclid(int val, int mod) => (val % mod + mod) % mod;

(int, int) solve(String rawInput, bool isSample) {
  final lines = getLines(rawInput);
  final h = lines.length;
  final w = lines[0].length;

  final innerW = w - 2;
  final innerH = h - 2;
  final cycle = lcm(innerW, innerH);

  final upSet = <int>{};
  final downSet = <int>{};
  final leftSet = <int>{};
  final rightSet = <int>{};

  for (var y = 0; y < h; y++) {
    final chars = lines[y].split('');
    for (var x = 0; x < w; x++) {
      final ch = chars[x];
      if (ch == '^') upSet.add(y * w + x);
      if (ch == 'v') downSet.add(y * w + x);
      if (ch == '<') leftSet.add(y * w + x);
      if (ch == '>') rightSet.add(y * w + x);
    }
  }

  bool hasBlizzard(int x, int y, int t) {
    final uy = remEuclid(y - 1 + t, innerH) + 1;
    final dy = remEuclid(y - 1 - t, innerH) + 1;
    final lx = remEuclid(x - 1 + t, innerW) + 1;
    final rx = remEuclid(x - 1 - t, innerW) + 1;

    return upSet.contains(uy * w + x) ||
        downSet.contains(dy * w + x) ||
        leftSet.contains(y * w + lx) ||
        rightSet.contains(y * w + rx);
  }

  bool isValid(int x, int y, int t, int sx, int sy, int gx, int gy) {
    if (x == sx && y == sy) return true;
    if (x == gx && y == gy) return true;
    if (x <= 0 || x > innerW || y <= 0 || y > innerH) return false;
    return !hasBlizzard(x, y, t);
  }

  int solvePath(int sx, int sy, int gx, int gy, int startT) {
    final result = AStar.implicitAStarBy<Day24State, String>(
      from: Day24State(sx, sy, startT),
      successors: (state) {
        final nt = state.t + 1;
        final candidates = [
          (state.x, state.y),
          (state.x, state.y - 1),
          (state.x, state.y + 1),
          (state.x - 1, state.y),
          (state.x + 1, state.y),
        ];

        final res = <(Day24State, double)>[];
        for (final (nx, ny) in candidates) {
          if (isValid(nx, ny, nt, sx, sy, gx, gy)) {
            res.add((Day24State(nx, ny, nt), 1.0));
          }
        }
        return res;
      },
      visitedBy: (state) => '${state.x},${state.y},${state.t % cycle}',
      isGoal: (state) => state.x == gx && state.y == gy,
      heuristic: (state) =>
          ((gx - state.x).abs() + (gy - state.y).abs()).toDouble(),
    );

    return result != null ? startT + result.$2.toInt() : startT;
  }

  final startPos = (1, 0);
  final goalPos = (innerW, h - 1);

  final t1 = solvePath(startPos.$1, startPos.$2, goalPos.$1, goalPos.$2, 0);
  final t2 = solvePath(goalPos.$1, goalPos.$2, startPos.$1, startPos.$2, t1);
  final t3 = solvePath(startPos.$1, startPos.$2, goalPos.$1, goalPos.$2, t2);

  return (t1, t3);
}
