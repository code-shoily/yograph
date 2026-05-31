import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
..@@.@@@@.
@@@.@.@.@@
@@@@@.@.@@
@.@@@@..@.
@@.@@@@.@@
.@@@@@@@.@
.@.@.@.@@@
@.@@@.@@@@
.@@@@@@@@.
@.@.@@@.@.
''';

void main() async {
  final (input, isSample) = await loadInput(
    year: 2025,
    day: 4,
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
  final graph1 = _buildGraph(lines);
  final graph2 = _buildGraph(lines);

  return (solvePart1(graph1), solvePart2(graph2));
}

int solvePart1(SimpleGraph<String, Null> graph) {
  var count = 0;
  for (final id in graph.nodeIds) {
    if (graph.successors(id).length < 4) {
      count++;
    }
  }
  return count;
}

int solvePart2(SimpleGraph<String, Null> graph) {
  final removable = <int>[];
  for (final id in graph.nodeIds) {
    if (graph.successors(id).length < 4) {
      removable.add(id);
    }
  }

  var count = 0;
  while (removable.isNotEmpty) {
    final curr = removable.removeAt(0);
    if (graph.hasNode(curr)) {
      final neighbors = graph.successors(curr).toList();
      graph.removeNode(curr);
      count++;

      for (final nid in neighbors) {
        if (graph.hasNode(nid) && graph.successors(nid).length < 4) {
          removable.add(nid);
        }
      }
    }
  }

  return count;
}

SimpleGraph<String, Null> _buildGraph(List<String> lines) {
  final graph = SimpleGraph<String, Null>.undirected();
  final rows = lines.length;
  final cols = lines[0].length;

  for (var r = 0; r < rows; r++) {
    final line = lines[r];
    for (var c = 0; c < cols; c++) {
      if (line[c] == '@') {
        graph.addNode(_pack(r, c), data: '@');
      }
    }
  }

  final directions = const [
    (-1, -1),
    (-1, 0),
    (-1, 1),
    (0, -1),
    (0, 1),
    (1, -1),
    (1, 0),
    (1, 1),
  ];

  for (final id in graph.nodeIds) {
    final (r, c) = _unpack(id);
    for (final (dr, dc) in directions) {
      final nr = r + dr;
      final nc = c + dc;
      if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
        if (lines[nr][nc] == '@') {
          graph.addEdge(id, _pack(nr, nc));
        }
      }
    }
  }

  return graph;
}

int _pack(int r, int c) => (r << 16) | c;

(int, int) _unpack(int id) => (id >> 16, id & 0xFFFF);
