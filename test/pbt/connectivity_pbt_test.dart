import 'package:glados/glados.dart';
import 'package:yograph/yograph.dart';

SimpleGraph<void, void> _buildDirectedGraph(List<List<int>> edges) {
  final graph = SimpleGraph<void, void>.directed();
  for (final edge in edges) {
    if (edge.length >= 2) {
      final u = edge[0];
      final v = edge[1];
      graph.addEdge(u, v);
    }
  }
  return graph;
}

List<List<int>> _normalizeSCCs(List<List<int>> sccs) {
  final sortedComponents = sccs.map((c) => List<int>.from(c)..sort()).toList();
  sortedComponents.sort((a, b) {
    if (a.isEmpty && b.isEmpty) return 0;
    if (a.isEmpty) return -1;
    if (b.isEmpty) return 1;
    return a[0].compareTo(b[0]);
  });
  return sortedComponents;
}

void main() {
  Glados<List<List<int>>>(any.list(any.list(any.int))).test(
    'SCC: Tarjan and Kosaraju agree on strongly connected components',
    (rawEdges) {
      final graph = _buildDirectedGraph(rawEdges);
      if (graph.isEmpty) return;

      final sccsTarjan = SCC.tarjan(graph);
      final sccsKosaraju = SCC.kosaraju(graph);

      expect(_normalizeSCCs(sccsTarjan), equals(_normalizeSCCs(sccsKosaraju)));
    },
  );
}
