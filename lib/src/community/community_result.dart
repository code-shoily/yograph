/// A non-overlapping community partition.
///
/// Each node is assigned to exactly one community. The [assignments] map
/// stores `nodeId -> communityId` pairs. Community IDs are normalized to a
/// contiguous range `0 .. numCommunities - 1` by the detection algorithms.
class CommunityResult {
  /// Map from node ID to community ID.
  final Map<int, int> assignments;

  /// Optional metadata such as algorithm name or final modularity.
  final Map<String, Object?> metadata;

  /// Creates a community result from an assignments map.
  ///
  /// The map is copied defensively. [metadata] is optional.
  CommunityResult(Map<int, int> assignments, {Map<String, Object?>? metadata})
    : assignments = Map.unmodifiable(Map<int, int>.from(assignments)),
      metadata = Map.unmodifiable(Map<String, Object?>.from(metadata ?? {}));

  /// Number of distinct communities in [assignments].
  int get numCommunities => assignments.values.toSet().length;

  @override
  String toString() =>
      'CommunityResult(numCommunities: $numCommunities, '
      'assignments: $assignments)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityResult &&
          numCommunities == other.numCommunities &&
          _mapsEqual(assignments, other.assignments);

  @override
  int get hashCode => Object.hash(numCommunities, assignments);

  static bool _mapsEqual(Map<int, int> a, Map<int, int> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
