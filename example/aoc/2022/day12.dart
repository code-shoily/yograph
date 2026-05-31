import 'package:yograph/yograph.dart';
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

  int startId = 0;
  int endId = 0;
  final gridData = <List<int>>[];
  final cols = lines[0].length;

  for (var r = 0; r < lines.length; r++) {
    final row = <int>[];
    final chars = lines[r].split('');
    for (var c = 0; c < chars.length; c++) {
      final ch = chars[c];
      if (ch == 'S') {
        startId = r * cols + c;
        row.add(0);
      } else if (ch == 'E') {
        endId = r * cols + c;
        row.add(25);
      } else {
        row.add(ch.codeUnitAt(0) - 'a'.codeUnitAt(0));
      }
    }
    gridData.add(row);
  }

  // Part 1: Dijkstra shortest path from S to E
  final gridGraph = GridBuilder.from2DList<int>(
    gridData,
    directed: true,
    canMove: (fromHeight, toHeight) => toHeight <= fromHeight + 1,
  );

  final path = Dijkstra.shortestPath(gridGraph.graph, startId, endId);
  final p1 = path != null ? path.weight.toInt() : 0;

  // Part 2: Backward Dijkstra singleSourceDistances from E
  final reversedGraph = GridBuilder.from2DList<int>(
    gridData,
    directed: true,
    canMove: (fromHeight, toHeight) => fromHeight <= toHeight + 1,
  );

  final dists = Dijkstra.singleSourceDistances(reversedGraph.graph, endId);
  var minP2 = 999999999;
  for (final entry in dists.entries) {
    final nodeId = entry.key;
    final dist = entry.value;
    if (reversedGraph.graph.nodeData(nodeId) == 0 && dist < minP2) {
      minP2 = dist.toInt();
    }
  }

  return (p1, minP2);
}
