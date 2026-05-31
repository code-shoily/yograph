import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
you: a b
a: out
b: out
svr: dac
dac: fft
fft: out
''';

void main() async {
  final (input, isSample) = await loadInput(
    year: 2025,
    day: 11,
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
  final builder = LabeledBuilder<String, double>.directed();

  // Pre-declare and add all nodes to the builder
  for (final line in lines) {
    final parts = line.split(':');
    if (parts.length != 2) continue;
    final src = parts[0].trim();
    builder.ensureNode(src);

    final dests = parts[1].trim().split(' ');
    for (final dest in dests) {
      final cleanDst = dest.trim();
      if (cleanDst.isNotEmpty) {
        builder.ensureNode(cleanDst);
        builder.addEdge(src, cleanDst, data: 1.0);
      }
    }
  }

  final graph = builder.toGraph() as SimpleGraph<String, double>;

  final p1 = countPaths('you', 'out', graph, builder);

  final p2_1 =
      countPaths('svr', 'dac', graph, builder) *
      countPaths('dac', 'fft', graph, builder) *
      countPaths('fft', 'out', graph, builder);

  final p2_2 =
      countPaths('svr', 'fft', graph, builder) *
      countPaths('fft', 'dac', graph, builder) *
      countPaths('dac', 'out', graph, builder);

  final p2 = p2_1 + p2_2;

  return (p1, p2);
}

int countPaths(
  String source,
  String target,
  SimpleGraph<String, double> graph,
  LabeledBuilder<String, double> builder,
) {
  final sourceId = builder.getId(source);
  final targetId = builder.getId(target);

  if (sourceId == null || targetId == null) return 0;
  if (sourceId == targetId) return 1;

  final sorted = topologicalSort(graph);
  if (sorted == null) {
    return 0;
  }

  final paths = <int, int>{};
  paths[targetId] = 1;

  for (var i = sorted.length - 1; i >= 0; i--) {
    final node = sorted[i];
    if (node == targetId) continue;

    var sum = 0;
    for (final succ in graph.successors(node)) {
      sum += paths[succ] ?? 0;
    }
    paths[node] = sum;
  }

  return paths[sourceId] ?? 0;
}
