import '../simple_graph.dart';
import 'max_flow_result.dart';
import 'min_cut_result.dart';

/// Static class housing maximum flow algorithms.
abstract final class MaxFlow {
  /// Finds the maximum flow using the Edmonds-Karp algorithm.
  ///
  /// Edmonds-Karp is an implementation of Ford-Fulkerson using BFS
  /// to find shortest augmenting paths. Complexity is O(V E^2).
  static MaxFlowResult<N> edmondsKarp<N>(
    SimpleGraph<N, num> graph,
    int source,
    int sink,
  ) {
    _validateInputs(graph, source, sink);

    if (source == sink) {
      return _zeroFlowResult(graph, source, sink, 'Edmonds-Karp');
    }

    final nodes = graph.nodeIds.toList();
    final residual = <int, Map<int, double>>{};
    for (final u in nodes) {
      residual[u] = <int, double>{};
    }

    for (final u in nodes) {
      for (final v in graph.successors(u)) {
        final cap = (graph.edgeData(u, v) ?? 1.0).toDouble();
        residual[u]![v] = (residual[u]![v] ?? 0.0) + cap;
        residual[v]![u] = residual[v]![u] ?? 0.0;
      }
    }

    double maxFlow = 0.0;
    final bottleneckOut = <int, double>{};

    while (true) {
      bottleneckOut.clear();
      final path = _findAugmentingPath(residual, source, sink, bottleneckOut);
      if (path == null) break;

      final bottleneck = bottleneckOut[sink]!;
      maxFlow += bottleneck;

      for (int i = 0; i < path.length - 1; i++) {
        final u = path[i];
        final v = path[i + 1];
        residual[u]![v] = residual[u]![v]! - bottleneck;
        residual[v]![u] = residual[v]![u]! + bottleneck;
      }
    }

    return MaxFlowResult(
      maxFlow: maxFlow,
      residualGraph: _buildResidualGraph(graph, residual),
      source: source,
      sink: sink,
      algorithm: 'Edmonds-Karp',
    );
  }

  /// Finds the maximum flow using Dinic's algorithm.
  ///
  /// Dinic's algorithm constructs a level graph using BFS and finds
  /// blocking flows using DFS. Complexity is O(V^2 E).
  static MaxFlowResult<N> dinic<N>(
    SimpleGraph<N, num> graph,
    int source,
    int sink,
  ) {
    _validateInputs(graph, source, sink);

    if (source == sink) {
      return _zeroFlowResult(graph, source, sink, 'Dinic');
    }

    final nodes = graph.nodeIds.toList();
    final residual = <int, Map<int, double>>{};
    for (final u in nodes) {
      residual[u] = <int, double>{};
    }

    for (final u in nodes) {
      for (final v in graph.successors(u)) {
        final cap = (graph.edgeData(u, v) ?? 1.0).toDouble();
        residual[u]![v] = (residual[u]![v] ?? 0.0) + cap;
        residual[v]![u] = residual[v]![u] ?? 0.0;
      }
    }

    double maxFlow = 0.0;

    while (true) {
      final level = _dinicBfs(residual, source, sink);
      if (level == null) break;

      final adj = <int, List<int>>{};
      final ptr = <int, int>{};
      for (final u in nodes) {
        adj[u] = residual[u]!.keys.toList();
        ptr[u] = 0;
      }

      while (true) {
        final pushed = _dinicDfs(
          residual,
          level,
          adj,
          ptr,
          source,
          sink,
          double.infinity,
        );
        if (pushed == 0.0) break;
        maxFlow += pushed;
      }
    }

    return MaxFlowResult(
      maxFlow: maxFlow,
      residualGraph: _buildResidualGraph(graph, residual),
      source: source,
      sink: sink,
      algorithm: 'Dinic',
    );
  }

  /// Finds the maximum flow using the Push-Relabel (Goldberg-Tarjan) algorithm.
  ///
  /// This implementation uses highest-label selection and the gap heuristic
  /// for high-performance maximum flow resolution. Complexity is O(V^3).
  static MaxFlowResult<N> pushRelabel<N>(
    SimpleGraph<N, num> graph,
    int source,
    int sink,
  ) {
    _validateInputs(graph, source, sink);

    if (source == sink) {
      return _zeroFlowResult(graph, source, sink, 'Push-Relabel');
    }

    final nodes = graph.nodeIds.toList();
    final n = nodes.length;

    final residual = <int, Map<int, double>>{};
    for (final u in nodes) {
      residual[u] = <int, double>{};
    }

    for (final u in nodes) {
      for (final v in graph.successors(u)) {
        final cap = (graph.edgeData(u, v) ?? 1.0).toDouble();
        residual[u]![v] = (residual[u]![v] ?? 0.0) + cap;
        residual[v]![u] = residual[v]![u] ?? 0.0;
      }
    }

    final height = <int, int>{};
    final excess = <int, double>{};
    for (final u in nodes) {
      height[u] = 0;
      excess[u] = 0.0;
    }

    height[source] = n;

    final buckets = <int, Set<int>>{};
    for (int i = 0; i <= 2 * n; i++) {
      buckets[i] = <int>{};
    }

    int maxH = 0;

    final sourceNeighbors = residual[source] ?? const {};
    for (final neighborEntry in Map<int, double>.from(
      sourceNeighbors,
    ).entries) {
      final v = neighborEntry.key;
      final cap = neighborEntry.value;
      if (v == source || cap <= 0) continue;

      residual[source]![v] = residual[source]![v]! - cap;
      residual[v]![source] = (residual[v]![source] ?? 0.0) + cap;

      excess[source] = excess[source]! - cap;
      excess[v] = excess[v]! + cap;

      if (v != source && v != sink && excess[v]! > 0) {
        buckets[0]!.add(v);
      }
    }

    final count = <int, int>{};
    for (int i = 0; i <= 2 * n; i++) {
      count[i] = 0;
    }
    for (final u in nodes) {
      if (u != source) {
        count[height[u]!] = count[height[u]!]! + 1;
      }
    }
    count[height[source]!] = count[height[source]!]! + 1;

    final ptrs = <int, List<int>>{};
    for (final u in nodes) {
      ptrs[u] = residual[u]!.keys.toList();
    }

    void push(int u, int v, double amount) {
      residual[u]![v] = residual[u]![v]! - amount;
      residual[v]![u] = residual[v]![u]! + amount;
      excess[u] = excess[u]! - amount;
      excess[v] = excess[v]! + amount;
    }

    void gap(int gapHeight) {
      for (final u in nodes) {
        if (u != source && u != sink) {
          final h = height[u]!;
          if (h > gapHeight && h < n + 1) {
            buckets[h]!.remove(u);
            count[h] = count[h]! - 1;
            height[u] = n + 1;
            count[n + 1] = count[n + 1]! + 1;
          }
        }
      }
    }

    void relabel(int u) {
      final oldHeight = height[u]!;
      int minHeight = 2 * n + 1;
      for (final neighborEntry in residual[u]!.entries) {
        final v = neighborEntry.key;
        final cap = neighborEntry.value;
        if (cap > 0) {
          final h = height[v]!;
          if (h < minHeight) {
            minHeight = h;
          }
        }
      }

      final newHeight = minHeight + 1;
      height[u] = newHeight;

      count[oldHeight] = count[oldHeight]! - 1;
      count[newHeight] = count[newHeight]! + 1;

      buckets[oldHeight]!.remove(u);
      if (newHeight < n) {
        buckets[newHeight]!.add(u);
      }

      if (newHeight > maxH) {
        maxH = newHeight;
      }

      if (count[oldHeight] == 0 && oldHeight < n) {
        gap(oldHeight);
      }
    }

    void discharge(int u) {
      while (excess[u]! > 0) {
        final remaining = ptrs[u]!;
        if (remaining.isEmpty) {
          relabel(u);
          ptrs[u] = residual[u]!.keys.toList();
        } else {
          final v = remaining.first;
          final cap = residual[u]![v]!;
          if (cap > 0 && height[u]! == height[v]! + 1) {
            final amount = excess[u]! < cap ? excess[u]! : cap;
            push(u, v, amount);

            if (v != source && v != sink && excess[v]! > 0) {
              buckets[height[v]!]!.add(v);
              if (height[v]! > maxH) {
                maxH = height[v]!;
              }
            }
          } else {
            remaining.removeAt(0);
          }
        }
      }
      buckets[height[u]!]!.remove(u);
    }

    while (maxH >= 0) {
      if (buckets[maxH]!.isEmpty) {
        maxH--;
      } else {
        final u = buckets[maxH]!.first;
        discharge(u);
      }
    }

    return MaxFlowResult(
      maxFlow: excess[sink] ?? 0.0,
      residualGraph: _buildResidualGraph(graph, residual),
      source: source,
      sink: sink,
      algorithm: 'Push-Relabel',
    );
  }

  /// Extracts the minimum cut from a max flow result.
  static MinCutResult extractMinCut<N>(MaxFlowResult<N> result) {
    final residual = result.residualGraph;
    final source = result.source;

    final visited = <int>{source};
    final queue = [source];

    while (queue.isNotEmpty) {
      final u = queue.removeAt(0);
      for (final v in residual.successors(u)) {
        final cap = residual.edgeData(u, v) ?? 0.0;
        if (cap > 0.0 && !visited.contains(v)) {
          visited.add(v);
          queue.add(v);
        }
      }
    }

    final allNodes = residual.nodeIds.toSet();
    final sinkSide = allNodes.difference(visited);

    return MinCutResult(
      cutValue: result.maxFlow,
      sourceSide: visited,
      sinkSide: sinkSide,
      algorithm: result.algorithm,
    );
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  static void _validateInputs(
    SimpleGraph<dynamic, num> graph,
    int source,
    int sink,
  ) {
    if (!graph.hasNode(source)) {
      throw ArgumentError('Source node $source not in graph');
    }
    if (!graph.hasNode(sink)) {
      throw ArgumentError('Sink node $sink not in graph');
    }
    for (final u in graph.nodeIds) {
      for (final v in graph.successors(u)) {
        final cap = (graph.edgeData(u, v) ?? 1.0).toDouble();
        if (cap < 0.0) {
          throw ArgumentError(
            'Edge capacity from $u to $v cannot be negative: $cap',
          );
        }
      }
    }
  }

  static MaxFlowResult<N> _zeroFlowResult<N>(
    SimpleGraph<N, num> graph,
    int source,
    int sink,
    String algorithm,
  ) {
    final res = SimpleGraph<N, double>.directed();
    for (final u in graph.nodeIds) {
      res.addNode(u, data: graph.nodeData(u));
    }
    for (final u in graph.nodeIds) {
      for (final v in graph.successors(u)) {
        final cap = (graph.edgeData(u, v) ?? 1.0).toDouble();
        res.addEdge(u, v, data: cap);
      }
    }
    return MaxFlowResult(
      maxFlow: 0.0,
      residualGraph: res,
      source: source,
      sink: sink,
      algorithm: algorithm,
    );
  }

  static List<int>? _findAugmentingPath(
    Map<int, Map<int, double>> residual,
    int source,
    int sink,
    Map<int, double> bottleneckOut,
  ) {
    final parent = <int, int>{};
    final visited = <int>{source};
    final queue = [source];
    final bottlenecks = {source: double.infinity};

    while (queue.isNotEmpty) {
      final u = queue.removeAt(0);
      if (u == sink) {
        bottleneckOut[sink] = bottlenecks[sink]!;
        final path = <int>[];
        var curr = sink;
        while (curr != source) {
          path.add(curr);
          curr = parent[curr]!;
        }
        path.add(source);
        return path.reversed.toList();
      }

      final neighbors = residual[u] ?? const {};
      for (final entry in neighbors.entries) {
        final v = entry.key;
        final cap = entry.value;
        if (cap > 0 && !visited.contains(v)) {
          visited.add(v);
          parent[v] = u;
          bottlenecks[v] = bottlenecks[u]! < cap ? bottlenecks[u]! : cap;
          queue.add(v);
        }
      }
    }
    return null;
  }

  static Map<int, int>? _dinicBfs(
    Map<int, Map<int, double>> residual,
    int source,
    int sink,
  ) {
    final level = {source: 0};
    final queue = [source];

    while (queue.isNotEmpty) {
      final u = queue.removeAt(0);
      final uLevel = level[u]!;

      final neighbors = residual[u] ?? const {};
      for (final entry in neighbors.entries) {
        final v = entry.key;
        final cap = entry.value;
        if (cap > 0 && !level.containsKey(v)) {
          level[v] = uLevel + 1;
          queue.add(v);
        }
      }
    }
    return level.containsKey(sink) ? level : null;
  }

  static double _dinicDfs(
    Map<int, Map<int, double>> residual,
    Map<int, int> level,
    Map<int, List<int>> adj,
    Map<int, int> ptr,
    int u,
    int sink,
    double pushable,
  ) {
    if (pushable == 0.0) return 0.0;
    if (u == sink) return pushable;

    final neighbors = adj[u] ?? const [];
    for (int i = ptr[u] ?? 0; i < neighbors.length; i = (ptr[u] = i + 1)) {
      final v = neighbors[i];
      final cap = residual[u]![v]!;

      if (level[v] == level[u]! + 1 && cap > 0) {
        final nextPushable = pushable < cap ? pushable : cap;
        final pushed = _dinicDfs(
          residual,
          level,
          adj,
          ptr,
          v,
          sink,
          nextPushable,
        );
        if (pushed > 0.0) {
          residual[u]![v] = residual[u]![v]! - pushed;
          residual[v]![u] = (residual[v]![u] ?? 0.0) + pushed;
          return pushed;
        }
      }
    }
    return 0.0;
  }

  static SimpleGraph<N, double> _buildResidualGraph<N>(
    SimpleGraph<N, num> originalGraph,
    Map<int, Map<int, double>> residualMap,
  ) {
    final graph = SimpleGraph<N, double>.directed();
    for (final u in originalGraph.nodeIds) {
      graph.addNode(u, data: originalGraph.nodeData(u));
    }
    for (final entry in residualMap.entries) {
      final u = entry.key;
      for (final innerEntry in entry.value.entries) {
        final v = innerEntry.key;
        final cap = innerEntry.value;
        if (cap > 0.0) {
          graph.addEdge(u, v, data: cap);
        }
      }
    }
    return graph;
  }
}
