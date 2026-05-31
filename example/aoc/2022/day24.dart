import 'dart:collection';
import '../aoc_helper.dart';

const sampleInput = r'''
#.######
#>>.<^<#
#.<..<<#
#>v.><>#
#<^v^^>#
######.#
''';

class SearchState {
  final int x;
  final int y;
  final int t;

  SearchState(this.x, this.y, this.t);
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

(int, int) solve(String rawInput, bool isSample) {
  final lines = getLines(rawInput);
  final h = lines.length;
  final w = lines[0].length;

  final up = <int>{};
  final down = <int>{};
  final left = <int>{};
  final right = <int>{};

  for (var y = 0; y < h; y++) {
    final line = lines[y];
    for (var x = 0; x < w; x++) {
      final char = line[x];
      final pos = y * w + x;
      if (char == '^') up.add(pos);
      if (char == 'v') down.add(pos);
      if (char == '<') left.add(pos);
      if (char == '>') right.add(pos);
    }
  }

  final innerW = w - 2;
  final innerH = h - 2;
  final cycle = _lcm(innerW, innerH);

  final startPos = (1, 0);
  final goalPos = (innerW, h - 1);

  final t1 = _solvePath(
    startPos,
    goalPos,
    0,
    up,
    down,
    left,
    right,
    w,
    h,
    cycle,
  );
  final t2 = _solvePath(
    goalPos,
    startPos,
    t1,
    up,
    down,
    left,
    right,
    w,
    h,
    cycle,
  );
  final t3 = _solvePath(
    startPos,
    goalPos,
    t2,
    up,
    down,
    left,
    right,
    w,
    h,
    cycle,
  );

  return (t1, t3);
}

int _solvePath(
  (int, int) start,
  (int, int) goal,
  int startT,
  Set<int> up,
  Set<int> down,
  Set<int> left,
  Set<int> right,
  int w,
  int h,
  int cycle,
) {
  final innerW = w - 2;
  final innerH = h - 2;

  bool isValid(int x, int y, int t) {
    if (x == start.$1 && y == start.$2) return true;
    if (x == goal.$1 && y == goal.$2) return true;
    if (x <= 0 || x > innerW || y <= 0 || y > innerH) return false;

    final uy = _remEuclid(y - 1 + t, innerH) + 1;
    final dy = _remEuclid(y - 1 - t, innerH) + 1;
    final lx = _remEuclid(x - 1 + t, innerW) + 1;
    final rx = _remEuclid(x - 1 - t, innerW) + 1;

    return !up.contains(uy * w + x) &&
        !down.contains(dy * w + x) &&
        !left.contains(y * w + lx) &&
        !right.contains(y * w + rx);
  }

  final q = Queue<SearchState>();
  q.add(SearchState(start.$1, start.$2, startT));

  final visited = <int>{};
  visited.add((start.$1 << 24) | (start.$2 << 16) | (startT % cycle));

  while (q.isNotEmpty) {
    final curr = q.removeFirst();
    if (curr.x == goal.$1 && curr.y == goal.$2) {
      return curr.t;
    }

    final nt = curr.t + 1;
    final moves = [
      (curr.x, curr.y),
      (curr.x, curr.y - 1),
      (curr.x, curr.y + 1),
      (curr.x - 1, curr.y),
      (curr.x + 1, curr.y),
    ];

    for (final (nx, ny) in moves) {
      if (isValid(nx, ny, nt)) {
        final stateId = (nx << 24) | (ny << 16) | (nt % cycle);
        if (!visited.contains(stateId)) {
          visited.add(stateId);
          q.add(SearchState(nx, ny, nt));
        }
      }
    }
  }

  throw StateError('No path found');
}

int _gcd(int a, int b) {
  var x = a;
  var y = b;
  while (y != 0) {
    final t = y;
    y = x % y;
    x = t;
  }
  return x;
}

int _lcm(int a, int b) => (a * b).abs() ~/ _gcd(a, b);

int _remEuclid(int a, int b) {
  final r = a % b;
  return r < 0 ? r + b : r;
}
