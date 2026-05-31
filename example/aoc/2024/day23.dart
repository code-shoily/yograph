import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

// Sample input from AoC 2024 Day 23 problem description
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
  print('=== ADVENT OF CODE 2024 - DAY 23: LAN PARTY ===\n');

  final (input, _) = await loadInput(
    year: 2024,
    day: 23,
    sampleInput: sampleInput,
  );

  // 2. Parse the connections and build the undirected graph
  final builder = LabeledBuilder<String, Null>.undirected();

  final lines = input.trim().split('\n');
  for (final line in lines) {
    if (line.trim().isEmpty) continue;

    final parts = line.split('-');
    builder.addEdge(parts[0].trim(), parts[1].trim());
  }

  final graph = builder.toGraph() as SimpleGraph<String, Null>;
  print(
    'Constructed Graph: ${graph.nodeCount} computers, ${graph.edgeCount} connection edges.\n',
  );

  // ===========================================================================
  // Part 1: Find all 3-cliques where at least one computer starts with 't'
  // ===========================================================================
  print('Finding all 3-cliques (triangles)...');
  final stopwatchPart1 = Stopwatch()..start();
  final cliques3 = Clique.kCliques(graph, 3);
  stopwatchPart1.stop();

  var countPart1 = 0;
  for (final clique in cliques3) {
    final names = clique.map((id) => graph.nodeData(id)!).toList();
    if (names.any((name) => name.startsWith('t'))) {
      countPart1++;
    }
  }

  print('Part 1 computed in ${stopwatchPart1.elapsedMilliseconds} ms.');
  print('🎯 Part 1 Result:');
  print('  Number of 3-cliques containing a "t" node: $countPart1\n');

  // ===========================================================================
  // Part 2: Find the maximum clique (alphabetically sorted password)
  // ===========================================================================
  print('Computing Maximum Clique (Bron-Kerbosch)...');
  final stopwatchPart2 = Stopwatch()..start();
  final maxCliqueSet = Clique.maxClique(graph);
  stopwatchPart2.stop();

  final maxCliqueNames = maxCliqueSet.map((id) => graph.nodeData(id)!).toList()
    ..sort();
  final password = maxCliqueNames.join(',');

  print('Part 2 computed in ${stopwatchPart2.elapsedMilliseconds} ms.');
  print('🎯 Part 2 Result:');
  print('  Maximum Clique Size: ${maxCliqueNames.length}');
  print('  Alphabetically Sorted Password: $password');
}
