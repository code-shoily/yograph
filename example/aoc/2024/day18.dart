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
  // Part 1: shortest path after first N bytes have fallen
  // ===========================================================================
  final gridPart1 = List.generate(size, (_) => List.filled(size, '.'));
  for (var i = 0; i < part1BytesCount; i++) {
    final (x, y) = byteCoords[i];
    gridPart1[y][x] = '#';
  }

  final gridGraphPart1 = _buildGridGraph(gridPart1);
  final startNode = gridGraphPart1.coordToId(0, 0);
  final endNode = gridGraphPart1.coordToId(size - 1, size - 1);

  // A* Search using a Manhattan distance heuristic
  double heuristic(int node, int goal) {
    final (r1, c1) = gridGraphPart1.idToCoord(node);
    final (r2, c2) = gridGraphPart1.idToCoord(goal);
    return ((r1 - r2).abs() + (c1 - c2).abs()).toDouble();
  }

  final stopwatchPart1 = Stopwatch()..start();
  final path = AStar.aStar(
    gridGraphPart1.toGraph(),
    startNode,
    endNode,
    heuristic: heuristic,
  );
  stopwatchPart1.stop();

  if (path == null) {
    print('⚠️ Part 1: No path found!');
  } else {
    final steps = path.nodes.length - 1;
    print('Part 1 computed in ${stopwatchPart1.elapsedMilliseconds} ms.');
    print('🎯 Part 1 Result:');
    print('  Shortest path steps: $steps\n');
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

    // Build grid up to mid index
    final grid = List.generate(size, (_) => List.filled(size, '.'));
    for (var i = 0; i <= mid; i++) {
      final (x, y) = byteCoords[i];
      grid[y][x] = '#';
    }

    final gridGraph = _buildGridGraph(grid);
    final start = gridGraph.coordToId(0, 0);
    final end = gridGraph.coordToId(size - 1, size - 1);

    double localHeuristic(int node, int goal) {
      final (r1, c1) = gridGraph.idToCoord(node);
      final (r2, c2) = gridGraph.idToCoord(goal);
      return ((r1 - r2).abs() + (c1 - c2).abs()).toDouble();
    }

    final testPath = AStar.aStar(
      gridGraph.toGraph(),
      start,
      end,
      heuristic: localHeuristic,
    );

    if (testPath == null) {
      // Path is blocked! This mid index could be the first blocker, or the blocker is earlier.
      firstBlockingIndex = mid;
      high = mid - 1;
    } else {
      // Path still exists. The blocker must fall later.
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

GridGraph<String, double> _buildGridGraph(List<List<String>> grid) {
  return GridBuilder.from2DListWithTopology<String>(
    grid,
    GridTopologies.rook,
    topologyName: 'rook',
    canMove: (fromCell, toCell) => toCell != '#',
  );
}
