import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
light red bags contain 1 bright white bag, 2 muted yellow bags.
dark orange bags contain 3 bright white bags, 4 muted yellow bags.
bright white bags contain 1 shiny gold bag.
muted yellow bags contain 2 shiny gold bags, 9 faded blue bags.
shiny gold bags contain 1 dark olive bag, 2 vibrant plum bags.
dark olive bags contain 3 faded blue bags, 4 dotted black bags.
vibrant plum bags contain 5 faded blue bags, 6 dotted black bags.
faded blue bags contain no other bags.
dotted black bags contain no other bags.
''';

void main() async {
  final (input, isSample) = await loadInput(
    year: 2020,
    day: 7,
    sampleInput: sampleInput,
  );
  final (p1, p2) = solve(input, isSample);
  print('($p1, $p2)');
}

(int, int) solve(String rawInput, bool isSample) {
  final builder = LabeledBuilder<String, double>.directed();
  final parentRegex = RegExp(r'^(.+?) bags contain (.+?)\.$');
  final childRegex = RegExp(r'^(\d+) (.+?) bags?$');

  for (final line in getLines(rawInput)) {
    final parentMatch = parentRegex.firstMatch(line);
    if (parentMatch != null) {
      final parent = parentMatch.group(1)!;
      final contents = parentMatch.group(2)!;
      if (contents != 'no other bags') {
        for (final part in contents.split(', ')) {
          final childMatch = childRegex.firstMatch(part);
          if (childMatch != null) {
            final count = double.parse(childMatch.group(1)!);
            final child = childMatch.group(2)!;
            builder.addEdge(parent, child, data: count);
          }
        }
      }
    }
  }

  final graph = builder.toGraph() as SimpleGraph<String, double>;
  final shinyGoldId = builder.getId('shiny gold')!;

  return (solvePart1(graph, shinyGoldId), solvePart2(graph, shinyGoldId));
}

int solvePart1(SimpleGraph<String, double> graph, int shinyGoldId) {
  final visited = <int>{};
  final queue = [shinyGoldId];
  visited.add(shinyGoldId);

  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    for (final parent in graph.predecessors(current)) {
      if (!visited.contains(parent)) {
        visited.add(parent);
        queue.add(parent);
      }
    }
  }

  return visited.length - 1;
}

int solvePart2(SimpleGraph<String, double> graph, int shinyGoldId) {
  return _countBagsInside(graph, shinyGoldId);
}

int _countBagsInside(SimpleGraph<String, double> graph, int nodeId) {
  var total = 0;
  for (final childId in graph.successors(nodeId)) {
    final count = graph.edgeWeight(nodeId, childId).toInt();
    total += count + count * _countBagsInside(graph, childId);
  }
  return total;
}
