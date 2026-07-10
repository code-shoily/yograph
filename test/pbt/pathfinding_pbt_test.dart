import 'package:glados/glados.dart';
import 'package:yograph/yograph.dart';

SimpleGraph<void, double> _buildWeightedGraph(
  List<List<int>> edges,
  bool directed,
) {
  final graph = directed
      ? SimpleGraph<void, double>.directed()
      : SimpleGraph<void, double>.undirected();

  for (final edge in edges) {
    if (edge.length >= 3) {
      final u = edge[0];
      final v = edge[1];
      final w = edge[2].abs().toDouble(); // non-negative weights
      graph.addEdge(u, v, data: w);
    }
  }
  return graph;
}

class PathfindingInput {
  final List<List<int>> edges;
  final bool directed;
  final int fromIdx;
  final int toIdx;

  PathfindingInput(this.edges, this.directed, this.fromIdx, this.toIdx);

  factory PathfindingInput.fromList(List<List<int>> list) {
    if (list.length < 2) {
      return PathfindingInput([], false, 0, 0);
    }
    final directed = list[0].isNotEmpty && list[0][0] != 0;
    final fromIdx = list[1].isNotEmpty ? list[1][0] : 0;
    final toIdx = (list[1].length >= 2) ? list[1][1] : 0;
    final edges = list.sublist(2);
    return PathfindingInput(edges, directed, fromIdx, toIdx);
  }
}

void main() {
  Glados<List<List<int>>>(any.list(any.list(any.int))).test(
    'Pathfinding Algorithm Consistency: Dijkstra, Bellman-Ford, and A* agree on path weight',
    (rawInput) {
      final input = PathfindingInput.fromList(rawInput);
      final graph = _buildWeightedGraph(input.edges, input.directed);
      if (graph.isEmpty) return;

      final nodes = graph.nodeIds.toList();
      final from = nodes[input.fromIdx.abs() % nodes.length];
      final to = nodes[input.toIdx.abs() % nodes.length];

      final pDijkstra = Pathfinding.shortestPath(
        graph,
        from,
        to,
        strategy: const Dijkstra(),
      );
      final pAStar = Pathfinding.shortestPath(
        graph,
        from,
        to,
        strategy: AStar(heuristic: (_, _) => 0.0),
      );
      final pBellmanFord = Pathfinding.shortestPath(
        graph,
        from,
        to,
        strategy: const BellmanFord(),
      );

      if (pDijkstra == null) {
        expect(pAStar, isNull);
        expect(pBellmanFord, isNull);
      } else {
        expect(pAStar, isNotNull);
        expect(pBellmanFord, isNotNull);
        expect(pAStar!.weight, closeTo(pDijkstra.weight, 1e-9));
        expect(pBellmanFord!.weight, closeTo(pDijkstra.weight, 1e-9));
      }
    },
  );

  Glados<List<List<int>>>(any.list(any.list(any.int))).test(
    'Bidirectional Dijkstra Correctness: yields same path weight as standard Dijkstra',
    (rawInput) {
      final input = PathfindingInput.fromList(rawInput);
      final graph = _buildWeightedGraph(input.edges, input.directed);
      if (graph.isEmpty) return;

      final nodes = graph.nodeIds.toList();
      final from = nodes[input.fromIdx.abs() % nodes.length];
      final to = nodes[input.toIdx.abs() % nodes.length];

      final pDijkstra = Pathfinding.shortestPath(
        graph,
        from,
        to,
        strategy: const Dijkstra(),
      );
      final pBiDijkstra = Pathfinding.shortestPath(
        graph,
        from,
        to,
        strategy: const BidirectionalDijkstra(),
      );

      if (pDijkstra == null) {
        expect(pBiDijkstra, isNull);
      } else {
        expect(pBiDijkstra, isNotNull);
        expect(pBiDijkstra!.weight, closeTo(pDijkstra.weight, 1e-9));
      }
    },
  );

  Glados<List<List<int>>>(any.list(any.list(any.int))).test(
    'Floyd-Warshall Agreement: agrees with repeated Dijkstra runs',
    (rawInput) {
      final input = PathfindingInput.fromList(rawInput);
      final graph = _buildWeightedGraph(input.edges, input.directed);
      if (graph.isEmpty) return;

      final fwResult = FloydWarshall.allPairs(graph);
      expect(
        fwResult.hasNegativeCycle,
        isFalse,
      ); // non-negative weights can't produce negative cycle

      final nodes = graph.nodeIds.toList();
      // Verify for a subset of node pairs to keep test execution fast
      final sampleSize = nodes.length > 10 ? 10 : nodes.length;
      for (var i = 0; i < sampleSize; i++) {
        final from = nodes[i];
        for (var j = 0; j < sampleSize; j++) {
          final to = nodes[j];
          final fwDist = fwResult.distance(from, to);
          final pDijkstra = Pathfinding.shortestPath(
            graph,
            from,
            to,
            strategy: const Dijkstra(),
          );

          if (pDijkstra == null) {
            expect(fwDist, isNull);
          } else {
            expect(fwDist, isNotNull);
            expect(fwDist, closeTo(pDijkstra.weight, 1e-9));
          }
        }
      }
    },
  );

  Glados<List<List<int>>>(any.list(any.list(any.int))).test(
    'Shortest Path algorithms agree with brute force on small graphs',
    (rawInput) {
      final input = PathfindingInput.fromList(rawInput);
      final graph = _buildWeightedGraph(input.edges, input.directed);
      if (graph.isEmpty) return;

      final nodes = graph.nodeIds.toList();
      if (nodes.length > 8 || graph.edgeCount > 12) return;

      final from = nodes[input.fromIdx.abs() % nodes.length];
      final to = nodes[input.toIdx.abs() % nodes.length];

      final pDijkstra = Pathfinding.shortestPath(
        graph,
        from,
        to,
        strategy: const Dijkstra(),
      );
      final pAStar = Pathfinding.shortestPath(
        graph,
        from,
        to,
        strategy: AStar(heuristic: (_, _) => 0.0),
      );
      final pBiDijkstra = Pathfinding.shortestPath(
        graph,
        from,
        to,
        strategy: const BidirectionalDijkstra(),
      );

      final expectedPath = _bruteForceShortestPath(graph, from, to);

      if (expectedPath == null) {
        expect(pDijkstra, isNull);
        expect(pAStar, isNull);
        expect(pBiDijkstra, isNull);
      } else {
        expect(pDijkstra, isNotNull);
        expect(pAStar, isNotNull);
        expect(pBiDijkstra, isNotNull);
        expect(pDijkstra!.weight, closeTo(expectedPath.weight, 1e-9));
        expect(pAStar!.weight, closeTo(expectedPath.weight, 1e-9));
        expect(pBiDijkstra!.weight, closeTo(expectedPath.weight, 1e-9));
      }
    },
  );

  Glados<List<List<int>>>(any.list(any.list(any.int))).test(
    'Yen k-shortest paths agrees with brute force on small graphs',
    (rawInput) {
      final input = PathfindingInput.fromList(rawInput);
      final graph = _buildWeightedGraph(input.edges, input.directed);
      if (graph.isEmpty) return;

      final nodes = graph.nodeIds.toList();
      if (nodes.length > 8 || graph.edgeCount > 12) return;

      final from = nodes[input.fromIdx.abs() % nodes.length];
      final to = nodes[input.toIdx.abs() % nodes.length];

      final k = 3;
      final yenPaths = Yen.kShortestPaths(graph, from, to, k);
      final expectedPaths = _bruteForceKShortestPaths(graph, from, to, k);

      expect(yenPaths.length, equals(expectedPaths.length));
      for (var i = 0; i < yenPaths.length; i++) {
        expect(yenPaths[i].weight, closeTo(expectedPaths[i].weight, 1e-9));
        expect(yenPaths[i].nodes, equals(expectedPaths[i].nodes));
      }
    },
  );
}

Path<double>? _bruteForceShortestPath(
  WeightedWalkable<void, double> graph,
  int from,
  int to,
) {
  if (!graph.hasNode(from) || !graph.hasNode(to)) return null;
  if (from == to) return Path([from], 0.0);

  var minWeight = double.infinity;
  List<int>? bestPath;

  void dfs(int current, List<int> path, double weight) {
    if (current == to) {
      if (weight < minWeight) {
        minWeight = weight;
        bestPath = List.from(path);
      }
      return;
    }

    for (final succ in graph.successors(current)) {
      if (!path.contains(succ)) {
        final edgeW = graph.edgeWeight(current, succ);
        dfs(succ, [...path, succ], weight + edgeW);
      }
    }
  }

  dfs(from, [from], 0.0);

  if (bestPath == null) return null;
  return Path(bestPath!, minWeight);
}

List<Path<double>> _bruteForceKShortestPaths(
  WeightedWalkable<void, double> graph,
  int from,
  int to,
  int k,
) {
  if (!graph.hasNode(from) || !graph.hasNode(to) || k <= 0) return [];
  if (from == to) {
    return [
      Path([from], 0.0),
    ];
  }

  final allPaths = <Path<double>>[];

  void dfs(int current, List<int> path, double weight) {
    if (current == to) {
      allPaths.add(Path(List.from(path), weight));
      return;
    }

    for (final succ in graph.successors(current)) {
      if (!path.contains(succ)) {
        final edgeW = graph.edgeWeight(current, succ);
        dfs(succ, [...path, succ], weight + edgeW);
      }
    }
  }

  dfs(from, [from], 0.0);

  allPaths.sort((a, b) {
    final cmp = a.weight.compareTo(b.weight);
    if (cmp != 0) return cmp;
    return a.nodes.join(',').compareTo(b.nodes.join(','));
  });

  return allPaths.take(k).toList();
}
