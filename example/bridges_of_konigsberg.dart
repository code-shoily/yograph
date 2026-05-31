/// The Seven Bridges of Königsberg.
///
/// Euler's famous problem: can you walk through the city crossing each
/// bridge exactly once? Run with:
///   dart run example/bridges_of_konigsberg.dart
library;

import 'package:yograph/yograph.dart';

void main() {
  // Land masses: North bank, South bank, East island, West island
  const north = 0;
  const south = 1;
  const east = 2;
  const west = 3;

  final names = ['North Bank', 'South Bank', 'East Island', 'West Island'];

  // The famous 7 bridges (undirected)
  final graph = SimpleGraph<String, void>.fromEdges([
    // North ↔ East (2 bridges)
    (north, east),
    (north, east),
    // North ↔ West (1 bridge)
    (north, west),
    // South ↔ East (2 bridges)
    (south, east),
    (south, east),
    // South ↔ West (1 bridge)
    (south, west),
    // East ↔ West (1 bridge)
    (east, west),
  ], kind: GraphKind.undirected);

  print('The Seven Bridges of Königsberg');
  print('');

  // Count degrees
  print('Land mass degrees:');
  for (var i = 0; i < names.length; i++) {
    print(
      '  ${names[i].padRight(12)} — '
      '${graph.successors(i).length} bridges',
    );
  }

  // Euler's theorem: a connected undirected graph has an Eulerian trail
  // iff exactly 0 or 2 vertices have odd degree.
  var oddCount = 0;
  for (final node in graph.nodeIds) {
    if (graph.successors(node).length.isOdd) oddCount++;
  }

  print('');
  print('Vertices with odd degree: $oddCount');

  if (oddCount == 0 || oddCount == 2) {
    print('Result: An Eulerian trail EXISTS!');
  } else {
    print('Result: No Eulerian trail possible.');
  }

  // Find bridges (critical infrastructure)
  print('');
  print('Bridge analysis:');
  final analysis = Analysis.analyze(graph);
  if (analysis.bridges.isEmpty) {
    print('  No single-bridge bottlenecks.');
  } else {
    for (final (u, v) in analysis.bridges) {
      print('  ${names[u]} ↔ ${names[v]} is a bridge');
    }
  }

  // Articulation points
  if (analysis.articulationPoints.isNotEmpty) {
    print('');
    print('Articulation points:');
    for (final node in analysis.articulationPoints) {
      print('  ${names[node]}');
    }
  }
}
