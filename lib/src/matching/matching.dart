import 'dart:collection';
import 'dart:math' as math;

import '../model/roles.dart';
import '../property/bipartite.dart';

/// Optimization direction for the Hungarian algorithm.
enum HungarianOptimization { min, max }

/// Result of a Hungarian weighted bipartite matching query.
class HungarianResult {
  /// Total cost (or total weight for maximization) of the matching.
  final double cost;

  /// Bidirectional matching map.  For every matched pair `{u, v}`, both
  /// `matching[u] == v` and `matching[v] == u` are present.
  final Map<int, int> matching;

  const HungarianResult(this.cost, this.matching);

  @override
  String toString() =>
      'HungarianResult(cost: $cost, ${matching.length ~/ 2} pairs)';
}

/// General graph matching algorithms.
///
/// Provides maximum-cardinality matching for bipartite graphs
/// ([hopcroftKarp]), maximum-weight perfect matching for complete bipartite
/// graphs ([hungarian]), and maximum-cardinality matching for general
/// (non-bipartite) graphs ([blossomMaximumMatching]).
abstract final class Matching {
  Matching._();

  // ---------------------------------------------------------------------------
  // Hopcroft–Karp: maximum bipartite matching
  // ---------------------------------------------------------------------------

  /// Finds a maximum cardinality matching in a bipartite graph.
  ///
  /// Returns a bidirectional map where every matched edge `{u, v}` appears
  /// as both `result[u] == v` and `result[v] == u`.  Isolated nodes are
  /// omitted.
  ///
  /// Throws [ArgumentError] if [graph] is not bipartite.
  ///
  /// **Time complexity:** O(E × √V)
  static Map<int, int> hopcroftKarp<N, E>(Bidirectional<N, E> graph) {
    final partition = Bipartite.partition(graph);
    if (partition == null) {
      throw ArgumentError('Hopcroft-Karp requires a bipartite graph.');
    }

    final left = partition.left.toList();
    final rightSet = partition.right;

    if (left.isEmpty || rightSet.isEmpty) return const {};

    final adj = <int, List<int>>{};
    for (final u in left) {
      adj[u] = _neighbors(graph, u).where(rightSet.contains).toList();
    }

    final pairU = <int, int?>{}; // left -> right
    final pairV = <int, int?>{}; // right -> left
    for (final u in left) {
      pairU[u] = null;
    }
    for (final v in rightSet) {
      pairV[v] = null;
    }

    final dist = <int?, int>{};
    const inf = 1 << 30;

    bool bfs() {
      final queue = Queue<int?>();
      for (final u in left) {
        if (pairU[u] == null) {
          dist[u] = 0;
          queue.add(u);
        } else {
          dist[u] = inf;
        }
      }
      dist[null] = inf;

      while (queue.isNotEmpty) {
        final u = queue.removeFirst();
        if (u == null) continue;
        if (dist[u]! < dist[null]!) {
          for (final v in adj[u] ?? const <int>[]) {
            final u2 = pairV[v];
            if (dist[u2] == inf) {
              dist[u2] = dist[u]! + 1;
              queue.add(u2);
            }
          }
        }
      }

      return dist[null]! != inf;
    }

    bool dfs(int? u) {
      if (u == null) return true;
      for (final v in adj[u] ?? const <int>[]) {
        final u2 = pairV[v];
        if (dist[u2] == dist[u]! + 1 && dfs(u2)) {
          pairU[u] = v;
          pairV[v] = u;
          return true;
        }
      }
      dist[u] = inf;
      return false;
    }

    while (bfs()) {
      for (final u in left) {
        if (pairU[u] == null) {
          dfs(u);
        }
      }
    }

    final result = <int, int>{};
    for (final u in left) {
      final v = pairU[u];
      if (v != null) {
        result[u] = v;
        result[v] = u;
      }
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Hungarian: weighted bipartite matching / assignment problem
  // ---------------------------------------------------------------------------

  /// Finds a minimum- or maximum-weight perfect matching in a complete
  /// bipartite graph.
  ///
  /// Returns a [HungarianResult] containing the total cost and a
  /// bidirectional matching map.  Rectangular partitions are padded with
  /// zero-cost dummy nodes.  Dummy matches are omitted from the result.
  ///
  /// Throws [ArgumentError] if [graph] is not bipartite or not complete
  /// bipartite.
  ///
  /// **Time complexity:** O(V³)
  static HungarianResult hungarian<N, E>(
    Bidirectional<N, E> graph, {
    HungarianOptimization optimization = HungarianOptimization.min,
  }) {
    final partition = Bipartite.partition(graph);
    if (partition == null) {
      throw ArgumentError('Hungarian algorithm requires a bipartite graph.');
    }

    final leftList = partition.left.toList()..sort();
    final rightList = partition.right.toList()..sort();

    final nLeft = leftList.length;
    final nRight = rightList.length;
    final k = math.max(nLeft, nRight);

    if (k == 0) return const HungarianResult(0.0, {});

    // Pad the smaller side with dummy nodes.
    final paddedLeft = List<int>.from(leftList);
    final paddedRight = List<int>.from(rightList);
    var dummyLeftId = -1;
    var dummyRightId = -2;
    for (var i = nLeft; i < k; i++) {
      paddedLeft.add(dummyLeftId);
      dummyLeftId -= 2;
    }
    for (var i = nRight; i < k; i++) {
      paddedRight.add(dummyRightId);
      dummyRightId -= 2;
    }

    final realLeft = partition.left;
    final realRight = partition.right;

    // Build k×k cost matrix; 1-based internally.
    final matrix = List<List<double>>.generate(
      k + 1,
      (_) => List<double>.filled(k + 1, 0.0),
    );

    for (var i = 1; i <= k; i++) {
      final u = paddedLeft[i - 1];
      final isDummyU = !realLeft.contains(u);
      for (var j = 1; j <= k; j++) {
        final v = paddedRight[j - 1];
        final isDummyV = !realRight.contains(v);
        if (isDummyU || isDummyV) {
          matrix[i][j] = 0.0;
        } else {
          double? weight;
          if (graph.hasEdge(u, v)) {
            weight = graph.edgeWeight(u, v);
          } else if (graph.hasEdge(v, u)) {
            weight = graph.edgeWeight(v, u);
          }
          if (weight == null) {
            throw ArgumentError(
              'hungarian() requires a complete bipartite graph; '
              'missing edge between $u and $v.',
            );
          }
          matrix[i][j] = optimization == HungarianOptimization.max
              ? -weight
              : weight;
        }
      }
    }

    final result = _hungarianImpl(matrix, k);
    final totalCost = result.$1;
    final columnToRow = result.$2;

    final matching = <int, int>{};
    for (var j = 1; j <= k; j++) {
      final i = columnToRow[j];
      if (i == null || i == 0) continue;
      final u = paddedLeft[i - 1];
      final v = paddedRight[j - 1];
      if (realLeft.contains(u) && realRight.contains(v)) {
        matching[u] = v;
        matching[v] = u;
      }
    }

    final cost = optimization == HungarianOptimization.max
        ? -totalCost
        : totalCost;
    return HungarianResult(cost, matching);
  }

  /// Classic Kuhn–Munkres implementation with 1-based indexing.
  ///
  /// Returns `(totalCost, columnToRowMatching)`.
  static (double, Map<int, int>) _hungarianImpl(
    List<List<double>> matrix,
    int n,
  ) {
    final u = List<double>.filled(n + 1, 0.0);
    final v = List<double>.filled(n + 1, 0.0);
    final p = List<int>.filled(n + 1, 0);
    final way = List<int>.filled(n + 1, 0);

    for (var i = 1; i <= n; i++) {
      p[0] = i;
      final minv = List<double>.filled(n + 1, double.infinity);
      final used = List<bool>.filled(n + 1, false);
      var j0 = 0;

      while (true) {
        used[j0] = true;
        final i0 = p[j0];
        var delta = double.infinity;
        var j1 = 0;

        for (var j = 1; j <= n; j++) {
          if (!used[j]) {
            final cur = matrix[i0][j] - u[i0] - v[j];
            if (cur < minv[j]) {
              minv[j] = cur;
              way[j] = j0;
            }
            if (minv[j] < delta) {
              delta = minv[j];
              j1 = j;
            }
          }
        }

        for (var j = 0; j <= n; j++) {
          if (used[j]) {
            u[p[j]] += delta;
            v[j] -= delta;
          } else {
            minv[j] -= delta;
          }
        }

        j0 = j1;
        if (p[j0] == 0) break;
      }

      // Augmenting: backtrack through way[].
      while (true) {
        final j1 = way[j0];
        p[j0] = p[j1];
        j0 = j1;
        if (j0 == 0) break;
      }
    }

    final matching = <int, int>{};
    for (var j = 1; j <= n; j++) {
      if (p[j] != 0) matching[j] = p[j];
    }

    return (-v[0], matching);
  }

  // ---------------------------------------------------------------------------
  // Edmonds' blossom: maximum matching in general graphs
  // ---------------------------------------------------------------------------

  /// Finds a maximum cardinality matching in a general (not necessarily
  /// bipartite) graph.
  ///
  /// Returns a bidirectional map where every matched edge `{u, v}` appears
  /// as both `result[u] == v` and `result[v] == u`.  Isolated nodes are
  /// omitted.
  ///
  /// **Time complexity:** O(V² × E)
  static Map<int, int> blossomMaximumMatching<N, E>(Bidirectional<N, E> graph) {
    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) return const {};

    final adj = <int, List<int>>{};
    for (final u in nodes) {
      adj[u] = _neighbors(graph, u).toList();
    }

    var match = const <int, int>{};

    for (final root in nodes) {
      if (match.containsKey(root)) continue;
      match = _blossomTryAugment(root, adj, match, nodes);
    }

    return match;
  }

  static Map<int, int> _blossomTryAugment(
    int root,
    Map<int, List<int>> adj,
    Map<int, int> match,
    List<int> nodes,
  ) {
    final base = <int, int>{for (final n in nodes) n: n};
    final parent = <int, int>{};
    final used = <int>{root};
    final queue = Queue<int>()..add(root);

    return _blossomBfs(queue, adj, match, base, parent, used, root);
  }

  static Map<int, int> _blossomBfs(
    Queue<int> queue,
    Map<int, List<int>> adj,
    Map<int, int> match,
    Map<int, int> base,
    Map<int, int> parent,
    Set<int> used,
    int root,
  ) {
    while (queue.isNotEmpty) {
      final v = queue.removeFirst();
      for (final to in adj[v] ?? const <int>[]) {
        final result = _processBlossomNeighbor(
          v,
          to,
          adj,
          match,
          base,
          parent,
          used,
          queue,
          root,
        );
        if (result != null) return result;
      }
    }
    return match;
  }

  static Map<int, int>? _processBlossomNeighbor(
    int v,
    int to,
    Map<int, List<int>> adj,
    Map<int, int> match,
    Map<int, int> base,
    Map<int, int> parent,
    Set<int> used,
    Queue<int> queue,
    int root,
  ) {
    final vBase = base[v]!;
    final toBase = base[to]!;

    if (vBase == toBase) return null;
    if (match[v] == to) return null;

    // Blossom found: 'to' is an even vertex in the tree.
    if (to == root ||
        (match.containsKey(to) && parent.containsKey(match[to]!))) {
      final curBase = _blossomLca(v, to, base, match, parent);

      var contractResult = _blossomContract(
        v,
        curBase,
        to,
        base,
        match,
        parent,
        queue,
        used,
      );
      base.addAll(contractResult.base);
      parent.addAll(contractResult.parent);
      used.addAll(contractResult.used);
      while (contractResult.queue.isNotEmpty) {
        queue.add(contractResult.queue.removeFirst());
      }

      contractResult = _blossomContract(
        to,
        curBase,
        v,
        base,
        match,
        parent,
        queue,
        used,
      );
      base.addAll(contractResult.base);
      parent.addAll(contractResult.parent);
      used.addAll(contractResult.used);
      while (contractResult.queue.isNotEmpty) {
        queue.add(contractResult.queue.removeFirst());
      }

      for (final i in nodesForBlossom(adj)) {
        if (used.contains(i) || base[base[i]!]! == curBase) {
          _resolveBase(i, base, curBase);
        }
      }
      return null;
    }

    if (to != root && !parent.containsKey(to)) {
      if (!match.containsKey(to)) {
        // Free vertex — augmenting path found.
        parent[to] = v;
        return _blossomAugment(to, parent, match);
      } else {
        // Matched vertex — extend the tree.
        final mate = match[to]!;
        parent[to] = v;
        used.add(mate);
        queue.add(mate);
      }
    }

    return null;
  }

  // Helper because base map may gain new keys during resolve.
  static Iterable<int> nodesForBlossom(Map<int, List<int>> adj) => adj.keys;

  static int _blossomLca(
    int a,
    int b,
    Map<int, int> base,
    Map<int, int> match,
    Map<int, int> parent,
  ) {
    final visited = <int>{};
    while (true) {
      final aBase = base[a]!;
      if (visited.contains(aBase)) return aBase;
      visited.add(aBase);

      final mate = match[aBase];
      int? nextA;
      if (mate != null) nextA = parent[mate];

      if (nextA == null) {
        final temp = a;
        a = b;
        b = temp;
      } else {
        a = nextA;
      }
    }
  }

  static _ContractResult _blossomContract(
    int v,
    int b,
    int child,
    Map<int, int> base,
    Map<int, int> match,
    Map<int, int> parent,
    Queue<int> queue,
    Set<int> used,
  ) {
    final baseCopy = Map<int, int>.of(base);
    final parentCopy = Map<int, int>.of(parent);
    final queueCopy = Queue<int>.of(queue);
    final usedCopy = <int>{...used};

    while (baseCopy[v] != b) {
      final vBase = baseCopy[v]!;
      baseCopy[vBase] = b;
      final mate = match[vBase];

      if (mate != null) {
        final mateBase = baseCopy[mate];
        if (mateBase != null) baseCopy[mateBase] = b;
      }

      parentCopy[v] = child;
      child = mate ?? child;

      if (mate != null && !usedCopy.contains(mate)) {
        queueCopy.add(mate);
        usedCopy.add(mate);
      }

      if (mate != null && parentCopy.containsKey(mate)) {
        v = parentCopy[mate]!;
      } else {
        v = b;
      }
    }

    return _ContractResult(baseCopy, parentCopy, queueCopy, usedCopy);
  }

  static void _resolveBase(int i, Map<int, int> base, int curBase) {
    var b = base[i];
    if (b == null) return;
    if (b == curBase || b == i) return;

    _resolveBase(b, base, curBase);
    b = base[i];
    if (b == null) return;

    final baseOfB = base[b];
    if (baseOfB == curBase) {
      base[i] = curBase;
    }
  }

  static Map<int, int> _blossomAugment(
    int v,
    Map<int, int> parent,
    Map<int, int> match,
  ) {
    final result = Map<int, int>.of(match);
    var current = v;

    while (true) {
      final pv = parent[current];
      if (pv == null) break;
      final ppv = result[pv];

      result[current] = pv;
      result[pv] = current;

      if (ppv == null) break;
      current = ppv;
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns the undirected neighbors of [node] (successors ∪ predecessors).
  static Set<int> _neighbors<N, E>(Bidirectional<N, E> graph, int node) {
    return graph.successors(node).toSet()..addAll(graph.predecessors(node));
  }
}

class _ContractResult {
  final Map<int, int> base;
  final Map<int, int> parent;
  final Queue<int> queue;
  final Set<int> used;

  _ContractResult(this.base, this.parent, this.queue, this.used);
}
