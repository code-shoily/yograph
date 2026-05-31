import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
#.#####################
#.......#########...###
#######.#########.#.###
###.....#.>.>.###.#.###
###v#####.#v#.###.#.###
###.>...#.#.#.....#...#
###v###.#.#.#########.#
###...#.#.#.......#...#
#####.#.#.#######.#.###
#.....#.#.#.......#...#
#.#####.#.#.#########v#
#.#...#...#...###...>.#
#.#.#v#######v###.###v#
#...#.>.#...>.>.#.###.#
#####v#.#.###v#.#.###.#
#.....#...#...#.#.#...#
#.#########.###.#.#.###
#...###...#...#...#.###
###.###.#.###v#####v###
#...#...#.#.>.>.#.>.###
#.###.###.#.###.#.#v###
#.....###...###...#...#
#####################.#
''';

void main() async {
  final (input, isSample) = await loadInput(
    year: 2023,
    day: 23,
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
  final height = lines.length;
  final width = lines[0].length;

  final grid = <(int, int), String>{};
  for (var r = 0; r < height; r++) {
    final chars = lines[r].split('');
    for (var c = 0; c < width; c++) {
      grid[(r, c)] = chars[c];
    }
  }

  final startPos = (0, 1);
  final goalPos = (height - 1, width - 2);

  List<(int, int)> getNeighbors((int, int) pos, int part) {
    final r = pos.$1;
    final c = pos.$2;
    final char = grid[pos];

    final candidates = switch ((part, char)) {
      (1, '>') => [(r, c + 1)],
      (1, '<') => [(r, c - 1)],
      (1, 'v') => [(r + 1, c)],
      (1, '^') => [(r - 1, c)],
      _ => [(r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)],
    };

    final result = <(int, int)>[];
    for (final cand in candidates) {
      final val = grid[cand];
      if (val != null && val != '#') {
        result.add(cand);
      }
    }
    return result;
  }

  final intersections = <(int, int)>[];
  for (final entry in grid.entries) {
    final pos = entry.key;
    final char = entry.value;
    if (char != '#') {
      final neighbors = getNeighbors(pos, 2);
      if (neighbors.length > 2 || pos == startPos || pos == goalPos) {
        intersections.add(pos);
      }
    }
  }

  final nodeToId = <(int, int), int>{};
  for (var i = 0; i < intersections.length; i++) {
    nodeToId[intersections[i]] = i;
  }

  final startId = nodeToId[startPos]!;
  final goalId = nodeToId[goalPos]!;

  (int, int, int)? walkToIntersection(
    (int, int) curr,
    (int, int) prev,
    int dist,
    int part,
  ) {
    var c = curr;
    var p = prev;
    var d = dist;
    while (true) {
      if (nodeToId.containsKey(c)) {
        return (c.$1, c.$2, d);
      }
      final nexts = getNeighbors(c, part).where((n) => n != p).toList();
      if (nexts.length == 1) {
        p = c;
        c = nexts[0];
        d++;
      } else {
        return null;
      }
    }
  }

  SimpleGraph<Null, double> buildCompressedGraph(int part) {
    final compGraph = SimpleGraph<Null, double>.directed();
    for (final id in nodeToId.values) {
      compGraph.addNode(id);
    }

    for (final entry in nodeToId.entries) {
      final sPos = entry.key;
      final sId = entry.value;
      for (final firstStep in getNeighbors(sPos, part)) {
        final walkRes = walkToIntersection(firstStep, sPos, 1, part);
        if (walkRes != null) {
          final ePos = (walkRes.$1, walkRes.$2);
          final dist = walkRes.$3;
          final eId = nodeToId[ePos]!;
          compGraph.addEdge(sId, eId, data: dist.toDouble());
        }
      }
    }
    return compGraph;
  }

  int longestPath(int start, int goal, SimpleGraph<Null, double> graph) {
    int dfs(int curr, int visited, int cost) {
      if (curr == goal) return cost;

      var maxCost = -1;
      for (final nextId in graph.successors(curr)) {
        final mask = 1 << nextId;
        if ((visited & mask) == 0) {
          final edgeW = graph.edgeData(curr, nextId)!.toInt();
          final res = dfs(nextId, visited | mask, cost + edgeW);
          if (res > maxCost) {
            maxCost = res;
          }
        }
      }
      return maxCost;
    }

    return dfs(start, 1 << start, 0);
  }

  final graph1 = buildCompressedGraph(1);
  final p1 = longestPath(startId, goalId, graph1);

  final graph2 = buildCompressedGraph(2);
  final p2 = longestPath(startId, goalId, graph2);

  return (p1, p2);
}
