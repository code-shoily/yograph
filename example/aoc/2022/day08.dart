import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
30373
25512
65332
33549
35390
''';

void main() async {
  final (input, isSample) = await loadInput(
    year: 2022,
    day: 8,
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

  final gridGraph = GridBuilder.from2DList<int>(gridData);
  final rows = gridGraph.rows;
  final cols = gridGraph.cols;

  var visibleCount = 0;
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      if (r == 0 || r == rows - 1 || c == 0 || c == cols - 1) {
        visibleCount++;
      } else {
        final h = gridGraph.graph.nodeData(r * cols + c)!;
        final directions = [(-1, 0), (1, 0), (0, -1), (0, 1)];
        var visible = false;
        for (final (dr, dc) in directions) {
          final heights = directionalWalk(gridGraph, r + dr, c + dc, dr, dc);
          if (heights.every((otherH) => otherH < h)) {
            visible = true;
            break;
          }
        }
        if (visible) {
          visibleCount++;
        }
      }
    }
  }

  var maxScenic = 0;
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      final h = gridGraph.graph.nodeData(r * cols + c)!;
      final directions = [(-1, 0), (1, 0), (0, -1), (0, 1)];
      var score = 1;
      for (final (dr, dc) in directions) {
        score *= viewingDistance(gridGraph, r + dr, c + dc, dr, dc, h);
      }
      if (score > maxScenic) {
        maxScenic = score;
      }
    }
  }

  return (visibleCount, maxScenic);
}

List<int> directionalWalk(
  GridGraph<int, double> gridGraph,
  int startR,
  int startC,
  int dr,
  int dc,
) {
  final rows = gridGraph.rows;
  final cols = gridGraph.cols;
  final startId = startR * cols + startC;

  if (startR < 0 || startR >= rows || startC < 0 || startC >= cols) {
    return const [];
  }

  return implicitFoldBy<int, int, List<int>>(
    startId,
    order: Order.breadthFirst,
    initial: <int>[],
    successorsOf: (nodeId) {
      final r = nodeId ~/ cols;
      final c = nodeId % cols;
      final nr = r + dr;
      final nc = c + dc;
      if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
        return [nr * cols + nc];
      }
      return const [];
    },
    visitedBy: (id) => id,
    folder: (acc, nodeId, meta) {
      final h = gridGraph.graph.nodeData(nodeId)!;
      acc.add(h);
      return (WalkControl.continueWalk, acc);
    },
  );
}

int viewingDistance(
  GridGraph<int, double> gridGraph,
  int startR,
  int startC,
  int dr,
  int dc,
  int limitHeight,
) {
  final rows = gridGraph.rows;
  final cols = gridGraph.cols;
  final startId = startR * cols + startC;

  if (startR < 0 || startR >= rows || startC < 0 || startC >= cols) {
    return 0;
  }

  return implicitFoldBy<int, int, int>(
    startId,
    order: Order.breadthFirst,
    initial: 0,
    successorsOf: (nodeId) {
      final r = nodeId ~/ cols;
      final c = nodeId % cols;
      final currH = gridGraph.graph.nodeData(nodeId)!;
      final nr = r + dr;
      final nc = c + dc;
      if (currH < limitHeight && nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
        return [nr * cols + nc];
      }
      return const [];
    },
    visitedBy: (id) => id,
    folder: (acc, nodeId, meta) {
      return (WalkControl.continueWalk, acc + 1);
    },
  );
}
