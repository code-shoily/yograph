/// Social network analysis — centrality & community detection.
///
/// Analyses a small social network to find the most influential
/// person and detect communities. Run with:
///   dart run example/social_network_analysis.dart
library;

import 'package:yograph/yograph.dart';

void main() {
  final names = ['Alice', 'Bob', 'Carol', 'Dave', 'Eve', 'Frank', 'Grace'];

  // Undirected friendship graph
  final graph = SimpleGraph<String, void>.undirected()
    // Community 1: Alice, Bob, Carol, Dave
    ..addEdge(0, 1)
    ..addEdge(0, 2)
    ..addEdge(1, 2)
    ..addEdge(1, 3)
    ..addEdge(2, 3)
    // Community 2: Eve, Frank, Grace
    ..addEdge(4, 5)
    ..addEdge(4, 6)
    ..addEdge(5, 6)
    // Bridge between communities
    ..addEdge(3, 4);

  // ── Centrality ──
  print('=== Centrality Analysis ===');
  print('');

  final betweenness = Centrality.betweenness(graph);
  final degree = Centrality.degree(graph);

  for (var i = 0; i < names.length; i++) {
    print(
      '${names[i].padRight(6)}  '
      'degree: ${degree[i]!.toStringAsFixed(2)}  '
      'betweenness: ${betweenness[i]!.toStringAsFixed(2)}',
    );
  }

  // Find the most influential (highest betweenness)
  final maxBetweenness = betweenness.entries
      .reduce((a, b) => a.value > b.value ? a : b);
  print('');
  print(
    'Most influential: ${names[maxBetweenness.key]} '
    '(betweenness = ${maxBetweenness.value.toStringAsFixed(2)})',
  );

  // ── Community Detection (Connected Components) ──
  print('');
  print('=== Communities ===');
  print('');

  final components = Components.connectedComponents(graph);
  for (var i = 0; i < components.length; i++) {
    final members = components[i].map((id) => names[id]).join(', ');
    print('Community ${i + 1}: $members');
  }

  // ── Structural Health ──
  print('');
  print('=== Network Health ===');
  print('');
  print('Diameter: ${Health.diameter(graph)?.toStringAsFixed(1)}');
  print('Radius:   ${Health.radius(graph)?.toStringAsFixed(1)}');
  print('APL:      ${Health.averagePathLength(graph)?.toStringAsFixed(2)}');
  print(
    'Assortativity: ${Health.assortativity(graph).toStringAsFixed(3)}',
  );

  // ── Bridges ──
  print('');
  print('=== Bridges ===');
  print('');

  final analysis = Analysis.analyze(graph);
  if (analysis.bridges.isEmpty) {
    print('No bridges found.');
  } else {
    for (final (u, v) in analysis.bridges) {
      print('Bridge: ${names[u]} ↔ ${names[v]}');
    }
  }
}
