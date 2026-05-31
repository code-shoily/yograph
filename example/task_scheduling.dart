/// Task scheduling with topological sort.
///
/// Determines a valid execution order for build tasks with
/// dependencies. Run with:
///   dart run example/task_scheduling.dart
library;

import 'package:yograph/yograph.dart';

void main() {
  // Task IDs
  const compileUtils = 0;
  const compileCore = 1;
  const compileUi = 2;
  const compileTests = 3;
  const runTests = 4;
  const buildDocs = 5;
  const deploy = 6;

  final names = [
    'compile-utils',
    'compile-core',
    'compile-ui',
    'compile-tests',
    'run-tests',
    'build-docs',
    'deploy',
  ];

  // Directed dependency graph: edge A → B means "A must complete before B"
  final graph = SimpleGraph<String, void>.directed();
  for (var i = 0; i < names.length; i++) {
    graph.addNode(i, data: names[i]);
  }
  graph.addEdgesFrom([
    (compileUtils, compileCore),
    (compileUtils, compileUi),
    (compileCore, compileTests),
    (compileCore, buildDocs),
    (compileUi, compileTests),
    (compileTests, runTests),
    (runTests, deploy),
    (buildDocs, deploy),
  ]);

  // Basic topological sort
  final order = topologicalSort(graph);
  if (order == null) {
    print('Error: dependency cycle detected!');
    return;
  }

  print('Build order (topological sort):');
  print('');
  for (var i = 0; i < order.length; i++) {
    print('  ${i + 1}. ${names[order[i]]}');
  }

  // Lexicographical topological sort (deterministic ordering)
  print('');
  print('Alphabetical build order:');
  print('');

  final lexOrder = lexicographicalTopologicalSort(
    graph,
    (a, b) => a.compareTo(b),
  );

  for (var i = 0; i < lexOrder!.length; i++) {
    print('  ${i + 1}. ${names[lexOrder[i]]}');
  }

  // Check if the graph is a DAG
  print('');
  print('Is DAG: ${Structure.isArborescence(graph) || order.isNotEmpty}');
}
