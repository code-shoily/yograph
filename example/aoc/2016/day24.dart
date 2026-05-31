import 'dart:collection';
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
  final grid = getLines(rawInput);

  final pois = <int, (int, int)>{};
  for (var r = 0; r < grid.length; r++) {
    final line = grid[r];
    for (var c = 0; c < line.length; c++) {
      final char = line[c];
      if (char.compareTo('0') >= 0 && char.compareTo('9') <= 0) {
        pois[int.parse(char)] = (r, c);
      }
    }
  }

  final poiDistances = <String, int>{};
  for (final entry1 in pois.entries) {
    final u = entry1.key;
    final (ur, uc) = entry1.value;
    final dists = _bfsDistances(grid, ur, uc);

    for (final entry2 in pois.entries) {
      final v = entry2.key;
      final (vr, vc) = entry2.value;
      final targetId = (vr << 16) | vc;
      poiDistances['$u-$v'] = dists[targetId] ?? 999999;
    }
  }

  final maxPoi = pois.keys.reduce((a, b) => a > b ? a : b);
  final targets = List.generate(maxPoi, (i) => i + 1);

  final perms = _permutations(targets);

  int solveTsp(bool returnToStart) {
    var minDist = 99999999;
    for (final p in perms) {
      final path = [0, ...p];
      if (returnToStart) path.add(0);

      var dist = 0;
      for (var i = 0; i < path.length - 1; i++) {
        dist += poiDistances['${path[i]}-${path[i + 1]}']!;
      }
      if (dist < minDist) {
        minDist = dist;
      }
    }
    return minDist;
  }

  return (solveTsp(false), solveTsp(true));
}

Map<int, int> _bfsDistances(List<String> grid, int startR, int startC) {
  final rows = grid.length;
  final cols = grid[0].length;

  final distances = <int, int>{};
  final visited = <int>{};
  final q = Queue<((int, int) pos, int dist)>();

  final startId = (startR << 16) | startC;
  q.add(((startR, startC), 0));
  visited.add(startId);

  while (q.isNotEmpty) {
    final (pos, dist) = q.removeFirst();
    final (r, c) = pos;

    final id = (r << 16) | c;
    distances[id] = dist;

    final neighbors = <(int, int)>[];
    if (r > 0) neighbors.add((r - 1, c));
    if (r < rows - 1) neighbors.add((r + 1, c));
    if (c > 0) neighbors.add((r, c - 1));
    if (c < cols - 1) neighbors.add((r, c + 1));

    for (final (nr, nc) in neighbors) {
      if (grid[nr][nc] != '#') {
        final nid = (nr << 16) | nc;
        if (!visited.contains(nid)) {
          visited.add(nid);
          q.add(((nr, nc), dist + 1));
        }
      }
    }
  }

  return distances;
}

List<List<int>> _permutations(List<int> list) {
  if (list.isEmpty) return [[]];
  final result = <List<int>>[];
  for (var i = 0; i < list.length; i++) {
    final x = list[i];
    final remaining = List<int>.from(list)..removeAt(i);
    for (final perm in _permutations(remaining)) {
      result.add([x, ...perm]);
    }
  }
  return result;
}
