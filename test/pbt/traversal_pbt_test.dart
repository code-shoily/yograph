import 'package:glados/glados.dart';
import 'package:yograph/yograph.dart';

SimpleGraph<void, void> _buildGraph(List<List<int>> edges, bool directed) {
  final graph = directed
      ? SimpleGraph<void, void>.directed()
      : SimpleGraph<void, void>.undirected();

  for (final edge in edges) {
    if (edge.length >= 2) {
      graph.addEdge(edge[0], edge[1]);
    }
  }
  return graph;
}

SimpleGraph<void, void> _buildDag(List<List<int>> edges) {
  final graph = SimpleGraph<void, void>.directed();
  for (final edge in edges) {
    if (edge.length >= 2) {
      final u = edge[0];
      final v = edge[1];
      if (u < v) {
        graph.addEdge(u, v);
      } else if (u > v) {
        graph.addEdge(v, u);
      }
    }
  }
  return graph;
}

void main() {
  Glados2<List<List<int>>, bool>(any.list(any.list(any.int)), any.bool).test(
    'BFS visits each reachable node exactly once',
    (edges, directed) {
      final graph = _buildGraph(edges, directed);
      if (graph.isEmpty) return;

      final startNode = graph.nodeIds.first;
      final visited = walk(graph, from: startNode, order: Order.breadthFirst);

      expect(visited.length, equals(visited.toSet().length));
    },
  );

  Glados2<List<List<int>>, bool>(any.list(any.list(any.int)), any.bool).test(
    'DFS-BFS Node Agreement: DFS and BFS visit the same set of reachable nodes',
    (edges, directed) {
      final graph = _buildGraph(edges, directed);
      if (graph.isEmpty) return;

      final startNode = graph.nodeIds.first;
      final bfsVisited = walk(
        graph,
        from: startNode,
        order: Order.breadthFirst,
      ).toSet();
      final dfsVisited = walk(
        graph,
        from: startNode,
        order: Order.depthFirst,
      ).toSet();

      expect(bfsVisited, equals(dfsVisited));
    },
  );

  Glados<List<List<int>>>(any.list(any.list(any.int))).test(
    'Topological Order: u appears before v in topological sort of DAG',
    (edges) {
      final graph = _buildDag(edges);
      if (graph.isEmpty) return;

      final order = topologicalSort(graph);
      expect(order, isNotNull);

      final position = <int, int>{
        for (var i = 0; i < order!.length; i++) order[i]: i,
      };

      for (final u in graph.nodeIds) {
        for (final v in graph.successors(u)) {
          expect(position[u]!, lessThan(position[v]!));
        }
      }
    },
  );
}
