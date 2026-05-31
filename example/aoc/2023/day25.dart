import 'dart:io';
import 'package:yograph/yograph.dart';

// Sample input from AoC 2023 Day 25 problem description
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
  print('=== ADVENT OF CODE 2023 - DAY 25: SNOWVERLOAD ===\n');

  // 1. Load the puzzle input (fall back to sample if file doesn't exist)
  String? rawInput;
  final envSrc = Platform.environment['AOC_INPUT_SRC'];
  if (envSrc != null && envSrc.isNotEmpty) {
    final envFile = File('$envSrc/2023_25.txt');
    if (await envFile.exists()) {
      print('Reading puzzle input from environment source: ${envFile.path}');
      rawInput = await envFile.readAsString();
    }
  }

  if (rawInput == null) {
    final localFile = File('example/aoc/2023/inputs/day25.txt');
    if (await localFile.exists()) {
      print('Reading puzzle input from local source: ${localFile.path}');
      rawInput = await localFile.readAsString();
    }
  }

  final input = rawInput ?? sampleInput;
  if (rawInput == null) {
    print('No input file found. Using sample input instead...');
  }

  // 2. Build the undirected graph
  // We use LabeledBuilder so we can parse String component names (like "jqt", "rhn")
  // and map them dynamically to sequential integer IDs.
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

  final graph = builder.toGraph() as SimpleGraph<String, double>;
  print(
    'Constructed Graph: ${graph.nodeCount} nodes, ${graph.edgeCount} edges.\n',
  );

  // 3. Compute Global Min-Cut using the Stoer-Wagner Algorithm
  print('Running Stoer-Wagner Global Min-Cut...');
  final stopwatch = Stopwatch()..start();
  final result = MinCut.globalMinCut(graph);
  stopwatch.stop();

  print('Min-Cut computed in ${stopwatch.elapsedMilliseconds} ms.');
  print('Cut value (number of severed links): ${result.cutValue.toInt()}');

  final sourceSize = result.sourceSideSize;
  final sinkSize = result.sinkSideSize;
  print('Partition sizes:');
  print('  - Component 1: $sourceSize components');
  print('  - Component 2: $sinkSize components\n');

  if (result.cutValue.toInt() == 3) {
    final answer = sourceSize * sinkSize;
    print('🎯 Success! Severed exactly 3 edges.');
    print('Product of partition sizes: $answer');
  } else {
    print('⚠️  The cut value was not 3. Got: ${result.cutValue}');
  }
}
