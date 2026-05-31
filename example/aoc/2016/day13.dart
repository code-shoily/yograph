import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '10';

void main() async {
  final (input, isSample) = await loadInput(
    year: 2016,
    day: 13,
    sampleInput: sampleInput,
  );
  final (p1, p2) = solve(input, isSample);
  print('($p1, $p2)');
}

(int, int) solve(String rawInput, bool isSample) {
  final fav = int.parse(rawInput.trim());
  return (solvePart1(fav, isSample), solvePart2(fav, isSample));
}

int solvePart1(int fav, bool isSample) {
  final target = isSample ? (7, 4) : (31, 39);

  Iterable<((int, int), double)> successors((int, int) pos) {
    return _openNeighbors(pos, fav).map((n) => (n, 1.0));
  }

  bool isGoal((int, int) pos) => pos == target;

  double heuristic((int, int) pos) {
    return ((pos.$1 - target.$1).abs() + (pos.$2 - target.$2).abs()).toDouble();
  }

  final result = AStar.implicitAStar<(int, int)>(
    from: (1, 1),
    successors: successors,
    isGoal: isGoal,
    heuristic: heuristic,
  );

  return result?.$2.toInt() ?? -1;
}

int solvePart2(int fav, bool isSample) {
  if (isSample) {
    return 0; // Part 2 doesn't have a sample spec in AoC 2016 Day 13
  }

  final visited = <(int, int)>{};
  final queue = <((int, int), int)>[];

  queue.add(((1, 1), 0));
  visited.add((1, 1));

  while (queue.isNotEmpty) {
    final (pos, dist) = queue.removeAt(0);

    if (dist >= 50) continue;

    for (final next in _openNeighbors(pos, fav)) {
      if (!visited.contains(next)) {
        visited.add(next);
        queue.add((next, dist + 1));
      }
    }
  }

  return visited.length;
}

Iterable<(int, int)> _openNeighbors((int, int) pos, int fav) {
  final (x, y) = pos;
  final candidates = [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)];
  return candidates.where((n) => !_isWall(n.$1, n.$2, fav));
}

bool _isWall(int x, int y, int fav) {
  if (x < 0 || y < 0) return true;
  final val = x * x + 3 * x + 2 * x * y + y + y * y + fav;
  return _countOnes(val) % 2 != 0;
}

int _countOnes(int n) {
  var count = 0;
  var temp = n;
  while (temp > 0) {
    count += temp & 1;
    temp >>= 1;
  }
  return count;
}
