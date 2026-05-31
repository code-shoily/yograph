import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
5,4
4,2
4,5
3,0
2,1
6,3
2,4
1,5
0,6
3,3
2,6
5,1
1,2
5,5
2,5
6,5
1,4
0,4
6,4
1,1
6,1
1,0
0,5
1,6
2,0
''';

void main() async {
  final (input, isSample) = await loadInput(
    year: 2024,
    day: 18,
    sampleInput: sampleInput,
  );
  final (p1, p2) = solve(input, isSample);
  print('($p1, $p2)');
}

(int, String) solve(String rawInput, bool isSample) {
  final parsed = parse(rawInput);
  return (solvePart1(parsed, isSample), solvePart2(parsed, isSample));
}

List<(int, int)> parse(String input) {
  final byteCoords = <(int, int)>[];
  for (final line in getLines(input)) {
    final parts = line.split(',');
    byteCoords.add((int.parse(parts[0]), int.parse(parts[1])));
  }
  return byteCoords;
}

int solvePart1(List<(int, int)> byteCoords, bool isSample) {
  final size = isSample ? 7 : 71;
  final part1BytesCount = isSample ? 12 : 1024;
  final corrupted = byteCoords.take(part1BytesCount).toSet();
  final cost = _findPath(size, corrupted);
  return cost?.toInt() ?? -1;
}

String solvePart2(List<(int, int)> byteCoords, bool isSample) {
  final size = isSample ? 7 : 71;
  final part1BytesCount = isSample ? 12 : 1024;

  var low = part1BytesCount;
  var high = byteCoords.length - 1;
  var firstBlockingIndex = -1;

  while (low <= high) {
    final mid = (low + high) ~/ 2;
    final corrupted = byteCoords.take(mid + 1).toSet();
    final cost = _findPath(size, corrupted);
    if (cost == null) {
      firstBlockingIndex = mid;
      high = mid - 1;
    } else {
      low = mid + 1;
    }
  }

  if (firstBlockingIndex != -1) {
    final (x, y) = byteCoords[firstBlockingIndex];
    return '$x,$y';
  }
  return 'No Blocking Byte';
}

double? _findPath(int size, Set<(int, int)> corrupted) {
  final target = size - 1;

  Iterable<((int, int), double)> successors((int x, int y) pos) {
    final next = <((int, int), double)>[];
    for (final (dx, dy) in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
      final nx = pos.$1 + dx;
      final ny = pos.$2 + dy;
      if (nx >= 0 && nx <= target && ny >= 0 && ny <= target) {
        if (!corrupted.contains((nx, ny))) {
          next.add(((nx, ny), 1.0));
        }
      }
    }
    return next;
  }

  bool isGoal((int, int) pos) => pos.$1 == target && pos.$2 == target;

  double heuristic((int, int) pos) {
    return ((pos.$1 - target).abs() + (pos.$2 - target).abs()).toDouble();
  }

  final result = AStar.implicitAStar<(int, int)>(
    from: (0, 0),
    successors: successors,
    isGoal: isGoal,
    heuristic: heuristic,
  );

  return result?.$2;
}
