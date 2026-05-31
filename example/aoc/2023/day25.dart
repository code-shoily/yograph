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
  final (input, isSample) = await loadInput(
    year: 2023,
    day: 25,
    sampleInput: sampleInput,
  );
  final (p1, p2) = solve(input, isSample);
  print('($p1, $p2)');
}

(int, String) solve(String rawInput, bool isSample) {
  final parsed = parse(rawInput);
  return (solvePart1(parsed), solvePart2(parsed));
}

SimpleGraph<String, double> parse(String input) {
  final builder = LabeledBuilder<String, double>.undirected();
  for (final line in getLines(input)) {
    final parts = line.split(': ');
    final from = parts[0];
    final toComponents = parts[1].split(' ');
    for (final to in toComponents) {
      builder.addEdge(from, to, data: 1.0);
    }
  }
  return builder.toGraph() as SimpleGraph<String, double>;
}

int solvePart1(SimpleGraph<String, double> graph) {
  final result = MinCut.globalMinCut(graph);
  return result.sourceSideSize * result.sinkSideSize;
}

String solvePart2(SimpleGraph<String, double> graph) {
  return 'Balanced';
}
