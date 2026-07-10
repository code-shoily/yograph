import 'package:yograph/yograph.dart';

void main() {
  final graph = SimpleGraph<String, int>.directed()
    ..addEdge(0, 1, data: 4)
    ..addEdge(0, 2, data: 1)
    ..addEdge(2, 1, data: 2)
    ..addEdge(1, 3, data: 1)
    ..addEdge(2, 3, data: 5);

  final path = Pathfinding.shortestPath(graph, 0, 3);
  print('Shortest path from 0 to 3: ${path?.nodes}');
  print('Total weight: ${path?.weight}');

  final order = walk(graph, from: 0, order: Order.breadthFirst);
  print('BFS order from 0: $order');

  final undirected = SimpleGraph<void, int>.undirected()
    ..addEdge(0, 1, data: 2)
    ..addEdge(1, 2, data: 3)
    ..addEdge(0, 2, data: 1);

  final mst = MST.kruskal(undirected);
  print('MST total weight: ${mst.totalWeight}');
}
