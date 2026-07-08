import 'dart:collection';

import '../internal/priority_queue.dart';
import '../model/graph_kind.dart';
import '../model/roles.dart';
import '../path.dart';
import '_utils.dart';
import 'dijkstra.dart';
import 'strategy.dart';

/// Bidirectional Dijkstra search.
///
/// Simultaneously runs Dijkstra's algorithm forward from the source and
/// backward from the target.  The first time the two frontiers meet, the
/// shortest path has been found.
///
/// For directed graphs the underlying graph must implement [Bidirectional]
/// so that the backward search can follow incoming edges.  If it does not,
/// the implementation transparently falls back to regular [Dijkstra].
///
/// **Time complexity:** O((V + E) log V) worst case, but typically much
/// faster than unidirectional Dijkstra for single-pair queries.
class BidirectionalDijkstra implements PointToPointStrategy {
  const BidirectionalDijkstra();

  @override
  Path? find<N, E>(
    WeightedWalkable<N, E> graph,
    int from,
    int to, {
    double zero = 0.0,
    double Function(double, double)? add,
    int Function(double, double)? compare,
  }) {
    return shortestPath(
      graph,
      from,
      to,
      zero: zero,
      add: add,
      compare: compare,
    );
  }

  /// Finds the shortest path from [from] to [to] using bidirectional Dijkstra.
  ///
  /// Returns `null` when [from] or [to] does not exist, or when no path
  /// connects them.
  static Path? shortestPath<N, E>(
    WeightedWalkable<N, E> graph,
    int from,
    int to, {
    double zero = 0.0,
    double Function(double, double)? add,
    int Function(double, double)? compare,
  }) {
    if (!graph.hasNode(from) || !graph.hasNode(to)) return null;
    if (from == to) return Path([from], zero);

    if (graph is! Bidirectional<N, E>) {
      return Dijkstra.shortestPath(
        graph,
        from,
        to,
        zero: zero,
        add: add,
        compare: compare,
      );
    }

    final bidirectional = graph as Bidirectional<N, E>;
    final addFn = add ?? defaultAdd;
    final compareFn = compare ?? defaultCompare;

    final pqF = PriorityQueue<(double dist, int node)>(
      (a, b) => compareFn(a.$1, b.$1),
    );
    final pqB = PriorityQueue<(double dist, int node)>(
      (a, b) => compareFn(a.$1, b.$1),
    );

    pqF.push((zero, from));
    pqB.push((zero, to));

    final distF = <int, double>{from: zero};
    final distB = <int, double>{to: zero};
    final predF = <int, int>{};
    final nextB = <int, int>{}; // next node towards the target

    double? bestMu;
    int? bestMeetingNode;

    void consider(double total, int meetingNode) {
      if (bestMu == null || compareFn(total, bestMu!) < 0) {
        bestMu = total;
        bestMeetingNode = meetingNode;
      }
    }

    Iterable<int> backwardNeighbors(int node) =>
        bidirectional.kind == GraphKind.undirected
        ? bidirectional.successors(node)
        : bidirectional.predecessors(node);

    double backwardWeight(int fromNode, int toNode) =>
        bidirectional.edgeWeight(fromNode, toNode);

    while (pqF.isNotEmpty || pqB.isNotEmpty) {
      // Termination: no unsettled frontier crossing can improve on bestMu.
      if (bestMu != null) {
        final topF = pqF.peek;
        final topB = pqB.peek;
        final canStop = switch ((topF, topB)) {
          (null, _) || (_, null) => true,
          _ => compareFn(addFn(topF!.$1, topB!.$1), bestMu!) >= 0,
        };
        if (canStop) break;
      }

      // Expand the frontier with the smaller tentative minimum.
      final topF = pqF.peek;
      final topB = pqB.peek;
      final expandForward =
          topB == null || (topF != null && compareFn(topF.$1, topB.$1) <= 0);

      if (expandForward) {
        _expandForward(
          graph,
          pqF,
          distF,
          distB,
          predF,
          addFn,
          compareFn,
          consider,
        );
      } else {
        _expandBackward(
          graph,
          pqB,
          distB,
          distF,
          nextB,
          backwardNeighbors,
          backwardWeight,
          addFn,
          compareFn,
          consider,
        );
      }
    }

    if (bestMu == null || bestMeetingNode == null) return null;

    return Path(
      _reconstructBidirectionalPath(predF, nextB, bestMeetingNode!),
      bestMu!,
    );
  }

  static void _expandForward<N, E>(
    WeightedWalkable<N, E> graph,
    PriorityQueue<(double dist, int node)> pq,
    Map<int, double> dist,
    Map<int, double> distOther,
    Map<int, int> pred,
    double Function(double, double) add,
    int Function(double, double) compare,
    void Function(double total, int meetingNode) consider,
  ) {
    final (d, u) = pq.pop()!;

    final bestU = dist[u];
    if (bestU == null || compare(d, bestU) > 0) return;

    if (distOther.containsKey(u)) {
      consider(add(d, distOther[u]!), u);
    }

    for (final v in graph.successors(u)) {
      final w = graph.edgeWeight(u, v);
      final newDist = add(d, w);

      final existing = dist[v];
      if (existing == null || compare(newDist, existing) < 0) {
        dist[v] = newDist;
        pred[v] = u;
        pq.push((newDist, v));
      }

      if (distOther.containsKey(v)) {
        consider(add(newDist, distOther[v]!), v);
      }
    }
  }

  static void _expandBackward<N, E>(
    WeightedWalkable<N, E> graph,
    PriorityQueue<(double dist, int node)> pq,
    Map<int, double> dist,
    Map<int, double> distOther,
    Map<int, int> nextB,
    Iterable<int> Function(int) neighbors,
    double Function(int, int) edgeWeight,
    double Function(double, double) add,
    int Function(double, double) compare,
    void Function(double total, int meetingNode) consider,
  ) {
    final (d, u) = pq.pop()!;

    final bestU = dist[u];
    if (bestU == null || compare(d, bestU) > 0) return;

    if (distOther.containsKey(u)) {
      consider(add(d, distOther[u]!), u);
    }

    for (final v in neighbors(u)) {
      final w = edgeWeight(v, u);
      final newDist = add(d, w);

      final existing = dist[v];
      if (existing == null || compare(newDist, existing) < 0) {
        dist[v] = newDist;
        nextB[v] = u; // from v, go to u next on the way to the target
        pq.push((newDist, v));
      }

      if (distOther.containsKey(v)) {
        consider(add(newDist, distOther[v]!), v);
      }
    }
  }

  static List<int> _reconstructBidirectionalPath(
    Map<int, int> predF,
    Map<int, int> nextB,
    int meetingNode,
  ) {
    final forward = reconstructPath(predF, meetingNode);
    final backward = <int>[];
    var current = meetingNode;
    while (nextB.containsKey(current)) {
      current = nextB[current]!;
      backward.add(current);
    }
    return [...forward, ...backward];
  }
}

/// Bidirectional breadth-first search for unweighted shortest paths.
///
/// Returns the fewest-edge path from [from] to [to].  The path [weight] is
/// the number of edges traversed.
///
/// For directed graphs the underlying graph must implement [Bidirectional];
/// otherwise a standard BFS is used as a fallback.
///
/// **Time complexity:** O(V + E)
abstract final class BidirectionalBfs {
  /// Finds a shortest (fewest-edge) path from [from] to [to].
  static Path? shortestPath<N, E>(Walkable<N, E> graph, int from, int to) {
    if (!graph.hasNode(from) || !graph.hasNode(to)) return null;
    if (from == to) return Path([from], 0.0);

    if (graph is! Bidirectional<N, E>) {
      return _unidirectionalBfs(graph, from, to);
    }

    final bidirectional = graph as Bidirectional<N, E>;
    final queueF = Queue<int>()..add(from);
    final queueB = Queue<int>()..add(to);
    final predF = <int, int>{};
    final nextB = <int, int>{};
    final visitedF = <int>{from};
    final visitedB = <int>{to};

    int? meetingNode;

    while (queueF.isNotEmpty && queueB.isNotEmpty && meetingNode == null) {
      // Expand the smaller frontier by one layer.
      if (queueF.length <= queueB.length) {
        meetingNode = _expandBfsLayer(
          bidirectional,
          queueF,
          visitedF,
          visitedB,
          predF,
          forward: true,
        );
      } else {
        meetingNode = _expandBfsLayer(
          bidirectional,
          queueB,
          visitedB,
          visitedF,
          nextB,
          forward: false,
        );
      }
    }

    if (meetingNode == null) return null;

    final path = _reconstructBfsPath(predF, nextB, meetingNode);
    return Path(path, path.length - 1.0);
  }

  static int? _expandBfsLayer<N, E>(
    Bidirectional<N, E> graph,
    Queue<int> queue,
    Set<int> visitedOwn,
    Set<int> visitedOther,
    Map<int, int> parent, {
    required bool forward,
  }) {
    final layerSize = queue.length;
    for (var i = 0; i < layerSize; i++) {
      final u = queue.removeFirst();
      final neighbors = forward
          ? graph.successors(u)
          : (graph.kind == GraphKind.undirected
                ? graph.successors(u)
                : graph.predecessors(u));

      for (final v in neighbors) {
        if (visitedOwn.contains(v)) continue;
        visitedOwn.add(v);
        parent[v] = u;
        queue.addLast(v);

        if (visitedOther.contains(v)) return v;
      }
    }
    return null;
  }

  static List<int> _reconstructBfsPath(
    Map<int, int> predF,
    Map<int, int> nextB,
    int meetingNode,
  ) {
    final forward = <int>[meetingNode];
    var current = meetingNode;
    while (predF.containsKey(current)) {
      current = predF[current]!;
      forward.add(current);
    }

    final backward = <int>[];
    current = meetingNode;
    while (nextB.containsKey(current)) {
      current = nextB[current]!;
      backward.add(current);
    }

    return [...forward.reversed, ...backward];
  }

  static Path? _unidirectionalBfs<N, E>(
    Walkable<N, E> graph,
    int from,
    int to,
  ) {
    final queue = Queue<int>()..add(from);
    final visited = <int>{from};
    final pred = <int, int>{};

    while (queue.isNotEmpty) {
      final u = queue.removeFirst();
      if (u == to) {
        final path = reconstructPath(pred, to);
        return Path(path, path.length - 1.0);
      }

      for (final v in graph.successors(u)) {
        if (visited.contains(v)) continue;
        visited.add(v);
        pred[v] = u;
        queue.addLast(v);
      }
    }

    return null;
  }
}
