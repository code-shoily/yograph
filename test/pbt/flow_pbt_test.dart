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
      final w = edge[2].abs().toDouble(); // non-negative weights/capacities
      graph.addEdge(u, v, data: w);
    }
  }
  return graph;
}

class FlowInput {
  final List<List<int>> edges;
  final int sourceIdx;
  final int sinkIdx;

  FlowInput(this.edges, this.sourceIdx, this.sinkIdx);

  factory FlowInput.fromList(List<List<int>> list) {
    if (list.length < 2) {
      return FlowInput([], 0, 0);
    }
    final sourceIdx = list[0].isNotEmpty ? list[0][0] : 0;
    final sinkIdx = (list[0].length >= 2) ? list[0][1] : 0;
    final edges = list.sublist(1);
    return FlowInput(edges, sourceIdx, sinkIdx);
  }
}

double _originalCapacity(WeightedWalkable<void, double> graph, int u, int v) {
  return graph.hasEdge(u, v) ? graph.edgeWeight(u, v) : 0.0;
}

double _residualCapacity(
  WeightedWalkable<void, double> residualGraph,
  int u,
  int v,
) {
  return residualGraph.hasEdge(u, v) ? residualGraph.edgeWeight(u, v) : 0.0;
}

double _netFlow(
  WeightedWalkable<void, double> graph,
  WeightedWalkable<void, double> residualGraph,
  int u,
  int v,
) {
  return _originalCapacity(graph, u, v) -
      _residualCapacity(residualGraph, u, v);
}

void main() {
  Glados<List<List<int>>>(any.list(any.list(any.int))).test(
    'Max-Flow Min-Cut Theorem: max flow value equals min cut capacity',
    (rawInput) {
      final input = FlowInput.fromList(rawInput);
      final graph = _buildWeightedGraph(
        input.edges,
        true,
      ); // directed capacity graph
      if (graph.isEmpty) return;

      final nodes = graph.nodeIds.toList();
      var source = nodes[input.sourceIdx.abs() % nodes.length];
      var sink = nodes[input.sinkIdx.abs() % nodes.length];
      if (source == sink) {
        sink = nodes[(input.sinkIdx.abs() + 1) % nodes.length];
      }
      if (source == sink) return;

      final flowResult = MaxFlow.dinic(graph, source, sink);
      final cutResult = MinCut.stMinCut(graph, source, sink);

      expect(flowResult.maxFlow, closeTo(cutResult.cutValue, 1e-9));
    },
  );

  Glados<List<List<int>>>(any.list(any.list(any.int))).test(
    'Flow Conservation: net flow sum is zero at every node except source/sink',
    (rawInput) {
      final input = FlowInput.fromList(rawInput);
      final graph = _buildWeightedGraph(input.edges, true);
      if (graph.isEmpty) return;

      final nodes = graph.nodeIds.toList();
      var source = nodes[input.sourceIdx.abs() % nodes.length];
      var sink = nodes[input.sinkIdx.abs() % nodes.length];
      if (source == sink) {
        sink = nodes[(input.sinkIdx.abs() + 1) % nodes.length];
      }
      if (source == sink) return;

      final flowResult = MaxFlow.dinic(graph, source, sink);
      final residual = flowResult.residualGraph;

      for (final u in graph.nodeIds) {
        if (u == source || u == sink) continue;
        var netFlowSum = 0.0;
        for (final v in graph.nodeIds) {
          netFlowSum += _netFlow(graph, residual, u, v);
        }
        expect(netFlowSum, closeTo(0.0, 1e-9));
      }
    },
  );

  Glados<List<List<int>>>(any.list(any.list(any.int))).test(
    'Residual Graph Termination: no augmenting path exists in the residual graph after max flow',
    (rawInput) {
      final input = FlowInput.fromList(rawInput);
      final graph = _buildWeightedGraph(input.edges, true);
      if (graph.isEmpty) return;

      final nodes = graph.nodeIds.toList();
      var source = nodes[input.sourceIdx.abs() % nodes.length];
      var sink = nodes[input.sinkIdx.abs() % nodes.length];
      if (source == sink) {
        sink = nodes[(input.sinkIdx.abs() + 1) % nodes.length];
      }
      if (source == sink) return;

      final flowResult = MaxFlow.dinic(graph, source, sink);
      final path = Pathfinding.shortestPath(
        flowResult.residualGraph,
        source,
        sink,
      );

      expect(path, isNull);
    },
  );

  Glados<List<List<int>>>(any.list(any.list(any.int))).test(
    'Zero Flow on Disconnected: max flow is zero between disconnected components',
    (rawInput) {
      final input = FlowInput.fromList(rawInput);
      final graph = _buildWeightedGraph(input.edges, true);
      if (graph.isEmpty) return;

      final nodes = graph.nodeIds.toList();
      var source = nodes[input.sourceIdx.abs() % nodes.length];
      var sink = nodes[input.sinkIdx.abs() % nodes.length];
      if (source == sink) {
        sink = nodes[(input.sinkIdx.abs() + 1) % nodes.length];
      }
      if (source == sink) return;

      final originalPath = Pathfinding.shortestPath(graph, source, sink);
      final flowResult = MaxFlow.dinic(graph, source, sink);

      if (originalPath == null) {
        expect(flowResult.maxFlow, equals(0.0));
      }
    },
  );

  Glados<List<List<int>>>(any.list(any.list(any.int))).test(
    'Max-Flow agrees with brute-force cut enumeration on small graphs',
    (rawInput) {
      final input = FlowInput.fromList(rawInput);
      final graph = _buildWeightedGraph(
        input.edges,
        true,
      ); // directed capacity graph
      if (graph.isEmpty) return;

      final nodes = graph.nodeIds.toList();
      if (nodes.length > 8 || graph.edgeCount > 12) return;

      var source = nodes[input.sourceIdx.abs() % nodes.length];
      var sink = nodes[input.sinkIdx.abs() % nodes.length];
      if (source == sink) {
        sink = nodes[(input.sinkIdx.abs() + 1) % nodes.length];
      }
      if (source == sink) return;

      final flowDinic = MaxFlow.dinic(graph, source, sink);
      final flowEK = MaxFlow.edmondsKarp(graph, source, sink);
      final expectedFlow = _bruteForceMaxFlow(graph, source, sink);

      expect(flowDinic.maxFlow, closeTo(expectedFlow, 1e-9));
      expect(flowEK.maxFlow, closeTo(expectedFlow, 1e-9));
    },
  );
}

double _bruteForceMaxFlow(
  WeightedWalkable<void, double> graph,
  int source,
  int sink,
) {
  final nodes = graph.nodeIds.toList();
  if (!nodes.contains(source) || !nodes.contains(sink)) return 0.0;
  if (source == sink) return 0.0;

  final otherNodes = nodes.where((n) => n != source && n != sink).toList();
  var minCutCapacity = double.infinity;

  final numSubsets = 1 << otherNodes.length;
  for (var mask = 0; mask < numSubsets; mask++) {
    final S = <int>{source};
    for (var i = 0; i < otherNodes.length; i++) {
      if ((mask & (1 << i)) != 0) {
        S.add(otherNodes[i]);
      }
    }

    var capacity = 0.0;
    for (final u in S) {
      for (final v in graph.successors(u)) {
        if (!S.contains(v)) {
          capacity += graph.edgeWeight(u, v);
        }
      }
    }

    if (capacity < minCutCapacity) {
      minCutCapacity = capacity;
    }
  }

  return minCutCapacity;
}
