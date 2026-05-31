/// Different ways to create graphs in Yograph.
///
/// Demonstrates the builder API, manual construction, and
/// the LabeledBuilder for ergonomic label-based graphs.
/// Run with:
///   dart run example/graph_creation.dart
library;

import 'package:yograph/yograph.dart';

void main() {
  // ── Method 1: Direct construction with integer IDs ──
  print('=== Method 1: Direct Construction ===');
  final graph1 = SimpleGraph<String, int>.directed()
    ..addEdge(0, 1, data: 5)
    ..addEdge(1, 2, data: 3)
    ..addEdge(0, 2, data: 10);

  print('Nodes: ${graph1.nodeIds.toList()}');
  print('Edge 0→1 weight: ${graph1.edgeWeight(0, 1)}');
  print('');

  // ── Method 2: LabeledBuilder with String labels ──
  print('=== Method 2: LabeledBuilder (String labels) ===');

  final builder = LabeledBuilder<String, int>.directed()
    ..addEdge('A', 'B', data: 5)
    ..addEdge('B', 'C', data: 3)
    ..addEdge('A', 'C', data: 10);

  final graph2 = builder.toGraph() as WeightedWalkable<String, int>;
  final idA = builder.getId('A')!;
  final idC = builder.getId('C')!;

  final path = Pathfinding.shortestPath(graph2, idA, idC);
  print('A → C shortest path: ${path?.nodes.map((id) {
    // reverse-lookup label by ID
    for (final label in builder.labels) {
      if (builder.getId(label) == id) return label;
    }
    return id.toString();
  }).join(' -> ')}');
  print('Weight: ${path?.weight}');
  print('');

  // ── Method 3: Undirected graph ──
  print('=== Method 3: Undirected Graph ===');

  final undirected = SimpleGraph<String, void>.undirected()
    ..addEdge(0, 1)
    ..addEdge(1, 2)
    ..addEdge(2, 0);

  print('Is complete: ${Structure.isComplete(undirected)}');
  print('Is regular:  ${Structure.isRegular(undirected, 2)}');
  print('Is chordal:  ${Structure.isChordal(undirected)}');
  print('');

  // ── Method 4: Using .on() to wrap an existing graph ──
  print('=== Method 4: Builder on Existing Graph ===');

  final baseGraph = SimpleGraph<String, int>.directed();
  final wrapped = LabeledBuilder<String, int>.on(baseGraph)
    ..addEdge('X', 'Y', data: 7)
    ..addEdge('Y', 'Z', data: 4);

  // The underlying graph is shared
  print('Underlying graph edge count: ${baseGraph.edgeCount}');
  print('Wrapped labels: ${wrapped.labels.toList()}');
  print('');

  // ── Method 5: Auto-creating nodes via addEdge ──
  print('=== Method 5: Auto-creating Nodes ===');

  final autoGraph = SimpleGraph<String, void>.directed()
    // Node 42 doesn't exist yet — addEdge creates it automatically
    ..addEdge(42, 99)
    ..addEdge(99, 42);

  print('Nodes: ${autoGraph.nodeIds.toList()}');
  print('Has node 42: ${autoGraph.hasNode(42)}');
  print('Has node 99: ${autoGraph.hasNode(99)}');
}
