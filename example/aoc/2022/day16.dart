import 'dart:math';
import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
Valve AA has flow rate=0; tunnels lead to valves DD, II, BB
Valve BB has flow rate=13; tunnels lead to valves CC, AA
Valve CC has flow rate=2; tunnels lead to valves DD, BB
Valve DD has flow rate=20; tunnels lead to valves CC, AA, EE
Valve EE has flow rate=3; tunnels lead to valves FF, DD
Valve FF has flow rate=0; tunnels lead to valves EE, GG
Valve GG has flow rate=0; tunnels lead to valves FF, HH
Valve HH has flow rate=22; tunnel leads to valve GG
Valve II has flow rate=0; tunnels lead to valves AA, JJ
Valve JJ has flow rate=21; tunnel leads to valve II
''';

class Valve {
  final String id;
  final int flow;
  final List<String> tunnels;

  Valve(this.id, this.flow, this.tunnels);
}

void main() async {
  final (input, isSample) = await loadInput(
    year: 2022,
    day: 16,
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
  final valves = parse(lines);

  final builder = LabeledBuilder<String, double>.directed();
  final flowMap = <int, int>{};

  for (final valve in valves) {
    final id = builder.ensureNode(valve.id);
    flowMap[id] = valve.flow;
  }

  for (final valve in valves) {
    for (final tunnel in valve.tunnels) {
      builder.addEdge(valve.id, tunnel, data: 1.0);
    }
  }

  final graph = builder.toGraph() as SimpleGraph<String, double>;
  final dists = FloydWarshall.allPairs(graph);

  final aaId = builder.getId('AA')!;

  final relevantValves = valves
      .where((v) => v.flow > 0)
      .map((v) => builder.getId(v.id)!)
      .toList();

  final indices = <int, int>{};
  for (var i = 0; i < relevantValves.length; i++) {
    indices[relevantValves[i]] = i;
  }

  // Part 1
  final memo1 = <int, int>{};
  _dfs(aaId, 30, 0, 0, relevantValves, dists, indices, flowMap, memo1);
  final p1 = memo1.values.reduce(max);

  // Part 2
  final memo2 = <int, int>{};
  _dfs(aaId, 26, 0, 0, relevantValves, dists, indices, flowMap, memo2);

  var p2 = 0;
  final maskEntries = memo2.entries.toList();
  for (var i = 0; i < maskEntries.length; i++) {
    final entry1 = maskEntries[i];
    for (var j = i + 1; j < maskEntries.length; j++) {
      final entry2 = maskEntries[j];
      if ((entry1.key & entry2.key) == 0) {
        final totalFlow = entry1.value + entry2.value;
        if (totalFlow > p2) {
          p2 = totalFlow;
        }
      }
    }
  }

  return (p1, p2);
}

List<Valve> parse(List<String> lines) {
  final regex = RegExp(
    r'^Valve ([A-Z]{2}) has flow rate=(\d+); tunnels? leads? to valves? (.*)$',
  );
  final result = <Valve>[];

  for (final line in lines) {
    final clean = line.trim();
    if (clean.isEmpty) continue;

    final match = regex.firstMatch(clean);
    if (match != null) {
      final id = match.group(1)!;
      final flow = int.parse(match.group(2)!);
      final tunnels = match.group(3)!.split(',').map((s) => s.trim()).toList();
      result.add(Valve(id, flow, tunnels));
    }
  }
  return result;
}

void _dfs(
  int curr,
  int time,
  int mask,
  int flow,
  List<int> relevant,
  FloydWarshallResult dists,
  Map<int, int> indices,
  Map<int, int> flows,
  Map<int, int> memo,
) {
  final currentFlow = memo[mask];
  if (currentFlow == null || currentFlow < flow) {
    memo[mask] = flow;
  }

  for (final next in relevant) {
    final idx = indices[next]!;
    if ((mask & (1 << idx)) == 0) {
      final dist = dists.distance(curr, next)!.toInt();
      final remTime = time - dist - 1;
      if (remTime > 0) {
        _dfs(
          next,
          remTime,
          mask | (1 << idx),
          flow + remTime * flows[next]!,
          relevant,
          dists,
          indices,
          flows,
          memo,
        );
      }
    }
  }
}
