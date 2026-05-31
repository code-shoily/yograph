import '../model/roles.dart';
import '../model/graph_kind.dart';

/// Clique finding algorithms using the Bron-Kerbosch algorithm.
abstract final class Clique {
  const Clique._();

  /// Finds the maximum clique in an undirected graph.
  ///
  /// Returns the largest subset of nodes where every pair is connected.
  static Set<int> maxClique<N, E>(Bidirectional<N, E> graph) {
    final cliques = allMaximalCliques(graph);
    if (cliques.isEmpty) return <int>{};
    var maxC = cliques.first;
    for (final c in cliques.skip(1)) {
      if (c.length > maxC.length) {
        maxC = c;
      }
    }
    return maxC;
  }

  /// Finds all maximal cliques in an undirected graph.
  ///
  /// Uses the Bron-Kerbosch algorithm with pivoting optimization.
  static List<Set<int>> allMaximalCliques<N, E>(Bidirectional<N, E> graph) {
    if (graph.kind != GraphKind.undirected) return [];
    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) return [];

    final adj = <int, Set<int>>{
      for (final u in nodes) u: graph.successors(u).toSet(),
    };

    final result = <Set<int>>[];

    void bronKerbosch(Set<int> r, Set<int> p, Set<int> x) {
      if (p.isEmpty && x.isEmpty) {
        if (r.isNotEmpty) {
          result.add(Set.of(r));
        }
        return;
      }

      // Choose pivot from P union X with maximum degree in P
      int? pivot;
      var maxDeg = -1;
      final unionPX = Set<int>.of(p)..addAll(x);
      for (final u in unionPX) {
        final deg = adj[u]!.intersection(p).length;
        if (deg > maxDeg) {
          maxDeg = deg;
          pivot = u;
        }
      }

      final candidates = pivot == null
          ? Set<int>.of(p)
          : p.difference(adj[pivot]!);

      for (final v in candidates) {
        final vNeighbors = adj[v] ?? const {};
        bronKerbosch(
          Set.of(r)..add(v),
          p.intersection(vNeighbors),
          x.intersection(vNeighbors),
        );
        p.remove(v);
        x.add(v);
      }
    }

    bronKerbosch(<int>{}, Set.of(nodes), <int>{});
    return result;
  }

  /// Finds all cliques of exactly size [k] in an undirected graph.
  ///
  /// Uses a modified Bron-Kerbosch algorithm with early pruning.
  static List<Set<int>> kCliques<N, E>(Bidirectional<N, E> graph, int k) {
    if (k <= 0) return [];
    if (graph.kind != GraphKind.undirected) return [];
    final nodes = graph.nodeIds.toList()..sort();
    if (k == 1)
      return [
        for (final u in nodes) {u},
      ];

    final adj = <int, Set<int>>{
      for (final u in nodes) u: graph.successors(u).toSet(),
    };

    final result = <Set<int>>[];

    void findKCliques(List<int> candidates, int remainingK, List<int> current) {
      if (remainingK == 0) {
        result.add(current.toSet());
        return;
      }
      if (candidates.isEmpty) return;

      for (var i = 0; i < candidates.length; i++) {
        final u = candidates[i];
        final uNeighbors = adj[u] ?? const {};

        final newCandidates = <int>[];
        for (var j = i + 1; j < candidates.length; j++) {
          final v = candidates[j];
          if (uNeighbors.contains(v)) {
            newCandidates.add(v);
          }
        }

        if (newCandidates.length >= remainingK - 1) {
          findKCliques(newCandidates, remainingK - 1, [...current, u]);
        }
      }
    }

    findKCliques(nodes, k, []);
    return result;
  }
}
