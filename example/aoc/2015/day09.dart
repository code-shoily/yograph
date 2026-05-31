import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
London to Dublin = 464
London to Belfast = 141
Dublin to Belfast = 141
''';

void main() async {
  final (input, isSample) = await loadInput(
    year: 2015,
    day: 9,
    sampleInput: sampleInput,
  );
  final (p1, p2) = solve(input, isSample);
  print('($p1, $p2)');
}

(int, int) solve(String rawInput, bool isSample) {
  final graph = parse(rawInput);
  return (solvePart1(graph), solvePart2(graph));
}

SimpleGraph<String, double> parse(String input) {
  final builder = LabeledBuilder<String, double>.undirected();
  for (final line in getLines(input)) {
    final regex = RegExp(r'^(\w+) to (\w+) = (\d+)$');
    final match = regex.firstMatch(line);
    if (match != null) {
      final from = match.group(1)!;
      final to = match.group(2)!;
      final dist = double.parse(match.group(3)!);
      builder.addEdge(from, to, data: dist);
    }
  }
  return builder.toGraph() as SimpleGraph<String, double>;
}

int solvePart1(SimpleGraph<String, double> graph) {
  final nodes = graph.nodeIds.toList();
  final paths = permutations(nodes);
  var minDistance = 99999999;
  for (final path in paths) {
    final dist = _pathDistance(path, graph);
    if (dist != null && dist < minDistance) {
      minDistance = dist;
    }
  }
  return minDistance;
}

int solvePart2(SimpleGraph<String, double> graph) {
  final nodes = graph.nodeIds.toList();
  final paths = permutations(nodes);
  var maxDistance = 0;
  for (final path in paths) {
    final dist = _pathDistance(path, graph);
    if (dist != null && dist > maxDistance) {
      maxDistance = dist;
    }
  }
  return maxDistance;
}

int? _pathDistance(List<int> path, SimpleGraph<String, double> graph) {
  var total = 0;
  for (var i = 0; i < path.length - 1; i++) {
    final u = path[i];
    final v = path[i + 1];
    if (!graph.hasEdge(u, v)) return null;
    total += graph.edgeWeight(u, v).toInt();
  }
  return total;
}

List<List<T>> permutations<T>(List<T> list) {
  if (list.isEmpty) return [[]];
  final result = <List<T>>[];
  for (var i = 0; i < list.length; i++) {
    final x = list[i];
    final remaining = List<T>.from(list)..removeAt(i);
    for (final rest in permutations(remaining)) {
      result.add([x, ...rest]);
    }
  }
  return result;
}
