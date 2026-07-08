import 'dart:math';

import '../model/roles.dart';
import 'community_dendrogram.dart';
import 'community_metrics.dart';
import 'community_result.dart';

/// Walktrap algorithm for community detection.
///
/// Uses random walks to compute distances between nodes, then performs
/// hierarchical agglomerative clustering based on those distances.
abstract final class Walktrap {
  const Walktrap._();

  /// Detects communities with custom options.
  static CommunityResult detect<N, E>(
    Bidirectional<N, E> graph, {
    int walkLength = 4,
    int? targetCommunities,
  }) => detectWithOptions(
    graph,
    walkLength: walkLength,
    targetCommunities: targetCommunities,
  );

  /// Detects communities with custom options.
  ///
  /// Options:
  /// - [walkLength]: length of random walks (default 4)
  /// - [targetCommunities]: stop when this many communities remain
  static CommunityResult detectWithOptions<N, E>(
    Bidirectional<N, E> graph, {
    int walkLength = 4,
    int? targetCommunities,
  }) {
    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) return CommunityResult({});
    if (nodes.length == 1) return CommunityResult({nodes.first: 0});

    final dendrogram = detectHierarchical(graph, walkLength: walkLength);

    if (targetCommunities != null) {
      final level = dendrogram.atLevel(targetCommunities);
      if (level != null) return level;
      return dendrogram.coarsest;
    }

    return _pickBestLevelByModularity(dendrogram.levels, graph);
  }

  /// Full hierarchical Walktrap detection.
  static CommunityDendrogram detectHierarchical<N, E>(
    Bidirectional<N, E> graph, {
    int walkLength = 4,
  }) {
    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) return CommunityDendrogram([]);
    if (nodes.length == 1) {
      return CommunityDendrogram([
        CommunityResult({nodes.first: 0}),
      ]);
    }

    final pT = _computePt(graph, walkLength);
    final degrees = <int, double>{};
    for (final u in nodes) {
      var d = 0.0;
      for (final v in graph.successors(u)) {
        d += graph.edgeWeight(u, v);
      }
      degrees[u] = max(d, 1.0);
    }

    final assignments = <int, int>{for (final node in nodes) node: node};
    final sizes = <int, int>{for (final node in nodes) node: 1};
    final commDegrees = <int, double>{
      for (final node in nodes) node: degrees[node]!,
    };
    final ptCache = <int, Map<int, double>>{
      for (final node in nodes) node: Map<int, double>.from(pT[node] ?? {}),
    };

    final initialResult = CommunityResult(assignments);
    return _doWalktrapMerge(
      [initialResult],
      degrees,
      ptCache,
      sizes,
      commDegrees,
    );
  }

  // ---------------------------------------------------------------------------
  // Random walk computation
  // ---------------------------------------------------------------------------

  static Map<int, Map<int, double>> _computePt<N, E>(
    Bidirectional<N, E> graph,
    int t,
  ) {
    final nodes = graph.nodeIds.toList();
    final p1 = <int, Map<int, double>>{};

    for (final u in nodes) {
      final neighbors = graph.successors(u).toList();
      var totalWeight = 0.0;
      for (final v in neighbors) {
        totalWeight += graph.edgeWeight(u, v);
      }

      final row = <int, double>{};
      if (totalWeight > 0) {
        for (final v in neighbors) {
          row[v] = graph.edgeWeight(u, v) / totalWeight;
        }
      }
      p1[u] = row;
    }

    var result = p1;
    for (var step = 1; step < t; step++) {
      result = _multiplySparseMatrices(result, p1);
    }
    return result;
  }

  static Map<int, Map<int, double>> _multiplySparseMatrices(
    Map<int, Map<int, double>> a,
    Map<int, Map<int, double>> b,
  ) {
    final result = <int, Map<int, double>>{};
    for (final entry in a.entries) {
      final i = entry.key;
      final rowA = entry.value;
      final newRow = <int, double>{};

      for (final aEntry in rowA.entries) {
        final k = aEntry.key;
        final aik = aEntry.value;
        final rowB = b[k] ?? {};
        for (final bEntry in rowB.entries) {
          final j = bEntry.key;
          final bkj = bEntry.value;
          newRow[j] = (newRow[j] ?? 0.0) + aik * bkj;
        }
      }

      result[i] = {
        for (final e in newRow.entries)
          if (e.value > 1e-12) e.key: e.value,
      };
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Hierarchical merging
  // ---------------------------------------------------------------------------

  static CommunityDendrogram _doWalktrapMerge(
    List<CommunityResult> levels,
    Map<int, double> degrees,
    Map<int, Map<int, double>> ptCache,
    Map<int, int> sizes,
    Map<int, double> commDegrees,
  ) {
    final currentLevel = levels.last;
    if (currentLevel.numCommunities <= 1) {
      return CommunityDendrogram(levels);
    }

    final merge = _findBestMerge(currentLevel, ptCache, degrees, sizes);

    if (merge == null) return CommunityDendrogram(levels);

    final (c1, c2) = merge;
    final mergedMap = _mergeCommunities(currentLevel.assignments, c2, c1);
    final nextLevel = CommunityResult(mergedMap);

    final s1 = sizes[c1] ?? 1;
    final s2 = sizes[c2] ?? 1;
    final newSizes = Map<int, int>.from(sizes)
      ..remove(c2)
      ..[c1] = s1 + s2;

    final d1 = commDegrees[c1] ?? 1.0;
    final d2 = commDegrees[c2] ?? 1.0;
    final newCommDegrees = Map<int, double>.from(commDegrees)
      ..remove(c2)
      ..[c1] = d1 + d2;

    final pC1 = ptCache[c1] ?? {};
    final pC2 = ptCache[c2] ?? {};
    final mergedPt = _mergeCommunityPt(pC1, pC2, d1, d2);
    final newPtCache = Map<int, Map<int, double>>.from(ptCache)
      ..remove(c2)
      ..[c1] = mergedPt;

    return _doWalktrapMerge(
      [...levels, nextLevel],
      degrees,
      newPtCache,
      newSizes,
      newCommDegrees,
    );
  }

  static (int, int)? _findBestMerge(
    CommunityResult communities,
    Map<int, Map<int, double>> ptCache,
    Map<int, double> degrees,
    Map<int, int> sizes,
  ) {
    final ids = communities.assignments.values.toSet().toList();
    if (ids.length < 2) return null;

    var bestPair = (ids[0], ids[1]);
    var bestDist = double.infinity;

    for (var i = 0; i < ids.length; i++) {
      for (var j = i + 1; j < ids.length; j++) {
        final c1 = ids[i];
        final c2 = ids[j];
        final r2 = _cachedDistanceSquared(c1, c2, ptCache, degrees);
        final s1 = sizes[c1] ?? 1;
        final s2 = sizes[c2] ?? 1;
        final wardDist = s1 * s2 / (s1 + s2) * r2;

        if (wardDist < bestDist) {
          bestDist = wardDist;
          bestPair = (c1, c2);
        }
      }
    }

    return bestPair;
  }

  static double _cachedDistanceSquared(
    int c1,
    int c2,
    Map<int, Map<int, double>> ptCache,
    Map<int, double> degrees,
  ) {
    final pC1 = ptCache[c1] ?? {};
    final pC2 = ptCache[c2] ?? {};
    final allNodes = {...pC1.keys, ...pC2.keys};

    var sum = 0.0;
    for (final k in allNodes) {
      final dK = degrees[k] ?? 1.0;
      final pk1 = pC1[k] ?? 0.0;
      final pk2 = pC2[k] ?? 0.0;
      final diff = pk1 - pk2;
      sum += diff * diff / dK;
    }
    return sum;
  }

  static Map<int, double> _mergeCommunityPt(
    Map<int, double> pC1,
    Map<int, double> pC2,
    double d1,
    double d2,
  ) {
    final totalD = d1 + d2;
    if (totalD == 0.0) return {};

    final allKeys = {...pC1.keys, ...pC2.keys};
    final result = <int, double>{};

    for (final k in allKeys) {
      final v1 = pC1[k] ?? 0.0;
      final v2 = pC2[k] ?? 0.0;
      final avg = (d1 * v1 + d2 * v2) / totalD;
      if (avg > 1e-12) result[k] = avg;
    }
    return result;
  }

  static Map<int, int> _mergeCommunities(
    Map<int, int> assignments,
    int source,
    int target,
  ) {
    return {
      for (final entry in assignments.entries)
        entry.key: entry.value == source ? target : entry.value,
    };
  }

  static CommunityResult _pickBestLevelByModularity<N, E>(
    List<CommunityResult> levels,
    Bidirectional<N, E> graph,
  ) {
    if (levels.isEmpty) return CommunityResult({});

    CommunityResult? best;
    var bestQ = double.negativeInfinity;

    for (final level in levels) {
      final q = CommunityMetrics.modularity(graph, level);
      if (q > bestQ) {
        bestQ = q;
        best = level;
      }
    }

    return best!;
  }
}
