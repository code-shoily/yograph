import '../internal/priority_queue.dart';
import '../model/roles.dart';
import '../path.dart';
import '_utils.dart';
import 'strategy.dart';

/// A* (A-Star) search algorithm for optimal pathfinding with heuristic guidance.
///
/// A* combines Dijkstra's algorithm with a heuristic function to efficiently
/// find the shortest path in weighted graphs.  It prioritises exploration
/// toward the goal using `f(n) = g(n) + h(n)`.
///
/// ## Heuristic requirements
///
/// For optimality the heuristic must be **admissible** (never over-estimate
/// the true cost).  Consistency (`h(n) ≤ c(n,n') + h(n')`) is also desirable.
///
/// ```dart
/// final path = AStar.aStar(
///   graph,
///   0, 5,
///   heuristic: (node, goal) => estimate[node] ?? 0.0,
/// );
/// ```
class AStar implements PointToPointStrategy {
  final double Function(int node, int goal) _heuristic;

  /// Creates an A* strategy with the given [heuristic].
  ///
  /// [heuristic] estimates the cost from any node to the goal.
  AStar({required this._heuristic});

  @override
  Path? find<N, E>(
    WeightedWalkable<N, E> graph,
    int from,
    int to, {
    double zero = 0.0,
    double Function(double, double)? add,
    int Function(double, double)? compare,
  }) {
    return aStar(
      graph,
      from,
      to,
      heuristic: _heuristic,
      zero: zero,
      add: add,
      compare: compare,
    );
  }

  /// Finds the shortest path from [from] to [to] using A*.
  ///
  /// Returns `null` when [from] or [to] does not exist, or when no path
  /// connects them.
  ///
  /// **Time complexity:** O((V + E) log V) with a good heuristic.
  static Path? aStar<N, E>(
    WeightedWalkable<N, E> graph,
    int from,
    int to, {
    required double Function(int node, int goal) heuristic,
    double zero = 0.0,
    double Function(double, double)? add,
    int Function(double, double)? compare,
  }) {
    if (!graph.hasNode(from) || !graph.hasNode(to)) return null;
    if (from == to) return Path([from], zero);

    final addFn = add ?? defaultAdd;
    final compareFn = compare ?? defaultCompare;

    final pq = PriorityQueue<(double f, double g, int node)>((a, b) {
      final cmp = compareFn(a.$1, b.$1);
      if (cmp != 0) return cmp;
      // Tie-break: prefer larger g (closer to goal).
      return compareFn(b.$2, a.$2);
    });

    final h0 = heuristic(from, to);
    pq.push((addFn(zero, h0), zero, from));

    final gScores = <int, double>{from: zero};
    final predecessors = <int, int>{};

    while (pq.isNotEmpty) {
      final (_, g, node) = pq.pop()!;

      final bestG = gScores[node];
      if (bestG == null || compareFn(g, bestG) > 0) continue;

      if (node == to) {
        return Path(reconstructPath(predecessors, to), g);
      }

      for (final succ in graph.successors(node)) {
        final edgeCost = graph.edgeWeight(node, succ);
        final newG = addFn(g, edgeCost);

        final existingG = gScores[succ];
        if (existingG == null || compareFn(newG, existingG) < 0) {
          gScores[succ] = newG;
          predecessors[succ] = node;
          final h = heuristic(succ, to);
          final f = addFn(newG, h);
          pq.push((f, newG, succ));
        }
      }
    }

    return null;
  }

  /// Runs A* on an implicit (generated) state space.
  ///
  /// Provide [successors] — a function that yields neighbouring states
  /// together with the transition cost.
  ///
  /// Returns the goal state and its cost, or `null` when unreachable.
  static (S state, double cost)? implicitAStar<S>({
    required S from,
    required Iterable<(S, double)> Function(S) successors,
    required bool Function(S) isGoal,
    required double Function(S) heuristic,
    double zero = 0.0,
    double Function(double, double)? add,
    int Function(double, double)? compare,
  }) {
    return implicitAStarBy(
      from: from,
      successors: successors,
      visitedBy: (s) => s,
      isGoal: isGoal,
      heuristic: heuristic,
      zero: zero,
      add: add,
      compare: compare,
    );
  }

  /// Runs A* on an implicit state space with a custom deduplication key.
  ///
  /// [visitedBy] extracts a lightweight key from each state.  Two states
  /// with the same key are considered equivalent; only the best (lowest
  /// cost) instance is kept.
  static (S state, double cost)? implicitAStarBy<S, K>({
    required S from,
    required Iterable<(S, double)> Function(S) successors,
    required K Function(S) visitedBy,
    required bool Function(S) isGoal,
    required double Function(S) heuristic,
    double zero = 0.0,
    double Function(double, double)? add,
    int Function(double, double)? compare,
  }) {
    final addFn = add ?? defaultAdd;
    final compareFn = compare ?? defaultCompare;

    if (isGoal(from)) return (from, zero);

    final pq = PriorityQueue<(double f, double g, S state)>((a, b) {
      final cmp = compareFn(a.$1, b.$1);
      if (cmp != 0) return cmp;
      return compareFn(b.$2, a.$2);
    });

    final fromKey = visitedBy(from);
    final h0 = heuristic(from);
    pq.push((addFn(zero, h0), zero, from));

    final gScores = <K, double>{fromKey: zero};

    while (pq.isNotEmpty) {
      final (_, g, state) = pq.pop()!;

      final key = visitedBy(state);
      final bestG = gScores[key];
      if (bestG == null || compareFn(g, bestG) > 0) continue;

      if (isGoal(state)) return (state, g);

      for (final (nextState, cost) in successors(state)) {
        final newG = addFn(g, cost);
        final nextKey = visitedBy(nextState);
        final existingG = gScores[nextKey];

        if (existingG == null || compareFn(newG, existingG) < 0) {
          gScores[nextKey] = newG;
          final h = heuristic(nextState);
          final f = addFn(newG, h);
          pq.push((f, newG, nextState));
        }
      }
    }

    return null;
  }
}
