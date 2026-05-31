import 'dart:collection';
import '../aoc_helper.dart';

const sampleInput = '''
Sabqponm
abcryxxl
accszExk
acctuvwj
abdefghi
''';

void main() async {
  final (input, isSample) = await loadInput(
    year: 2022,
    day: 12,
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
  final rows = lines.length;
  final cols = lines[0].length;

  late (int, int) startPos;
  late (int, int) endPos;
  final elevations = List.generate(rows, (r) {
    final line = lines[r];
    return List.generate(cols, (c) {
      final char = line[c];
      if (char == 'S') {
        startPos = (r, c);
        return 0;
      } else if (char == 'E') {
        endPos = (r, c);
        return 25;
      } else {
        return char.codeUnitAt(0) - 97;
      }
    });
  });

  final p1 = solvePart1(elevations, startPos, endPos);
  final p2 = solvePart2(elevations, endPos);
  return (p1, p2);
}

int solvePart1(
  List<List<int>> elevations,
  (int, int) startPos,
  (int, int) endPos,
) {
  final rows = elevations.length;
  final cols = elevations[0].length;
  final target = _pack(endPos.$1, endPos.$2);

  final visited = <int>{};
  final queue = Queue<(int id, int dist)>();
  final startId = _pack(startPos.$1, startPos.$2);
  queue.add((startId, 0));
  visited.add(startId);

  while (queue.isNotEmpty) {
    final (id, dist) = queue.removeFirst();
    if (id == target) return dist;

    final (r, c) = _unpack(id);
    final currentElev = elevations[r][c];

    final neighbors = <(int, int)>[];
    if (r > 0) neighbors.add((r - 1, c));
    if (r < rows - 1) neighbors.add((r + 1, c));
    if (c > 0) neighbors.add((r, c - 1));
    if (c < cols - 1) neighbors.add((r, c + 1));

    for (final (nr, nc) in neighbors) {
      final nextElev = elevations[nr][nc];
      if (nextElev - currentElev <= 1) {
        final nid = _pack(nr, nc);
        if (!visited.contains(nid)) {
          visited.add(nid);
          queue.add((nid, dist + 1));
        }
      }
    }
  }

  return -1;
}

int solvePart2(List<List<int>> elevations, (int, int) endPos) {
  final rows = elevations.length;
  final cols = elevations[0].length;

  final visited = <int>{};
  final queue = Queue<(int id, int dist)>();
  final endId = _pack(endPos.$1, endPos.$2);
  queue.add((endId, 0));
  visited.add(endId);

  while (queue.isNotEmpty) {
    final (id, dist) = queue.removeFirst();
    final (r, c) = _unpack(id);
    final currentElev = elevations[r][c];

    if (currentElev == 0) return dist;

    final neighbors = <(int, int)>[];
    if (r > 0) neighbors.add((r - 1, c));
    if (r < rows - 1) neighbors.add((r + 1, c));
    if (c > 0) neighbors.add((r, c - 1));
    if (c < cols - 1) neighbors.add((r, c + 1));

    for (final (nr, nc) in neighbors) {
      final nextElev = elevations[nr][nc];
      if (currentElev - nextElev <= 1) {
        final nid = _pack(nr, nc);
        if (!visited.contains(nid)) {
          visited.add(nid);
          queue.add((nid, dist + 1));
        }
      }
    }
  }

  return -1;
}

int _pack(int r, int c) => (r << 16) | c;

(int, int) _unpack(int id) => (id >> 16, id & 0xFFFF);
