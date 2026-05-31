import 'dart:io';
import 'package:yograph/yograph.dart';

// Sample input from AoC 2024 Day 18 problem description
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
  print('=== ADVENT OF CODE 2024 - DAY 18: RAM RUN ===\n');

  // 1. Load the puzzle input (fall back to sample if file doesn't exist)
  String? rawInput;
  final envSrc = Platform.environment['AOC_INPUT_SRC'];
  if (envSrc != null && envSrc.isNotEmpty) {
    final envFile = File('$envSrc/2024_18.txt');
    if (await envFile.exists()) {
      print('Reading puzzle input from environment source: ${envFile.path}');
      rawInput = await envFile.readAsString();
    }
  }

  if (rawInput == null) {
    final localFile = File('example/aoc/2024/inputs/day18.txt');
    if (await localFile.exists()) {
      print('Reading puzzle input from local source: ${localFile.path}');
      rawInput = await localFile.readAsString();
    }
  }

  final input = rawInput ?? sampleInput;
  final isSample = rawInput == null;
  if (isSample) {
    print('No input file found. Using sample input instead...');
  }

  // 2. Parse byte coordinates
  final byteCoords = <(int x, int y)>[];
  final lines = input.trim().split('\n');
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    final parts = line.split(',');
    byteCoords.add((int.parse(parts[0].trim()), int.parse(parts[1].trim())));
  }

  // Decide grid size and the number of falling bytes for Part 1
  final size = isSample ? 7 : 71;
  final part1BytesCount = isSample ? 12 : 1024;

  print('Grid Size: ${size}x$size');
  print('Total falling bytes listed: ${byteCoords.length}');

  // ===========================================================================
  // Part 1: shortest path after first N bytes have fallen (Implicit A*)
  // ===========================================================================
  final corruptedPart1 = byteCoords.take(part1BytesCount).toSet();

  final stopwatchPart1 = Stopwatch()..start();
  final resultPart1 = _findPath(size, corruptedPart1);
  stopwatchPart1.stop();

  if (resultPart1 == null) {
    print('⚠️ Part 1: No path found!');
  } else {
    print('Part 1 computed in ${stopwatchPart1.elapsedMilliseconds} ms.');
    print('🎯 Part 1 Result:');
    print('  Shortest path steps: ${resultPart1.toInt()}\n');
  }

  // ===========================================================================
  // Part 2: Find the first falling byte that blocks all paths (Binary Search)
  // ===========================================================================
  print('Finding the first blocking byte using Binary Search...');
  final stopwatchPart2 = Stopwatch()..start();

  var low = part1BytesCount;
  var high = byteCoords.length - 1;
  var firstBlockingIndex = -1;

  while (low <= high) {
    final mid = (low + high) ~/ 2;
    final corrupted = byteCoords.take(mid + 1).toSet();

    final cost = _findPath(size, corrupted);

    if (cost == null) {
      // Path is blocked! Move left to see if there is an earlier blocker.
      firstBlockingIndex = mid;
      high = mid - 1;
    } else {
      // Path still exists. The blocker falls later.
      low = mid + 1;
    }
  }

  stopwatchPart2.stop();

  if (firstBlockingIndex != -1) {
    final (x, y) = byteCoords[firstBlockingIndex];
    print('Part 2 computed in ${stopwatchPart2.elapsedMilliseconds} ms.');
    print('🎯 Part 2 Result:');
    print('  First blocking byte index: $firstBlockingIndex');
    print('  Coordinate of first blocking byte: $x,$y');
  } else {
    print('⚠️ Part 2: No blocking byte found!');
  }
}

/// Runs implicit A* on the grid space without building any graph representation.
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
