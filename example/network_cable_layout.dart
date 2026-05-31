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

  final labels = [
    'Hub',
    'Office A',
    'Office B',
    'Office C',
    'Office D',
    'Warehouse',
  ];

  // Undirected graph: edge weight = cost in thousands of dollars
  final graph = SimpleGraph<String, int>.fromEdgesWithData([
    (hub, officeA, 7),
    (hub, officeB, 9),
    (hub, officeC, 14),
    (officeA, officeB, 10),
    (officeA, officeD, 15),
    (officeB, officeC, 2),
    (officeB, officeD, 11),
    (officeC, officeD, 6),
    (officeC, warehouse, 9),
    (officeD, warehouse, 9),
  ], kind: GraphKind.undirected);

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
  print(
    'Prim agrees — total cost: \$${primMst.totalWeight.toStringAsFixed(1)}k',
  );
}
