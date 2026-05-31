import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
pbga (66)
xhth (57)
ebri (9)
kxlj (33)
ktlj (57)
fwft (72) -> ktlj, cntj, xhth
qoyq (66)
padx (45) -> pbga, havc, qoyq
tknk (41) -> ugml, padx, fwft
jptl (61)
ugml (68) -> gyxo, ebri, jptl
gyxo (61)
cntj (57)
''';

class ProgramNode {
  final String name;
  final int weight;
  final List<String> branches;

  ProgramNode(this.name, this.weight, this.branches);
}

class WeightResult {
  final int own;
  final int total;
  WeightResult(this.own, this.total);
}

void main() async {
  final (input, isSample) = await loadInput(
    year: 2017,
    day: 7,
    sampleInput: sampleInput,
  );
  final stopwatch = Stopwatch()..start();
  final (p1, p2) = solve(input, isSample);
  stopwatch.stop();
  print('($p1, $p2)');
  print('Solved in ${stopwatch.elapsedMilliseconds}ms');
}

(String, int) solve(String rawInput, bool isSample) {
  final lines = getLines(rawInput);
  final parsed = parse(lines);

  final builder = LabeledBuilder<String, Null>.directed();
  final weights = <int, int>{};

  for (final node in parsed) {
    final id = builder.ensureNode(node.name);
    weights[id] = node.weight;
  }

  for (final node in parsed) {
    for (final branch in node.branches) {
      builder.addEdge(node.name, branch);
    }
  }

  final graph = builder.toGraph() as SimpleGraph<String, Null>;

  final rootId = findRoot(graph);
  final p1 = graph.nodeData(rootId)!;

  final subtreeWeights = <int, WeightResult>{};
  getSubtreeWeights(graph, weights, rootId, subtreeWeights);

  final (_, p2) = findUnbalanced(graph, weights, rootId, subtreeWeights);

  return (p1, p2);
}

List<ProgramNode> parse(List<String> lines) {
  final regex = RegExp(r'^([a-z]+)\s*\((\d+)\)(?:\s*->\s*(.*))?$');
  final result = <ProgramNode>[];

  for (final line in lines) {
    final cleanLine = line.trim();
    if (cleanLine.isEmpty) continue;

    final match = regex.firstMatch(cleanLine);
    if (match != null) {
      final name = match.group(1)!;
      final weight = int.parse(match.group(2)!);
      final branchesStr = match.group(3);
      final branches = branchesStr != null
          ? branchesStr.split(',').map((s) => s.trim()).toList()
          : <String>[];
      result.add(ProgramNode(name, weight, branches));
    }
  }
  return result;
}

int findRoot(SimpleGraph<String, Null> graph) {
  for (final id in graph.nodeIds) {
    if (graph.inDegree(id) == 0 && graph.outDegree(id) > 0) {
      return id;
    }
  }
  throw StateError('No root found');
}

WeightResult getSubtreeWeights(
  SimpleGraph<String, Null> graph,
  Map<int, int> weights,
  int node,
  Map<int, WeightResult> memo,
) {
  final cached = memo[node];
  if (cached != null) return cached;

  final own = weights[node] ?? 0;
  var total = own;

  for (final child in graph.successors(node)) {
    total += getSubtreeWeights(graph, weights, child, memo).total;
  }

  final result = WeightResult(own, total);
  memo[node] = result;
  return result;
}

(bool, int) findUnbalanced(
  SimpleGraph<String, Null> graph,
  Map<int, int> weights,
  int node,
  Map<int, WeightResult> subtreeWeights,
) {
  final children = graph.successors(node).toList();
  if (children.isEmpty) {
    return (true, 0);
  }

  final childTotalWeights = children
      .map((c) => subtreeWeights[c]!.total)
      .toList();

  final weightCounts = <int, List<int>>{};
  for (var i = 0; i < children.length; i++) {
    weightCounts.putIfAbsent(childTotalWeights[i], () => []).add(children[i]);
  }

  int? unbalancedWeight;
  int? balancedWeight;
  int? unbalancedNode;

  for (final entry in weightCounts.entries) {
    if (entry.value.length == 1) {
      unbalancedWeight = entry.key;
      unbalancedNode = entry.value.first;
    } else {
      balancedWeight = entry.key;
    }
  }

  if (unbalancedNode != null && balancedWeight != null) {
    final (isChildBalanced, childResult) = findUnbalanced(
      graph,
      weights,
      unbalancedNode,
      subtreeWeights,
    );
    if (!isChildBalanced) {
      return (false, childResult);
    } else {
      final diff = balancedWeight - unbalancedWeight!;
      final correctWeight = weights[unbalancedNode]! + diff;
      return (false, correctWeight);
    }
  }

  return (true, 0);
}
