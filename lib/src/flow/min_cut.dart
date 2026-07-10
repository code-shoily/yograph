import '../model/graph_kind.dart';
import '../model/roles.dart';
import '../model/mutable.dart';
import '../simple_graph.dart';
import '../internal/priority_queue.dart';
import 'max_flow.dart';
import 'min_cut_result.dart';

/// Static class housing minimum cut algorithms.
abstract final class MinCut {
  /// Computes the minimum s-t cut using a maximum flow algorithm.
  static MinCutResult stMinCut<N>(
    WeightedWalkable<N, num> graph,
    int source,
    int sink, {
    String algorithm = 'Dinic',
    GraphCreator<N, double>? createGraph,
  }) {
    final normAlg = algorithm
        .replaceAll(RegExp(r'[^a-zA-Z]'), '')
        .toLowerCase();
    final flowResult = normAlg == 'edmondskarp'
        ? MaxFlow.edmondsKarp(graph, source, sink, createGraph: createGraph)
        : normAlg == 'pushrelabel'
        ? MaxFlow.pushRelabel(graph, source, sink, createGraph: createGraph)
        : MaxFlow.dinic(graph, source, sink, createGraph: createGraph);

    return MaxFlow.extractMinCut(flowResult);
  }

  /// Finds the global minimum cut of an undirected weighted graph.
  ///
  /// This implementation uses the Stoer-Wagner algorithm. It repeatedly finds
  /// an s-t min-cut in a phase using Maximum Adjacency Search and then contracts
  /// the nodes s and t. The global minimum cut is the minimum of all phase cuts.
  ///
  /// **Time Complexity:** O(V^2 log V + V E) with Priority Queue optimization.
  static MinCutResult globalMinCut<N>(WeightedWalkable<N, num> graph) {
    if (graph.kind != GraphKind.undirected) {
      throw ArgumentError('Global min cut requires an undirected graph');
    }

    final nodes = graph.nodeIds.toList();
    if (nodes.length <= 1) {
      return MinCutResult(
        cutValue: 0.0,
        sourceSide: nodes.toSet(),
        sinkSide: const {},
        algorithm: 'Stoer-Wagner',
      );
    }

    // Validate that all edge weights are non-negative
    for (final u in nodes) {
      for (final v in graph.successors(u)) {
        final w = (graph.edgeData(u, v) ?? 1.0).toDouble();
        if (w < 0.0) {
          throw ArgumentError(
            'Edge weight from $u to $v cannot be negative: $w',
          );
        }
      }
    }

    // Create a mutable working copy for contractions
    Mutable<N, num> localCreate(GraphKind kind) =>
        SimpleGraph<N, num>.undirected();
    final tempGraph = localCreate(GraphKind.undirected);
    for (final u in nodes) {
      tempGraph.addNode(u, data: graph.nodeData(u));
    }
    for (final u in nodes) {
      for (final v in graph.successors(u)) {
        if (u < v) {
          tempGraph.addEdge(u, v, data: graph.edgeData(u, v));
        }
      }
    }

    // Track the partitions for each contracted node
    final partitions = <int, Set<int>>{};
    for (final u in nodes) {
      partitions[u] = {u};
    }

    double? bestCutValue;
    Set<int>? bestSourceSide;

    while (tempGraph.nodeCount > 1) {
      final (s, t, cutWeight) = _maximumAdjacencySearch(tempGraph);

      if (bestCutValue == null || cutWeight < bestCutValue) {
        bestCutValue = cutWeight;
        bestSourceSide = Set<int>.from(partitions[t]!);
      }

      // Merge t into s
      partitions[s]!.addAll(partitions[t]!);
      partitions.remove(t);

      _contract(tempGraph, s, t);
    }

    final allNodesSet = nodes.toSet();
    final sourceSide = bestSourceSide ?? const {};
    final sinkSide = allNodesSet.difference(sourceSide);

    return MinCutResult(
      cutValue: bestCutValue ?? 0.0,
      sourceSide: sourceSide,
      sinkSide: sinkSide,
      algorithm: 'Stoer-Wagner',
    );
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  static (int s, int t, double cutWeight) _maximumAdjacencySearch<N>(
    WeightedWalkable<N, num> graph,
  ) {
    final nodes = graph.nodeIds.toList();
    final start = nodes.first;

    final inSearch = <int>{start};
    final weights = <int, double>{};

    for (final v in graph.successors(start)) {
      weights[v] = (graph.edgeData(start, v) ?? 1.0).toDouble();
    }

    // Max-priority queue storing MapEntry(node, weight)
    final pq = PriorityQueue<MapEntry<int, double>>(
      (a, b) => b.value.compareTo(a.value),
    );
    for (final v in nodes) {
      if (v != start) {
        pq.push(MapEntry(v, weights[v] ?? 0.0));
      }
    }

    final order = <int>[start];

    while (order.length < nodes.length) {
      final entry = pq.pop();
      if (entry == null) break;
      final u = entry.key;
      final w = entry.value;

      if (inSearch.contains(u) || w < (weights[u] ?? 0.0) - 1e-9) {
        continue;
      }

      inSearch.add(u);
      order.add(u);

      for (final v in graph.successors(u)) {
        if (!inSearch.contains(v)) {
          final edgeW = (graph.edgeData(u, v) ?? 1.0).toDouble();
          weights[v] = (weights[v] ?? 0.0) + edgeW;
          pq.push(MapEntry(v, weights[v]!));
        }
      }
    }

    final t = order.last;
    final s = order[order.length - 2];
    final cutWeight = weights[t] ?? 0.0;

    return (s, t, cutWeight);
  }

  static void _contract<N>(Mutable<N, num> graph, int s, int t) {
    final tSuccessors = graph.successors(t).toList();
    for (final v in tSuccessors) {
      if (v == s) continue;
      final w = (graph.edgeData(t, v) ?? 1.0).toDouble();
      final existingW = (graph.edgeData(s, v) ?? 0.0).toDouble();
      final newW = existingW + w;

      if (graph.edgeData(s, v) != null) {
        graph.removeEdge(s, v);
      }
      graph.addEdge(s, v, data: newW as num);
    }
    graph.removeNode(t);
  }
}
