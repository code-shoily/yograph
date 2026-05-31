import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
Alice would gain 54 happiness units by sitting next to Bob.
Alice would lose 79 happiness units by sitting next to Carol.
Alice would lose 2 happiness units by sitting next to David.
Bob would gain 83 happiness units by sitting next to Alice.
Bob would lose 7 happiness units by sitting next to Carol.
Bob would lose 63 happiness units by sitting next to David.
Carol would lose 62 happiness units by sitting next to Alice.
Carol would gain 60 happiness units by sitting next to Bob.
Carol would gain 55 happiness units by sitting next to David.
David would gain 46 happiness units by sitting next to Alice.
David would lose 7 happiness units by sitting next to Bob.
David would gain 41 happiness units by sitting next to Carol.
''';

void main() async {
  final (input, isSample) = await loadInput(
    year: 2015,
    day: 13,
    sampleInput: sampleInput,
  );
  final (p1, p2) = solve(input, isSample);
  print('($p1, $p2)');
}

(int, int) solve(String rawInput, bool isSample) {
  final graph = parse(rawInput);
  return (solvePart1(graph), solvePart2(graph));
}

SimpleGraph<String, double> parse(String input) {
  final builder = LabeledBuilder<String, double>.undirected();
  final regex = RegExp(
    r'^(\w+) would (gain|lose) (\d+) happiness units by sitting next to (\w+)\.$',
  );
  final relationshipWeights = <(String, String), double>{};

  for (final line in getLines(input)) {
    final match = regex.firstMatch(line);
    if (match != null) {
      final a = match.group(1)!;
      final action = match.group(2)!;
      final value = int.parse(match.group(3)!);
      final b = match.group(4)!;
      final weight = value * (action == 'gain' ? 1.0 : -1.0);
      relationshipWeights[(a, b)] = weight;
    }
  }

  final people = relationshipWeights.keys.map((k) => k.$1).toSet();
  for (final a in people) {
    for (final b in people) {
      if (a != b) {
        final w1 = relationshipWeights[(a, b)] ?? 0.0;
        final w2 = relationshipWeights[(b, a)] ?? 0.0;
        builder.addEdge(a, b, data: w1 + w2);
      }
    }
  }

  return builder.toGraph() as SimpleGraph<String, double>;
}

int solvePart1(SimpleGraph<String, double> graph) {
  return _solveGraph(graph, includeMe: false);
}

int solvePart2(SimpleGraph<String, double> graph) {
  return _solveGraph(graph, includeMe: true);
}

int _solveGraph(SimpleGraph<String, double> graph, {required bool includeMe}) {
  final nodes = graph.nodeIds.toList();
  final n = nodes.length;
  final totalN = includeMe ? n + 1 : n;

  final weights = List.generate(totalN, (_) => List.filled(totalN, 0));
  for (var i = 0; i < n; i++) {
    for (var j = 0; j < n; j++) {
      if (i != j) {
        final u = nodes[i];
        final v = nodes[j];
        if (graph.hasEdge(u, v)) {
          weights[i][j] = graph.edgeWeight(u, v).toInt();
        }
      }
    }
  }

  final targetMask = (1 << totalN) - 1;
  return _tsp(0, 1, 0, targetMask, weights, totalN, {});
}

int _tsp(
  int curr,
  int mask,
  int root,
  int targetMask,
  List<List<int>> weights,
  int n,
  Map<int, int> memo,
) {
  if (mask == targetMask) {
    return weights[curr][root];
  }
  final key = (curr << 16) | mask;
  if (memo.containsKey(key)) return memo[key]!;

  var best = -99999999;
  for (var next = 0; next < n; next++) {
    if ((mask & (1 << next)) == 0) {
      final val =
          weights[curr][next] +
          _tsp(next, mask | (1 << next), root, targetMask, weights, n, memo);
      if (val > best) {
        best = val;
      }
    }
  }
  memo[key] = best;
  return best;
}
