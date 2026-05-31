import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
kh-tc
qp-kh
de-cg
ka-co
yn-aq
qp-ub
cg-tb
vc-aq
tb-ka
wh-tc
yn-cg
kh-ub
ta-co
de-co
tc-td
tb-yn
de-ot
tb-vc
aq-co
aq-yn
yn-ka
vy-de
kh-tc
yn-ub
tc-qp
tb-de
vy-tb
vy-tc
yp-de
yp-as
aq-dd
lh-tb
ub-vc
de-dd
tc-co
dy-as
tc-yn
yn-de
dd-co
ta-ru
ta-to
qp-kh
rp-jt
co-tc
tc-td
tb-co
de-ot
''';

void main() async {
  final (input, _) = await loadInput(
    year: 2024,
    day: 23,
    sampleInput: sampleInput,
  );
  final graph = parse(input);
  final (p1, p2) = solve(graph);
  print('($p1, $p2)');
}

SimpleGraph<String, Null> parse(String input) {
  final builder = LabeledBuilder<String, Null>.undirected();
  final lines = input.trim().split('\n');
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    final parts = line.split('-');
    builder.addEdge(parts[0].trim(), parts[1].trim());
  }
  return builder.toGraph() as SimpleGraph<String, Null>;
}

(int, String) solve(SimpleGraph<String, Null> graph) {
  final cliques3 = Clique.kCliques(graph, 3);
  var countPart1 = 0;
  for (final clique in cliques3) {
    final names = clique.map((id) => graph.nodeData(id)!).toList();
    if (names.any((name) => name.startsWith('t'))) {
      countPart1++;
    }
  }
  final maxCliqueSet = Clique.maxClique(graph);
  final maxCliqueNames = maxCliqueSet.map((id) => graph.nodeData(id)!).toList()
    ..sort();
  final password = maxCliqueNames.join(',');
  return (countPart1, password);
}
