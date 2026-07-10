import 'package:glados/glados.dart';
import 'package:yograph/yograph.dart';

SimpleGraph<String, double> _buildGraph(List<List<int>> edges, bool directed) {
  final builder = directed
      ? LabeledBuilder<String, double>.directed()
      : LabeledBuilder<String, double>.undirected();

  for (final edge in edges) {
    if (edge.length >= 3) {
      // Map node integer ID to a clean string label: e.g. "N$id"
      final u = 'N${edge[0].abs()}';
      final v = 'N${edge[1].abs()}';
      final w =
          (edge[2].abs() % 100).toDouble() / 10.0 +
          0.1; // positive non-zero weight
      builder.addEdge(u, v, data: w);
    } else if (edge.length == 1) {
      builder.ensureNode('N${edge[0].abs()}');
    }
  }
  return builder.toGraph() as SimpleGraph<String, double>;
}

void _assertGraphsEqual(
  SimpleGraph<String, double> g1,
  SimpleGraph<String, double> g2,
) {
  expect(g2.nodeCount, equals(g1.nodeCount));

  final labelToId1 = <String, int>{};
  for (final u in g1.nodeIds) {
    final label = g1.nodeData(u);
    if (label != null) {
      labelToId1[label] = u;
    }
  }

  final labelToId2 = <String, int>{};
  for (final u in g2.nodeIds) {
    final label = g2.nodeData(u);
    if (label != null) {
      labelToId2[label] = u;
    }
  }

  expect(labelToId2.keys.toSet(), equals(labelToId1.keys.toSet()));

  for (final label in labelToId1.keys) {
    final u1 = labelToId1[label]!;
    final u2 = labelToId2[label]!;

    final successors1 = g1.successors(u1).map((v) => g1.nodeData(v)!).toSet();
    final successors2 = g2.successors(u2).map((v) => g2.nodeData(v)!).toSet();
    expect(successors2, equals(successors1));

    for (final succLabel in successors1) {
      final v1 = labelToId1[succLabel]!;
      final v2 = labelToId2[succLabel]!;
      expect(g2.edgeWeight(u2, v2), closeTo(g1.edgeWeight(u1, v1), 1e-9));
    }
  }
}

void main() {
  Glados<List<List<int>>>(any.list(any.list(any.int))).test(
    'GraphIO round-trip for edgelist and csv (no isolated nodes)',
    (rawEdges) {
      for (final directed in [true, false]) {
        // Build a graph containing ONLY edges (no isolated nodes)
        final builder = directed
            ? LabeledBuilder<String, double>.directed()
            : LabeledBuilder<String, double>.undirected();

        for (final edge in rawEdges) {
          if (edge.length >= 3) {
            final u = 'N${edge[0].abs()}';
            final v = 'N${edge[1].abs()}';
            final w = (edge[2].abs() % 100).toDouble() / 10.0 + 0.1;
            builder.addEdge(u, v, data: w);
          }
        }

        final graph = builder.toGraph() as SimpleGraph<String, double>;
        if (graph.isEmpty) continue;

        for (final format in ['edgelist', 'csv']) {
          final serialized = GraphIO.write(graph, format);
          final deserialized = GraphIO.read(
            serialized,
            format,
            directed: directed,
          );
          _assertGraphsEqual(graph, deserialized);
        }
      }
    },
  );

  Glados<List<List<int>>>(any.list(any.list(any.int))).test(
    'GraphIO round-trip for adjlist and tgf (supports isolated nodes)',
    (rawEdges) {
      for (final directed in [true, false]) {
        // Build a graph that can contain isolated nodes
        final graph = _buildGraph(rawEdges, directed);
        if (graph.isEmpty) continue;

        for (final format in ['adjlist', 'tgf']) {
          final serialized = GraphIO.write(graph, format);
          final deserialized = GraphIO.read(
            serialized,
            format,
            directed: directed,
          );
          _assertGraphsEqual(graph, deserialized);
        }
      }
    },
  );
}
