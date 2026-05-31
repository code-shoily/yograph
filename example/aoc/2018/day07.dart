import 'dart:math';
import 'package:yograph/yograph.dart';
import '../aoc_helper.dart';

const sampleInput = '''
Step C must be finished before step A can begin.
Step C must be finished before step F can begin.
Step A must be finished before step B can begin.
Step A must be finished before step D can begin.
Step B must be finished before step E can begin.
Step D must be finished before step E can begin.
Step F must be finished before step E can begin.
''';

void main() async {
  final (input, isSample) = await loadInput(
    year: 2018,
    day: 7,
    sampleInput: sampleInput,
  );
  final (p1, p2) = solve(input, isSample);
  print('($p1, $p2)');
}

(String, int) solve(String rawInput, bool isSample) {
  final graph = parse(rawInput);
  return (solvePart1(graph), solvePart2(graph, isSample));
}

SimpleGraph<String, Null> parse(String input) {
  final builder = LabeledBuilder<String, Null>.directed();
  final regex = RegExp(
    r'^Step (\w+) must be finished before step (\w+) can begin\.$',
  );
  for (final line in getLines(input)) {
    final match = regex.firstMatch(line);
    if (match != null) {
      final prereq = match.group(1)!;
      final step = match.group(2)!;
      builder.addEdge(prereq, step);
    }
  }
  return builder.toGraph() as SimpleGraph<String, Null>;
}

String solvePart1(SimpleGraph<String, Null> graph) {
  final order = lexicographicalTopologicalSort(graph, (a, b) => a.compareTo(b));
  return order!.map((id) => graph.nodeData(id)!).join('');
}

int solvePart2(SimpleGraph<String, Null> graph, bool isSample) {
  final baseTime = isSample ? 0 : 60;
  final maxWorkers = isSample ? 2 : 5;

  final inDegrees = <int, int>{
    for (final id in graph.nodeIds) id: graph.inDegree(id),
  };

  final available = <int>[];
  for (final entry in inDegrees.entries) {
    if (entry.value == 0) {
      available.add(entry.key);
    }
  }
  available.sort((a, b) => graph.nodeData(a)!.compareTo(graph.nodeData(b)!));

  final workers = <int, int>{};
  var time = 0;

  while (available.isNotEmpty || workers.isNotEmpty) {
    while (workers.length < maxWorkers && available.isNotEmpty) {
      final next = available.removeAt(0);
      final label = graph.nodeData(next)!;
      final duration = baseTime + label.codeUnitAt(0) - 'A'.codeUnitAt(0) + 1;
      workers[next] = duration;
    }

    final dt = workers.values.reduce(min);
    time += dt;

    final completed = <int>[];
    for (final node in workers.keys.toList()) {
      workers[node] = workers[node]! - dt;
      if (workers[node] == 0) {
        completed.add(node);
        workers.remove(node);
      }
    }

    final newlyAvailable = <int>[];
    for (final parent in completed) {
      for (final child in graph.successors(parent)) {
        final newDeg = inDegrees[child]! - 1;
        inDegrees[child] = newDeg;
        if (newDeg == 0) {
          newlyAvailable.add(child);
        }
      }
    }

    available.addAll(newlyAvailable);
    available.sort((a, b) => graph.nodeData(a)!.compareTo(graph.nodeData(b)!));
  }

  return time;
}
