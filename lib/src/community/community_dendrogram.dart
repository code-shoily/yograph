import 'community_result.dart';

/// A hierarchical community structure produced by algorithms such as
/// [Louvain] or [Walktrap].
///
/// Levels are ordered from finest (most communities) to coarsest (fewest
/// communities). Each level is a [CommunityResult] whose assignments are over
/// the graph at that aggregation depth.
class CommunityDendrogram {
  /// Levels ordered finest → coarsest.
  final List<CommunityResult> levels;

  /// Optional metadata.
  final Map<String, Object?> metadata;

  /// Creates a dendrogram from a list of levels.
  ///
  /// The list is copied defensively.
  CommunityDendrogram(
    List<CommunityResult> levels, {
    Map<String, Object?>? metadata,
  }) : levels = List.unmodifiable(List<CommunityResult>.from(levels)),
       metadata = Map.unmodifiable(Map<String, Object?>.from(metadata ?? {}));

  /// The finest partition (most communities).
  CommunityResult get finest =>
      levels.isNotEmpty ? levels.first : CommunityResult({});

  /// The coarsest partition (fewest communities).
  CommunityResult get coarsest =>
      levels.isNotEmpty ? levels.last : CommunityResult({});

  /// Number of hierarchical levels.
  int get numLevels => levels.length;

  /// Returns the level with at most [n] communities, or `null` if none.
  CommunityResult? atLevel(int n) => levels.cast<CommunityResult?>().firstWhere(
    (level) => level!.numCommunities <= n,
    orElse: () => null,
  );

  /// Returns the level at [index], or `null` if out of bounds.
  CommunityResult? getLevel(int index) =>
      index >= 0 && index < levels.length ? levels[index] : null;

  /// Composes all levels into a single [CommunityResult] keyed by original
  /// node IDs.
  ///
  /// The first level maps original nodes to first-level communities; each
  /// subsequent level maps communities to coarser communities. This method
  /// follows the chain down to the final community ID for every original node.
  CommunityResult flattenToOriginal() {
    if (levels.isEmpty) return CommunityResult({});

    var assignments = Map<int, int>.from(levels.first.assignments);
    for (var i = 1; i < levels.length; i++) {
      final level = levels[i];
      assignments = assignments.map(
        (node, comm) => MapEntry(node, level.assignments[comm] ?? comm),
      );
    }
    return CommunityResult(assignments);
  }

  @override
  String toString() =>
      'CommunityDendrogram(numLevels: $numLevels, levels: $levels)';
}
