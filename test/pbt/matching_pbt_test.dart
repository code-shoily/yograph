import 'package:glados/glados.dart';
import 'package:yograph/yograph.dart';

SimpleGraph<void, double> _buildUndirectedGraph(List<List<int>> edges) {
  final graph = SimpleGraph<void, double>.undirected();
  for (final edge in edges) {
    if (edge.length >= 2) {
      final u = edge[0];
      final v = edge[1];
      graph.addEdge(u, v);
    }
  }
  return graph;
}

int bruteForceMaxMatching(SimpleGraph<dynamic, dynamic> graph) {
  final edges = <(int, int)>[];
  for (final u in graph.nodeIds) {
    for (final v in graph.successors(u)) {
      if (u < v) {
        edges.add((u, v));
      }
    }
  }

  var maxMatching = 0;
  final numSubsets = 1 << edges.length;
  for (var mask = 0; mask < numSubsets; mask++) {
    final used = <int>{};
    var isValid = true;
    var count = 0;
    for (var i = 0; i < edges.length; i++) {
      if ((mask & (1 << i)) != 0) {
        final (u, v) = edges[i];
        if (used.contains(u) || used.contains(v)) {
          isValid = false;
          break;
        }
        used.add(u);
        used.add(v);
        count++;
      }
    }
    if (isValid && count > maxMatching) {
      maxMatching = count;
    }
  }
  return maxMatching;
}

void main() {
  Glados<List<List<int>>>(any.list(any.list(any.int))).test(
    'Maximum Matching agrees with brute force on small graphs',
    (rawEdges) {
      final graph = _buildUndirectedGraph(rawEdges);
      // Keep it small for brute force
      final edges = <(int, int)>[];
      for (final u in graph.nodeIds) {
        for (final v in graph.successors(u)) {
          if (u < v) {
            edges.add((u, v));
          }
        }
      }
      if (edges.length > 12 || graph.isEmpty) return;

      final expectedSize = bruteForceMaxMatching(graph);

      // Test Blossom algorithm
      final blossomMatching = Matching.blossomMaximumMatching(graph);
      final blossomSize = blossomMatching.length ~/ 2;
      expect(blossomSize, equals(expectedSize));

      // Test Hopcroft-Karp algorithm if bipartite
      final partition = Bipartite.partition(graph);
      if (partition != null) {
        final hkMatching = Matching.hopcroftKarp(graph);
        final hkSize = hkMatching.length ~/ 2;
        expect(hkSize, equals(expectedSize));
      }
    },
  );
}
