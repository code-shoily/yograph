import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
jqt: rhn xhk nvd
rsh: frs pzl lsr
xhk: hfx
cmg: qnr nvd lhk bvb
rhn: xhk bvb hfx
bvb: xhk hfx
pzl: lsr hfx nvd
qnr: nvd
ntq: jqt hfx bvb xhk
nvd: lhk
lsr: lhk
rzs: qnr cmg lsr rsh
frs: qnr lhk lsr
''';

void main() async {
  final (input, _) = await loadInput(
    year: 2023,
    day: 25,
    sampleInput: sampleInput,
  );
  final graph = parse(input);
  final (p1, p2) = solve(graph);
  print('($p1, $p2)');
}

SimpleGraph<String, double> parse(String input) {
  final builder = LabeledBuilder<String, double>.undirected();
  final lines = input.trim().split('\n');
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    final parts = line.split(': ');
    final from = parts[0].trim();
    final toComponents = parts[1].trim().split(' ');
    for (final to in toComponents) {
      builder.addEdge(from, to, data: 1.0);
    }
  }
  return builder.toGraph() as SimpleGraph<String, double>;
}

(int, String) solve(SimpleGraph<String, double> graph) {
  final result = MinCut.globalMinCut(graph);
  final p1 = result.sourceSideSize * result.sinkSideSize;
  return (p1, 'Balanced');
}
