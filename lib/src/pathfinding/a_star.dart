import '../internal/priority_queue.dart';
import '../model/roles.dart';
import '../model/weight_algebra.dart';
import '../path.dart';
import '_utils.dart';
import 'strategy.dart';

/// A* (A-Star) search algorithm for optimal pathfinding with heuristic guidance.
///
/// A* combines Dijkstra's algorithm with a heuristic function to efficiently
/// find the shortest path in weighted graphs.  It prioritises exploration
/// toward the goal using `f(n) = g(n) + h(n)`.
///
/// The algorithm works with any edge type [E] through a [WeightAlgebra<E>].
/// When [E] is `double` and no algebra is supplied, [DoubleAlgebra.instance]
/// is used automatically — preserving full backwards compatibility.
///
/// **Requirements:**
/// - All edge weights must be non-negative. If the graph contains negative edge
///   weights, the algorithm is not guaranteed to produce correct results.
///
/// ## Heuristic requirements
///
/// For optimality the heuristic must be **admissible** (never over-estimate
/// the true cost).  Consistency (`h(n) ≤ c(n,n') + h(n')`) is also desirable.
///
/// ```dart
/// // Unchanged existing usage (double edges):
/// final path = AStar.aStar(graph, 0, 5, heuristic: manhattan);
///
/// // Custom algebra:
/// final path = AStar.aStar(graph, 0, 5,
///   heuristic: (_, _) => 0.0,
///   algebra: RoadByKm.instance,
/// );
/// ```
class AStar implements PointToPointStrategy {
  final double Function(int node, int goal) _heuristic;

  AStar({required this._heuristic});

  @override
  Path<E>? find<N, E>(
    WeightedWalkable<N, E> graph,
    int from,
    int to, {
    WeightAlgebra<E>? algebra,
  }) {
    return aStar(graph, from, to, heuristic: _heuristic, algebra: algebra);
  }

  /// Finds the shortest path from [from] to [to] using A*.
  ///
  /// **Time complexity:** O((V + E) log V) with a good heuristic.
  static Path<E>? aStar<N, E>(
    WeightedWalkable<N, E> graph,
    int from,
    int to, {
    required double Function(int node, int goal) heuristic,
    WeightAlgebra<E>? algebra,
  }) {
    final alg = resolveAlgebra<E>(algebra);
    if (!graph.hasNode(from) || !graph.hasNode(to)) return null;
    if (from == to) return Path([from], alg.zero);

    // We use double scalars for the priority queue and store typed weights
    // alongside so the final result carries the full typed weight.
    final pq = PriorityQueue<(double f, double g, E gTyped, int node)>((a, b) {
      final cmp = a.$1.compareTo(b.$1);
      if (cmp != 0) return cmp;
      return b.$2.compareTo(a.$2); // tie-break: prefer larger g
    });

    final zero = alg.zero;
    final zeroD = alg.toDouble(zero);
    final h0 = heuristic(from, to);
    pq.push((zeroD + h0, zeroD, zero, from));

    final gScores = <int, double>{from: zeroD};
    final gTyped = <int, E>{from: zero};
    final predecessors = <int, int>{};

    while (pq.isNotEmpty) {
      final (_, g, gT, node) = pq.pop()!;

      final bestG = gScores[node];
      if (bestG == null || g > bestG) continue;

      if (node == to) {
        return Path(reconstructPath(predecessors, to), gT);
      }

      for (final succ in graph.successors(node)) {
        final edgeRaw = edgeValue(graph, node, succ, alg);
        final newGTyped = alg.add(gT, edgeRaw);
        final newG = alg.toDouble(newGTyped);

        final existingG = gScores[succ];
        if (existingG == null || newG < existingG) {
          gScores[succ] = newG;
          gTyped[succ] = newGTyped;
          predecessors[succ] = node;
          final h = heuristic(succ, to);
          pq.push((newG + h, newG, newGTyped, succ));
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
    final addFn = add ?? (a, b) => a + b;
    final compareFn = compare ?? (a, b) => a.compareTo(b);

    if (isGoal(from)) return (from, zero);

    final pq = PriorityQueue<(double f, double g, S state)>((a, b) {
      final cmp = compareFn(a.$1, b.$1);
      if (cmp != 0) return cmp;
      return compareFn(b.$2, a.$2);
    });

    final fromKey = visitedBy(from);
    pq.push((addFn(zero, heuristic(from)), zero, from));

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
          pq.push((addFn(newG, heuristic(nextState)), newG, nextState));
        }
      }
    }

    return null;
  }
}

/// Resolves an optional [WeightAlgebra<E>], falling back to [DoubleAlgebra]
/// when [E] is `double` and no algebra is provided.
///
/// This is the Elixir-style ring resolution: if you don't supply a ring,
/// the default numeric ring is used.
WeightAlgebra<E> resolveAlgebra<E>(WeightAlgebra<E>? algebra) {
  if (algebra != null) return algebra;
  if (E == double || E == dynamic || E == Null || E.toString() == 'void') {
    return DoubleAlgebra.instance as WeightAlgebra<E>;
  }
  if (E == int) {
    return IntAlgebra.instance as WeightAlgebra<E>;
  }
  throw ArgumentError(
    'A WeightAlgebra<$E> must be supplied for non-double edge types. '
    'Example: Dijkstra.shortestPath(graph, 0, 5, algebra: MyAlgebra.instance)',
  );
}
