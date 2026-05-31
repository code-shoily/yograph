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
  final parsed = parse(input);
  final (p1, p2) = solve(parsed, isSample);
  print('($p1, $p2)');
}

List<(int, int)> parse(String input) {
  final byteCoords = <(int, int)>[];
  final lines = input.trim().split('\n');
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    final parts = line.split(',');
    byteCoords.add((int.parse(parts[0].trim()), int.parse(parts[1].trim())));
  }
  return byteCoords;
}

(int, String) solve(List<(int, int)> byteCoords, bool isSample) {
  final size = isSample ? 7 : 71;
  final part1BytesCount = isSample ? 12 : 1024;

  final corruptedPart1 = byteCoords.take(part1BytesCount).toSet();
  final costPart1 = _findPath(size, corruptedPart1);
  final p1 = costPart1?.toInt() ?? -1;

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
    return (p1, '$x,$y');
  }
  return (p1, 'No Blocking Byte');
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
