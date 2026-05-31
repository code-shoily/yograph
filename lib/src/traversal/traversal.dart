import 'dart:collection';
import 'dart:math';

import '../internal/priority_queue.dart';
import '../model/roles.dart';
import 'order.dart';
import 'walk_control.dart';
import 'walk_metadata.dart';

// =============================================================================
// WALKS
// =============================================================================

/// Walks the graph starting from [from], visiting all reachable nodes.
///
/// Returns a list of node IDs in the order they were visited.
/// Uses [Walkable.successors] to follow directed paths.
///
/// **Time Complexity:** O(V + E)
List<int> walk<N, E>(
  Walkable<N, E> graph, {
  required int from,
  required Order order,
}) {
  return foldWalk(
    graph,
    from: from,
    order: order,
    initial: <int>[],
    folder: (acc, nodeId, _) => (WalkControl.continueWalk, [...acc, nodeId]),
  );
}

/// Walks the graph but stops early when [until] returns `true`.
///
/// Traverses the graph until [until] returns `true` for a node.
/// Returns all nodes visited including the one that stopped traversal.
///
/// **Time Complexity:** O(V + E) in worst case; often much less.
List<int> walkUntil<N, E>(
  Walkable<N, E> graph, {
  required int from,
  required Order order,
  required bool Function(int nodeId) until,
}) {
  return foldWalk(
    graph,
    from: from,
    order: order,
    initial: <int>[],
    folder: (acc, nodeId, _) {
      final newAcc = [...acc, nodeId];
      return until(nodeId)
          ? (WalkControl.halt, newAcc)
          : (WalkControl.continueWalk, newAcc);
    },
  );
}

/// Folds over nodes during graph traversal, accumulating state with metadata.
///
/// This is the **universal traversal primitive**. All other walk functions
/// are thin wrappers around it.
///
/// The [folder] function controls the traversal flow:
/// * [WalkControl.continueWalk] — explore successors of the current node
/// * [WalkControl.stopBranch] — skip successors, but continue other queued nodes
/// * [WalkControl.halt] — stop the entire traversal immediately
///
/// **Time Complexity:** O(V + E) for both BFS and DFS.
///
/// ```dart
/// // Find all nodes within distance 3 from start
/// final nearby = foldWalk(
///   graph,
///   from: 0,
///   order: Order.breadthFirst,
///   initial: <int, int>{},
///   folder: (acc, nodeId, meta) {
///     if (meta.depth <= 3) {
///       return (WalkControl.continueWalk, {...acc, nodeId: meta.depth});
///     }
///     return (WalkControl.stopBranch, acc);
///   },
/// );
/// ```
T foldWalk<N, E, T>(
  Walkable<N, E> graph, {
  required int from,
  required Order order,
  required T initial,
  required (WalkControl, T) Function(T acc, int nodeId, WalkMetadata<int> meta)
  folder,
}) {
  return implicitFoldBy<int, int, T>(
    from,
    order: order,
    initial: initial,
    successorsOf: graph.successors,
    visitedBy: (id) => id,
    folder: folder,
  );
}

// =============================================================================
// IMPLICIT GRAPH TRAVERSALS
// =============================================================================

/// Traverses an *implicit* graph using BFS or DFS, folding over visited nodes.
///
/// Unlike [foldWalk], this does not require a materialised graph.
/// Instead, you supply a [successorsOf] function that computes neighbours
/// on the fly — ideal for infinite grids, state-space search, or any
/// graph that is too large or expensive to build upfront.
///
/// **Time Complexity:** O(V + E)
T implicitFold<T>(
  int start, {
  required Order order,
  required T initial,
  required Iterable<int> Function(int) successorsOf,
  required (WalkControl, T) Function(T, int, WalkMetadata<int>) folder,
}) {
  return implicitFoldBy<int, int, T>(
    start,
    order: order,
    initial: initial,
    successorsOf: successorsOf,
    visitedBy: (id) => id,
    folder: folder,
  );
}

/// Like [implicitFold], but deduplicates visited nodes by a custom key.
///
/// This is essential when your node type carries extra state beyond what
/// defines "identity". For example, in state-space search you might have
/// `(position, mask)` nodes, but only want to visit each `position` once —
/// the `mask` is just carried state, not part of the identity.
///
/// The [visitedBy] function extracts the deduplication key from each node.
/// Internally, a `Set<K>` tracks which keys have been visited, but the
/// full `N` value (with all its state) is still passed to your folder.
///
/// **Time Complexity:** O(V + E) where V and E are measured in terms of
/// unique *keys* (not unique nodes).
T implicitFoldBy<N, K, T>(
  N start, {
  required Order order,
  required T initial,
  required Iterable<N> Function(N) successorsOf,
  required K Function(N) visitedBy,
  required (WalkControl, T) Function(T, N, WalkMetadata<N>) folder,
}) {
  final startMeta = WalkMetadata<N>(depth: 0, parent: null);
  switch (order) {
    case Order.breadthFirst:
      final queue = Queue<(N, WalkMetadata<N>)>()..addLast((start, startMeta));
      return _walkBfs(queue, <K>{}, initial, successorsOf, visitedBy, folder);
    case Order.depthFirst:
      final stack = <(N, WalkMetadata<N>)>[(start, startMeta)];
      return _walkDfs(stack, <K>{}, initial, successorsOf, visitedBy, folder);
  }
}

T _walkBfs<N, K, T>(
  Queue<(N, WalkMetadata<N>)> queue,
  Set<K> visited,
  T acc,
  Iterable<N> Function(N) successorsOf,
  K Function(N) keyFn,
  (WalkControl, T) Function(T, N, WalkMetadata<N>) folder,
) {
  while (queue.isNotEmpty) {
    final (node, meta) = queue.removeFirst();
    final key = keyFn(node);
    if (visited.contains(key)) continue;

    final (control, newAcc) = folder(acc, node, meta);
    visited.add(key);

    switch (control) {
      case WalkControl.halt:
        return newAcc;
      case WalkControl.stopBranch:
        acc = newAcc;
        continue;
      case WalkControl.continueWalk:
        final nextMeta = WalkMetadata<N>(depth: meta.depth + 1, parent: node);
        for (final n in successorsOf(node)) {
          queue.addLast((n, nextMeta));
        }
        acc = newAcc;
    }
  }
  return acc;
}

T _walkDfs<N, K, T>(
  List<(N, WalkMetadata<N>)> stack,
  Set<K> visited,
  T acc,
  Iterable<N> Function(N) successorsOf,
  K Function(N) keyFn,
  (WalkControl, T) Function(T, N, WalkMetadata<N>) folder,
) {
  while (stack.isNotEmpty) {
    final (node, meta) = stack.removeLast();
    final key = keyFn(node);
    if (visited.contains(key)) continue;

    final (control, newAcc) = folder(acc, node, meta);
    visited.add(key);

    switch (control) {
      case WalkControl.halt:
        return newAcc;
      case WalkControl.stopBranch:
        acc = newAcc;
        continue;
      case WalkControl.continueWalk:
        final nextMeta = WalkMetadata<N>(depth: meta.depth + 1, parent: node);
        // Push successors in reverse so they are explored in original order.
        final succs = successorsOf(node).toList();
        for (var i = succs.length - 1; i >= 0; i--) {
          stack.add((succs[i], nextMeta));
        }
        acc = newAcc;
    }
  }
  return acc;
}

// =============================================================================
// BEST-FIRST SEARCH
// =============================================================================

/// Performs a Greedy Best-First Walk starting from [from].
///
/// Visits nodes in order of their score as determined by [scoredBy].
/// Lower scores are visited first. Unlike Dijkstra, scores are not cumulative.
///
/// **Time Complexity:** O((V + E) log V)
List<int> bestFirstWalk<N, E>(
  Walkable<N, E> graph, {
  required int from,
  required int Function(int nodeId) scoredBy,
}) {
  return bestFirstFold(
    graph,
    from: from,
    initial: <int>[],
    scoredBy: scoredBy,
    folder: (acc, nodeId) => (WalkControl.continueWalk, [...acc, nodeId]),
  );
}

/// Folds over nodes in Best-First order using a priority queue.
///
/// Nodes are explored according to the score returned by [scoredBy]
/// (cheapest first). This is a Greedy Best-First Search — if you need
/// cumulative edge costs, use Dijkstra instead.
///
/// **Time Complexity:** O((V + E) log V)
T bestFirstFold<N, E, T>(
  Walkable<N, E> graph, {
  required int from,
  required T initial,
  required int Function(int nodeId) scoredBy,
  required (WalkControl, T) Function(T acc, int nodeId) folder,
}) {
  final pq = PriorityQueue<(int, int)>((a, b) => a.$1.compareTo(b.$1))
    ..push((scoredBy(from), from));

  final visited = <int>{};
  var acc = initial;

  while (pq.isNotEmpty) {
    final entry = pq.pop()!;
    final (_, node) = entry;
    if (visited.contains(node)) continue;

    final (control, newAcc) = folder(acc, node);
    visited.add(node);
    acc = newAcc;

    switch (control) {
      case WalkControl.halt:
        return acc;
      case WalkControl.stopBranch:
        continue;
      case WalkControl.continueWalk:
        for (final nb in graph.successors(node)) {
          if (!visited.contains(nb)) {
            pq.push((scoredBy(nb), nb));
          }
        }
    }
  }

  return acc;
}

// =============================================================================
// RANDOM WALK
// =============================================================================

/// Simulates a random walk on the graph for a specified number of steps.
///
/// At each step, one of the current node's neighbors is chosen uniformly
/// at random. Returns the sequence of node IDs visited.
///
/// [seed] is optional for reproducibility.
///
/// **Time Complexity:** O(steps)
List<int> randomWalk<N, E>(
  Walkable<N, E> graph, {
  required int from,
  required int steps,
  int? seed,
}) {
  final rng = seed != null ? Random(seed) : Random();
  final result = <int>[from];
  var current = from;

  for (var i = 0; i < steps; i++) {
    final neighbors = graph.successors(current).toList();
    if (neighbors.isEmpty) break;
    current = neighbors[rng.nextInt(neighbors.length)];
    result.add(current);
  }

  return result;
}

// =============================================================================
// TOPOLOGICAL SORTS
// =============================================================================

/// Performs a topological sort on a directed graph using Kahn's algorithm.
///
/// Returns a linear ordering of nodes such that for every directed edge
/// (u, v), node u comes before node v in the ordering.
///
/// Returns `null` if the graph contains a cycle.
///
/// **Time Complexity:** O(V + E)
List<int>? topologicalSort<N, E>(Bidirectional<N, E> graph) {
  final inDegrees = <int, int>{
    for (final id in graph.nodeIds) id: graph.inDegree(id),
  };

  final queue = Queue<int>();
  for (final entry in inDegrees.entries) {
    if (entry.value == 0) queue.addLast(entry.key);
  }

  final result = <int>[];
  final totalCount = graph.nodeCount;

  while (queue.isNotEmpty) {
    final node = queue.removeFirst();
    result.add(node);

    for (final nb in graph.successors(node)) {
      final newDeg = inDegrees[nb]! - 1;
      inDegrees[nb] = newDeg;
      if (newDeg == 0) queue.addLast(nb);
    }
  }

  return result.length == totalCount ? result : null;
}

/// Performs a topological sort that returns the lexicographically smallest
/// sequence.
///
/// Uses a heap-based version of Kahn's algorithm to ensure that when multiple
/// nodes have in-degree 0, the smallest one (according to [compareNodes]
/// applied to node *data*) is chosen first.
///
/// Returns `null` if the graph contains a cycle.
///
/// **Time Complexity:** O(V log V + E) due to heap operations.
List<int>? lexicographicalTopologicalSort<N, E>(
  Bidirectional<N, E> graph,
  int Function(N a, N b) compareNodes,
) {
  final inDegrees = <int, int>{
    for (final id in graph.nodeIds) id: graph.inDegree(id),
  };

  final pq = PriorityQueue<int>((a, b) {
    final da = graph.nodeData(a);
    final db = graph.nodeData(b);
    // If either node has no data, fall back to ID comparison.
    if (da == null || db == null) return a.compareTo(b);
    return compareNodes(da, db);
  });

  for (final entry in inDegrees.entries) {
    if (entry.value == 0) pq.push(entry.key);
  }

  final result = <int>[];
  final totalCount = graph.nodeCount;

  while (pq.isNotEmpty) {
    final node = pq.pop()!;
    result.add(node);

    for (final nb in graph.successors(node)) {
      final newDeg = inDegrees[nb]! - 1;
      inDegrees[nb] = newDeg;
      if (newDeg == 0) pq.push(nb);
    }
  }

  return result.length == totalCount ? result : null;
}
