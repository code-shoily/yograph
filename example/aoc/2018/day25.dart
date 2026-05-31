import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
 0,0,0,0
 3,0,0,0
 0,3,0,0
 0,0,3,0
 0,0,0,3
 0,0,0,6
 9,0,0,0
12,0,0,0
''';

void main() async {
  final (input, isSample) = await loadInput(
    year: 2018,
    day: 25,
    sampleInput: sampleInput,
  );
  final stopwatch = Stopwatch()..start();
  final (p1, p2) = solve(input, isSample);
  stopwatch.stop();
  print('($p1, $p2)');
  print('Solved in ${stopwatch.elapsedMilliseconds}ms');
}

(int, String) solve(String rawInput, bool isSample) {
  final points = parse(rawInput);
  final graph = buildGraph(points);
  return (solvePart1(graph), solvePart2(points));
}

List<(int, int, int, int)> parse(String input) {
  final points = <(int, int, int, int)>[];
  for (final line in getLines(input)) {
    final parts = line.split(',').map((s) => int.parse(s.trim())).toList();
    points.add((parts[0], parts[1], parts[2], parts[3]));
  }
  return points;
}

SimpleGraph<(int, int, int, int), Null> buildGraph(
  List<(int, int, int, int)> points,
) {
  final graph = SimpleGraph<(int, int, int, int), Null>.undirected();
  final n = points.length;

  for (var i = 0; i < n; i++) {
    graph.addNode(i, data: points[i]);
  }

  for (var i = 0; i < n; i++) {
    final p1 = points[i];
    for (var j = i + 1; j < n; j++) {
      final p2 = points[j];
      if (manhattanDist(p1, p2) <= 3) {
        graph.addEdge(i, j);
      }
    }
  }

  return graph;
}

int solvePart1(SimpleGraph<(int, int, int, int), Null> graph) {
  final components = Components.connectedComponents(graph);
  return components.length;
}

String solvePart2(List<(int, int, int, int)> points) {
  return 'Finished the 4D adventure! 🥳';
}

int manhattanDist((int, int, int, int) a, (int, int, int, int) b) {
  return (a.$1 - b.$1).abs() +
      (a.$2 - b.$2).abs() +
      (a.$3 - b.$3).abs() +
      (a.$4 - b.$4).abs();
}
