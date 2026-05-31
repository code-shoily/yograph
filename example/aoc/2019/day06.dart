import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
COM)B
B)C
C)D
D)E
E)F
B)G
G)H
D)I
E)J
J)K
K)L
K)YOU
I)SAN
''';

void main() async {
  final (input, isSample) = await loadInput(
    year: 2019,
    day: 6,
    sampleInput: sampleInput,
  );
  final (p1, p2) = solve(input, isSample);
  print('($p1, $p2)');
}

(int, int) solve(String rawInput, bool isSample) {
  final dirBuilder = LabeledBuilder<String, Null>.directed();
  for (final line in getLines(rawInput)) {
    final parts = line.split(')');
    dirBuilder.addEdge(parts[0], parts[1]);
  }
  final dirGraph = dirBuilder.toGraph() as SimpleGraph<String, Null>;
  final comId = dirBuilder.getId('COM')!;
  final p1 = solvePart1(dirGraph, comId);

  final undirBuilder = LabeledBuilder<String, Null>.undirected();
  for (final line in getLines(rawInput)) {
    final parts = line.split(')');
    undirBuilder.addEdge(parts[0], parts[1]);
  }
  final undirGraph = undirBuilder.toGraph() as SimpleGraph<String, Null>;

  final youId = undirBuilder.getId('YOU');
  final sanId = undirBuilder.getId('SAN');

  final p2 = (youId != null && sanId != null)
      ? solvePart2(undirGraph, youId, sanId)
      : 0;

  return (p1, p2);
}

int solvePart1(SimpleGraph<String, Null> graph, int comId) {
  return _countTotalOrbits(graph, comId, 0);
}

int solvePart2(SimpleGraph<String, Null> graph, int youId, int sanId) {
  final path = Dijkstra.shortestPath(graph, youId, sanId);
  return path!.length - 2;
}

int _countTotalOrbits(SimpleGraph<String, Null> graph, int nodeId, int depth) {
  var total = depth;
  for (final childId in graph.successors(nodeId)) {
    total += _countTotalOrbits(graph, childId, depth + 1);
  }
  return total;
}
