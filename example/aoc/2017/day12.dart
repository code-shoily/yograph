import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
0 <-> 2
1 <-> 1
2 <-> 0, 3, 4
3 <-> 2, 4
4 <-> 2, 3, 6
5 <-> 6
6 <-> 4, 5
''';

void main() async {
  final (input, isSample) = await loadInput(
    year: 2017,
    day: 12,
    sampleInput: sampleInput,
  );
  final (p1, p2) = solve(input, isSample);
  print('($p1, $p2)');
}

(int, int) solve(String rawInput, bool isSample) {
  final graph = parse(rawInput);
  return (solvePart1(graph), solvePart2(graph));
}

SimpleGraph<int, Null> parse(String input) {
  final builder = LabeledBuilder<int, Null>.undirected();
  for (final line in getLines(input)) {
    final parts = line.split(' <-> ');
    final u = int.parse(parts[0]);
    final dests = parts[1].split(', ').map(int.parse);
    for (final v in dests) {
      builder.addEdge(u, v);
    }
  }
  return builder.toGraph() as SimpleGraph<int, Null>;
}

int solvePart1(SimpleGraph<int, Null> graph) {
  final visited = <int>{};
  final stack = [0];
  visited.add(0);

  while (stack.isNotEmpty) {
    final node = stack.removeLast();
    for (final neighbor in graph.successors(node)) {
      if (!visited.contains(neighbor)) {
        visited.add(neighbor);
        stack.add(neighbor);
      }
    }
  }

  return visited.length;
}

int solvePart2(SimpleGraph<int, Null> graph) {
  return Components.connectedComponents(graph).length;
}
