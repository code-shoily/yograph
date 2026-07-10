import 'dart:math' as math;
import 'package:glados/glados.dart';
import 'package:yograph/yograph.dart';

SimpleGraph<void, double> _buildUndirectedWeightedGraph(List<List<int>> edges) {
  final graph = SimpleGraph<void, double>.undirected();
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

void main() {
  Glados<List<List<int>>>(any.list(any.list(any.int))).test(
    'Kruskal and Prim agree on total weight for connected undirected subgraphs',
    (rawEdges) {
      final graph = _buildUndirectedWeightedGraph(rawEdges);
      if (graph.isEmpty) return;

      final components = Components.connectedComponents(graph);
      for (final component in components) {
        if (component.length > 1) {
          // Construct the induced subgraph for this component
          final sub = SimpleGraph<void, double>.undirected();
          for (final u in component) {
            sub.addNode(u, data: graph.nodeData(u));
          }
          for (final u in component) {
            for (final v in graph.successors(u)) {
              if (component.contains(v) && u < v) {
                sub.addEdge(u, v, data: graph.edgeWeight(u, v));
              }
            }
          }

          final kruskalResult = MST.kruskal(sub);
          final primResult = MST.prim(sub, from: component.first);

          expect(
            kruskalResult.totalWeight,
            closeTo(primResult.totalWeight, 1e-9),
          );
        }
      }
    },
  );

  Glados<List<List<int>>>(any.list(any.list(any.int))).test(
    'MST edge count equals V - c for c connected components',
    (rawEdges) {
      final graph = _buildUndirectedWeightedGraph(rawEdges);
      if (graph.isEmpty) return;

      final result = MST.kruskal(graph);
      final components = Components.connectedComponents(graph);
      final numComponents = components.length;
      final numNodes = graph.nodeCount;

      final expectedEdges = math.max(0, numNodes - numComponents);
      expect(result.edgeCount, equals(expectedEdges));
    },
  );

  Glados<List<List<int>>>(any.list(any.list(any.int))).test(
    'MST is cycle-free (contains no cycles)',
    (rawEdges) {
      final graph = _buildUndirectedWeightedGraph(rawEdges);
      if (graph.isEmpty) return;

      final result = MST.kruskal(graph);
      final dsu = DisjointSet<int>();
      var hasCycle = false;

      for (final edge in result.edges) {
        if (dsu.connected(edge.from, edge.to)) {
          hasCycle = true;
          break;
        }
        dsu.union(edge.from, edge.to);
      }

      expect(hasCycle, isFalse);
    },
  );

  Glados<List<List<int>>>(any.list(any.list(any.int))).test(
    'MST total weight is non-negative',
    (rawEdges) {
      final graph = _buildUndirectedWeightedGraph(rawEdges);
      if (graph.isEmpty) return;

      final result = MST.kruskal(graph);
      expect(result.totalWeight, greaterThanOrEqualTo(0.0));
    },
  );

  Glados<List<List<int>>>(any.list(any.list(any.int))).test(
    'MST weight agrees with brute force on small graphs',
    (rawEdges) {
      final graph = _buildUndirectedWeightedGraph(rawEdges);
      final edges = <(int, int, double)>[];
      for (final u in graph.nodeIds) {
        for (final v in graph.successors(u)) {
          if (u < v) {
            edges.add((u, v, graph.edgeWeight(u, v)));
          }
        }
      }
      if (edges.length > 12 || graph.isEmpty) return;

      final kruskalResult = MST.kruskal(graph);
      final expectedWeight = _bruteForceMSTWeight(graph);

      expect(kruskalResult.totalWeight, closeTo(expectedWeight, 1e-9));
    },
  );
}

double _bruteForceMSTWeight(SimpleGraph<void, double> graph) {
  final edges = <(int, int, double)>[];
  for (final u in graph.nodeIds) {
    for (final v in graph.successors(u)) {
      if (u < v) {
        edges.add((u, v, graph.edgeWeight(u, v)));
      }
    }
  }
  final V = graph.nodeCount;
  if (V == 0) return 0.0;
  final components = Components.connectedComponents(graph);
  final C = components.length;
  final targetEdgeCount = V - C;
  if (targetEdgeCount <= 0) return 0.0;

  var minWeight = double.infinity;
  final numSubsets = 1 << edges.length;
  for (var mask = 0; mask < numSubsets; mask++) {
    var bitCount = 0;
    for (var i = 0; i < edges.length; i++) {
      if ((mask & (1 << i)) != 0) bitCount++;
    }
    if (bitCount != targetEdgeCount) continue;

    final dsu = DisjointSet<int>();
    var hasCycle = false;
    var weightSum = 0.0;
    for (var i = 0; i < edges.length; i++) {
      if ((mask & (1 << i)) != 0) {
        final (u, v, w) = edges[i];
        if (dsu.connected(u, v)) {
          hasCycle = true;
          break;
        }
        dsu.union(u, v);
        weightSum += w;
      }
    }
    if (!hasCycle) {
      if (weightSum < minWeight) {
        minWeight = weightSum;
      }
    }
  }
  return minWeight;
}
