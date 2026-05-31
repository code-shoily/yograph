import 'dart:math';
import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
###########
#0.1.....2#
#.#######.#
#4.......3#
###########
''';

void main() async {
  final (input, isSample) = await loadInput(
    year: 2016,
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
  final gridData = lines.map((line) => line.split('')).toList();

  // Create the Rook (4-neighbor) grid graph, avoiding walls ('#')
  final gridGraph = GridBuilder.from2DList<String>(
    gridData,
    canMove: (from, to) => from != '#' && to != '#',
  );

  // Extract positions of numbered Points of Interest (0-9)
  final pois = <int, int>{};
  final rows = gridData.length;
  final cols = gridData[0].length;
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      final val = gridData[r][c];
      if (val != '#' && val != '.') {
        final digit = int.tryParse(val);
        if (digit != null) {
          pois[digit] = r * cols + c;
        }
      }
    }
  }

  // Pre-calculate distances between all POIs using Dijkstra
  final distances = <(int, int), int>{};
  for (final entryU in pois.entries) {
    final u = entryU.key;
    final uId = entryU.value;
    final dists = Dijkstra.singleSourceDistances(gridGraph.graph, uId);

    for (final entryV in pois.entries) {
      final v = entryV.key;
      final vId = entryV.value;
      final dist = dists[vId];
      if (dist != null) {
        distances[(u, v)] = dist.toInt();
      }
    }
  }

  final maxPoi = pois.keys.reduce(max);
  final targets = List<int>.generate(maxPoi, (i) => i + 1);

  final perms = permutations(targets);

  var minP1 = 999999999;
  var minP2 = 999999999;

  for (final p in perms) {
    // Part 1: path starts at 0, goes through permutation p
    final path1 = [0, ...p];
    var dist1 = 0;
    for (var i = 0; i < path1.length - 1; i++) {
      dist1 += distances[(path1[i], path1[i + 1])] ?? 99999999;
    }
    if (dist1 < minP1) {
      minP1 = dist1;
    }

    // Part 2: path starts at 0, goes through permutation p, and returns to 0
    final path2 = [0, ...p, 0];
    var dist2 = 0;
    for (var i = 0; i < path2.length - 1; i++) {
      dist2 += distances[(path2[i], path2[i + 1])] ?? 99999999;
    }
    if (dist2 < minP2) {
      minP2 = dist2;
    }
  }

  return (minP1, minP2);
}

List<List<int>> permutations(List<int> list) {
  if (list.isEmpty) return [[]];
  final result = <List<int>>[];
  for (var i = 0; i < list.length; i++) {
    final x = list[i];
    final rest = List<int>.from(list)..removeAt(i);
    for (final perm in permutations(rest)) {
      result.add([x, ...perm]);
    }
  }
  return result;
}
