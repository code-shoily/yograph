import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
2199943210
3987894921
9856789892
8767896789
9899965678
''';

void main() async {
  final (input, isSample) = await loadInput(
    year: 2021,
    day: 9,
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
  final gridData = lines
      .map((line) => line.split('').map(int.parse).toList())
      .toList();

  // Create Rook (4-neighbor) grid graph of node heights
  final gridGraph = GridBuilder.from2DList<int>(gridData);
  final graph = gridGraph.graph;
  final rows = gridGraph.rows;
  final cols = gridGraph.cols;

  // Part 1: Risk points sum (height + 1 for all low points)
  var riskSum = 0;
  for (var id = 0; id < rows * cols; id++) {
    final height = graph.nodeData(id)!;
    var isLow = true;
    for (final neighborId in graph.successors(id)) {
      final neighborHeight = graph.nodeData(neighborId)!;
      if (neighborHeight <= height) {
        isLow = false;
        break;
      }
    }
    if (isLow) {
      riskSum += height + 1;
    }
  }

  // Part 2: Basin multiplier (find connected components of sub-graph with heights < 9)
  final subGraph = SimpleGraph<int, double>.undirected();

  // Add all valid nodes (height < 9)
  for (var id = 0; id < rows * cols; id++) {
    final height = graph.nodeData(id)!;
    if (height < 9) {
      subGraph.addNode(id, data: height);
    }
  }

  // Add edges between adjacent valid nodes
  for (final fromId in subGraph.nodeIds) {
    for (final toId in graph.successors(fromId)) {
      if (subGraph.hasNode(toId) && fromId < toId) {
        subGraph.addEdge(fromId, toId, data: 1.0);
      }
    }
  }

  final components = Components.connectedComponents(subGraph);
  final sortedSizes = components.map((c) => c.length).toList()
    ..sort((a, b) => b.compareTo(a));

  final p2 = sortedSizes[0] * sortedSizes[1] * sortedSizes[2];

  return (riskSum, p2);
}
