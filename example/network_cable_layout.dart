/// Minimum spanning tree for network cable layout.
///
/// A telecom company wants to lay fibre-optic cable between buildings
/// at minimum cost. Run with:
///   dart run example/network_cable_layout.dart
library;

import 'package:yograph/yograph.dart';

void main() {
  // Building IDs
  const hub = 0;
  const officeA = 1;
  const officeB = 2;
  const officeC = 3;
  const officeD = 4;
  const warehouse = 5;

  final labels = ['Hub', 'Office A', 'Office B', 'Office C', 'Office D', 'Warehouse'];

  // Undirected graph: edge weight = cost in thousands of dollars
  final graph = SimpleGraph<String, int>.undirected()
    ..addEdge(hub, officeA, data: 7)
    ..addEdge(hub, officeB, data: 9)
    ..addEdge(hub, officeC, data: 14)
    ..addEdge(officeA, officeB, data: 10)
    ..addEdge(officeA, officeD, data: 15)
    ..addEdge(officeB, officeC, data: 2)
    ..addEdge(officeB, officeD, data: 11)
    ..addEdge(officeC, officeD, data: 6)
    ..addEdge(officeC, warehouse, data: 9)
    ..addEdge(officeD, warehouse, data: 9);

  // Kruskal's MST
  final mst = MST.kruskal(graph);

  print('Minimum-cost cable layout (Kruskal):');
  print('Total cost: \$${mst.totalWeight.toStringAsFixed(1)}k');
  print('');
  print('Cables to install:');
  for (final edge in mst.edges) {
    print(
      '  ${labels[edge.from]} ↔ ${labels[edge.to]}  '
      '(\$${edge.weight.toStringAsFixed(1)}k)',
    );
  }

  // Compare with Prim
  final primMst = MST.prim(graph);
  print('');
  print('Prim agrees — total cost: \$${primMst.totalWeight.toStringAsFixed(1)}k');
}
