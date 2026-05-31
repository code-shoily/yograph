import 'dart:math';
import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
...........
.S-------7.
.|F-----7|.
.||.....||.
.||.....||.
.|L-7.F-J|.
.|..|.|..|.
.L--J.L--J.
...........
''';

class PipeCell {
  final int row;
  final int col;
  final String char;

  PipeCell(this.row, this.col, this.char);
}

void main() async {
  final (input, isSample) = await loadInput(
    year: 2023,
    day: 10,
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
  final gridData = <List<PipeCell>>[];
  for (var r = 0; r < lines.length; r++) {
    final row = <PipeCell>[];
    final chars = lines[r].split('');
    for (var c = 0; c < chars.length; c++) {
      row.add(PipeCell(r, c, chars[c]));
    }
    gridData.add(row);
  }

  bool canConnect(PipeCell from, PipeCell to) {
    final dr = to.row - from.row;
    final dc = to.col - from.col;

    final validOut = switch (from.char) {
      '|' => dr != 0 && dc == 0,
      '-' => dr == 0 && dc != 0,
      'L' => (dr == -1 && dc == 0) || (dr == 0 && dc == 1),
      'J' => (dr == -1 && dc == 0) || (dr == 0 && dc == -1),
      '7' => (dr == 1 && dc == 0) || (dr == 0 && dc == -1),
      'F' => (dr == 1 && dc == 0) || (dr == 0 && dc == 1),
      'S' => true,
      _ => false,
    };

    final validIn = switch (to.char) {
      '|' => dr != 0 && dc == 0,
      '-' => dr == 0 && dc != 0,
      'L' => (dr == 1 && dc == 0) || (dr == 0 && dc == -1),
      'J' => (dr == 1 && dc == 0) || (dr == 0 && dc == 1),
      '7' => (dr == -1 && dc == 0) || (dr == 0 && dc == 1),
      'F' => (dr == -1 && dc == 0) || (dr == 0 && dc == -1),
      'S' => true,
      _ => false,
    };

    return validOut && validIn;
  }

  final gridGraph = GridBuilder.from2DList<PipeCell>(
    gridData,
    directed: true,
    canMove: canConnect,
  );
  final graph = gridGraph.graph;
  final rows = gridGraph.rows;
  final cols = gridGraph.cols;

  var startId = 0;
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      if (gridData[r][c].char == 'S') {
        startId = r * cols + c;
      }
    }
  }

  // Part 1: Dijkstra distance from startId
  final dists = Dijkstra.singleSourceDistances(graph, startId);
  final p1 = dists.values.reduce(max).toInt();

  // Part 2: Loop isolation & scanline crossing logic
  final loopNodes = isolateLoop(dists.keys.toSet(), graph);

  final sNeighbors = graph
      .successors(startId)
      .where(loopNodes.contains)
      .toList();
  final sr = startId ~/ cols;
  final sc = startId % cols;
  final sOffsets = sNeighbors.map((nid) {
    final nr = nid ~/ cols;
    final nc = nid % cols;
    return (nr - sr, nc - sc);
  }).toSet();

  final hasUp = sOffsets.contains((-1, 0));
  final hasDown = sOffsets.contains((1, 0));
  final hasLeft = sOffsets.contains((0, -1));
  final hasRight = sOffsets.contains((0, 1));

  final sChar = switch ((hasUp, hasDown, hasLeft, hasRight)) {
    (true, true, _, _) => '|',
    (_, _, true, true) => '-',
    (true, _, _, true) => 'L',
    (true, _, true, _) => 'J',
    (_, true, true, _) => '7',
    (_, true, _, true) => 'F',
    _ => 'S',
  };

  var part2 = 0;
  for (var r = 0; r < rows; r++) {
    var inside = false;
    for (var c = 0; c < cols; c++) {
      final id = r * cols + c;
      if (loopNodes.contains(id)) {
        final cell = graph.nodeData(id)!;
        final char = cell.char == 'S' ? sChar : cell.char;
        if (char == '|' || char == 'L' || char == 'J') {
          inside = !inside;
        }
      } else {
        if (inside) {
          part2++;
        }
      }
    }
  }

  return (p1, part2);
}

Set<int> isolateLoop(
  Set<int> initialNodes,
  SimpleGraph<PipeCell, double> graph,
) {
  var nodeSet = Set<int>.from(initialNodes);
  while (true) {
    final toRemove = <int>[];
    for (final id in nodeSet) {
      var loopNeighborsCount = 0;
      for (final nb in graph.successors(id)) {
        if (nodeSet.contains(nb)) {
          loopNeighborsCount++;
        }
      }
      if (loopNeighborsCount < 2) {
        toRemove.add(id);
      }
    }

    if (toRemove.isEmpty) {
      break;
    }

    nodeSet.removeAll(toRemove);
  }
  return nodeSet;
}
