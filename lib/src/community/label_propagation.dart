import 'dart:math';

import '../model/roles.dart';
import 'community_result.dart';

/// Label Propagation Algorithm (LPA) for community detection.
///
/// A fast, near-linear-time algorithm in which each node adopts the label that
/// most of its neighbors currently hold. The algorithm converges when no node
/// changes its label in a full pass.
abstract final class LabelPropagation {
  const LabelPropagation._();

  /// Detects communities using Label Propagation.
  ///
  /// [seed] controls deterministic tie-breaking. If `null`, a non-deterministic
  /// random number generator is used. [maxIterations] bounds the number of
  /// asynchronous update passes.
  static CommunityResult detect<N, E>(
    Bidirectional<N, E> graph, {
    int? seed,
    int maxIterations = 100,
  }) {
    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) return CommunityResult({});
    if (nodes.length == 1) return CommunityResult({nodes.first: 0});

    final random = seed == null ? Random() : Random(seed);
    var labels = <int, int>{for (final n in nodes) n: n};

    for (var iteration = 0; iteration < maxIterations; iteration++) {
      final shuffled = List<int>.from(nodes)..shuffle(random);
      var changed = false;

      for (final node in shuffled) {
        final neighbors = _neighbors(graph, node);
        if (neighbors.isEmpty) continue;

        final currentLabel = labels[node]!;
        final bestLabel = _mostFrequentLabel(
          neighbors.map((n) => labels[n]!).toList(),
          currentLabel,
          seed ?? 0,
        );

        if (bestLabel != currentLabel) {
          labels[node] = bestLabel;
          changed = true;
        }
      }

      if (!changed) break;
    }

    return _normalize(labels);
  }

  static List<int> _neighbors<N, E>(Bidirectional<N, E> graph, int node) {
    final neighbors = <int>{};
    for (final neighbor in graph.successors(node)) {
      neighbors.add(neighbor);
    }
    for (final neighbor in graph.predecessors(node)) {
      neighbors.add(neighbor);
    }
    return neighbors.toList();
  }

  static int _mostFrequentLabel(List<int> labels, int currentLabel, int seed) {
    final frequencies = <int, int>{};
    var maxCount = 0;
    for (final label in labels) {
      final count = frequencies.update(label, (v) => v + 1, ifAbsent: () => 1);
      if (count > maxCount) maxCount = count;
    }

    final candidates = frequencies.entries
        .where((e) => e.value == maxCount)
        .map((e) => e.key)
        .toList();

    if (candidates.contains(currentLabel)) return currentLabel;

    candidates.sort((a, b) {
      final ha = _hash(a, seed);
      final hb = _hash(b, seed);
      return ha.compareTo(hb);
    });
    return candidates.first;
  }

  static int _hash(int label, int seed) => Object.hash(label, seed);

  static CommunityResult _normalize(Map<int, int> labels) {
    final unique = labels.values.toSet().toList()..sort();
    final mapping = <int, int>{
      for (var i = 0; i < unique.length; i++) unique[i]: i,
    };
    return CommunityResult({
      for (final entry in labels.entries) entry.key: mapping[entry.value]!,
    });
  }
}
