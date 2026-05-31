import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
..@@.@@@@.
@@@.@.@.@@
@@@@@.@.@@
@.@@@@..@.
@@.@@@@.@@
.@@@@@@@.@
.@.@.@.@@@
@.@@@.@@@@
.@@@@@@@@.
@.@.@@@.@.
''';

void main() async {
  final (input, isSample) = await loadInput(
    year: 2025,
    day: 4,
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
  final graph1 = _buildGraph(lines);
  final graph2 = _buildGraph(lines);

  return (solvePart1(graph1), solvePart2(graph2));
}

int solvePart1(SimpleGraph<String, double> graph) {
  var count = 0;
  for (final id in graph.nodeIds) {
    if (graph.successors(id).length < 4) {
      count++;
    }
  }
  return count;
}

int solvePart2(SimpleGraph<String, double> graph) {
  final removable = <int>[];
  for (final id in graph.nodeIds) {
    if (graph.successors(id).length < 4) {
      removable.add(id);
    }
  }

  var count = 0;
  while (removable.isNotEmpty) {
    final curr = removable.removeAt(0);
    if (graph.hasNode(curr)) {
      final neighbors = graph.successors(curr).toList();
      graph.removeNode(curr);
      count++;

      for (final nid in neighbors) {
        if (graph.hasNode(nid) && graph.successors(nid).length < 4) {
          removable.add(nid);
        }
      }
    }
  }

  return count;
}

SimpleGraph<String, double> _buildGraph(List<String> lines) {
  final gridData = lines.map((line) => line.split('')).toList();

  final gridGraph = GridBuilder.from2DListWithTopology(
    gridData,
    GridTopologies.queen,
    topologyName: 'queen',
    directed: false,
    canMove: (fromCell, toCell) => fromCell == '@' && toCell == '@',
  );

  final graph = gridGraph.toGraph();

  // Filter out any nodes that are not '@'
  for (final id in List<int>.from(graph.nodeIds)) {
    if (graph.nodeData(id) != '@') {
      graph.removeNode(id);
    }
  }

  return graph;
}
