import '../model/roles.dart';
import 'community_dendrogram.dart';
import 'community_metrics.dart';
import 'community_result.dart';
import 'label_propagation.dart';
import 'leiden.dart';
import 'louvain.dart';
import 'walktrap.dart';

/// Community detection and clustering algorithms.
///
/// This facade exposes the detection algorithms and provides utility
/// functions for working with community partitions.
abstract final class Community {
  const Community._();

  // ---------------------------------------------------------------------------
  // Detection algorithms
  // ---------------------------------------------------------------------------

  /// Louvain community detection.
  static CommunityResult louvain<N, E>(
    Bidirectional<N, E> graph, {
    double resolution = 1.0,
    double minModularityGain = 1e-6,
    int maxIterations = 100,
    int? seed,
  }) => Louvain.detectWithOptions(
    graph,
    resolution: resolution,
    minModularityGain: minModularityGain,
    maxIterations: maxIterations,
    seed: seed,
  );

  /// Hierarchical Louvain detection.
  static CommunityDendrogram louvainHierarchical<N, E>(
    Bidirectional<N, E> graph, {
    double resolution = 1.0,
    double minModularityGain = 1e-6,
    int maxIterations = 100,
    int? seed,
  }) => Louvain.detectHierarchical(
    graph,
    resolution: resolution,
    minModularityGain: minModularityGain,
    maxIterations: maxIterations,
    seed: seed,
  );

  /// Leiden community detection.
  static CommunityResult leiden<N, E>(
    Bidirectional<N, E> graph, {
    double resolution = 1.0,
    double minModularityGain = 1e-6,
    int maxIterations = 100,
    int refinementIterations = 5,
    int? seed,
  }) => Leiden.detectWithOptions(
    graph,
    resolution: resolution,
    minModularityGain: minModularityGain,
    maxIterations: maxIterations,
    refinementIterations: refinementIterations,
    seed: seed,
  );

  /// Hierarchical Leiden detection.
  static CommunityDendrogram leidenHierarchical<N, E>(
    Bidirectional<N, E> graph, {
    double resolution = 1.0,
    double minModularityGain = 1e-6,
    int maxIterations = 100,
    int refinementIterations = 5,
    int? seed,
  }) => Leiden.detectHierarchical(
    graph,
    resolution: resolution,
    minModularityGain: minModularityGain,
    maxIterations: maxIterations,
    refinementIterations: refinementIterations,
    seed: seed,
  );

  /// Label Propagation community detection.
  static CommunityResult labelPropagation<N, E>(
    Bidirectional<N, E> graph, {
    int? seed,
    int maxIterations = 100,
  }) =>
      LabelPropagation.detect(graph, seed: seed, maxIterations: maxIterations);

  /// Walktrap community detection.
  static CommunityResult walktrap<N, E>(
    Bidirectional<N, E> graph, {
    int walkLength = 4,
    int? targetCommunities,
  }) => Walktrap.detectWithOptions(
    graph,
    walkLength: walkLength,
    targetCommunities: targetCommunities,
  );

  /// Hierarchical Walktrap detection.
  static CommunityDendrogram walktrapHierarchical<N, E>(
    Bidirectional<N, E> graph, {
    int walkLength = 4,
  }) => Walktrap.detectHierarchical(graph, walkLength: walkLength);

  // ---------------------------------------------------------------------------
  // Utility functions
  // ---------------------------------------------------------------------------

  /// Converts community assignments to a map of community ID → set of nodes.
  static Map<int, Set<int>> toMap(CommunityResult result) {
    final map = <int, Set<int>>{};
    for (final entry in result.assignments.entries) {
      map.putIfAbsent(entry.value, () => <int>{}).add(entry.key);
    }
    return map;
  }

  /// Returns the community ID with the largest number of nodes.
  ///
  /// Returns `null` if the result is empty.
  static int? largest(CommunityResult result) {
    if (result.assignments.isEmpty) return null;

    final sizes = Community.sizes(result);
    var largestComm = result.assignments.values.first;
    var largestSize = sizes[largestComm] ?? 0;

    for (final entry in sizes.entries) {
      if (entry.value > largestSize) {
        largestSize = entry.value;
        largestComm = entry.key;
      }
    }
    return largestComm;
  }

  /// Returns a map of community ID → size (number of nodes).
  static Map<int, int> sizes(CommunityResult result) {
    final sizes = <int, int>{};
    for (final comm in result.assignments.values) {
      sizes[comm] = (sizes[comm] ?? 0) + 1;
    }
    return sizes;
  }

  /// Returns all nodes belonging to [communityId].
  static Set<int> nodesIn(CommunityResult result, int communityId) => result
      .assignments
      .entries
      .where((e) => e.value == communityId)
      .map((e) => e.key)
      .toSet();

  /// Returns the community ID for [node], or `null` if not assigned.
  static int? forNode(CommunityResult result, int node) =>
      result.assignments[node];

  /// Merges [source] community into [target] community.
  static CommunityResult merge(CommunityResult result, int source, int target) {
    if (source == target) return result;

    final sourceExists = result.assignments.values.contains(source);
    if (!sourceExists) return result;

    final newAssignments = {
      for (final entry in result.assignments.entries)
        entry.key: entry.value == source ? target : entry.value,
    };

    return CommunityResult(
      newAssignments,
      metadata: Map<String, Object?>.from(result.metadata),
    );
  }

  // ---------------------------------------------------------------------------
  // Metric delegations
  // ---------------------------------------------------------------------------

  /// Modularity of [result] on [graph].
  static double modularity<N, E>(
    Bidirectional<N, E> graph,
    CommunityResult result, {
    double resolution = 1.0,
  }) => CommunityMetrics.modularity(graph, result, resolution: resolution);

  /// Total number of triangles in [graph].
  static int countTriangles<N, E>(Bidirectional<N, E> graph) =>
      CommunityMetrics.countTriangles(graph);

  /// Number of triangles each node participates in.
  static Map<int, int> trianglesPerNode<N, E>(Bidirectional<N, E> graph) =>
      CommunityMetrics.trianglesPerNode(graph);

  /// Local clustering coefficient of [node].
  static double clusteringCoefficient<N, E>(
    Bidirectional<N, E> graph,
    int node,
  ) => CommunityMetrics.clusteringCoefficient(graph, node);

  /// Average local clustering coefficient over all nodes.
  static double averageClusteringCoefficient<N, E>(Bidirectional<N, E> graph) =>
      CommunityMetrics.averageClusteringCoefficient(graph);

  /// Transitivity (global clustering coefficient) of [graph].
  static double transitivity<N, E>(Bidirectional<N, E> graph) =>
      CommunityMetrics.transitivity(graph);

  /// Graph density.
  static double density<N, E>(Bidirectional<N, E> graph) =>
      CommunityMetrics.density(graph);

  /// Density of edges within [communityId].
  static double communityDensity<N, E>(
    Bidirectional<N, E> graph,
    CommunityResult result,
    int communityId,
  ) => CommunityMetrics.communityDensity(
    graph,
    Community.nodesIn(result, communityId),
  );

  /// Average density across all communities.
  static double averageCommunityDensity<N, E>(
    Bidirectional<N, E> graph,
    CommunityResult result,
  ) => CommunityMetrics.averageCommunityDensity(graph, result);

  /// Normalized Mutual Information between two partitions.
  static double nmi(Map<int, int> detected, Map<int, int> truth) =>
      CommunityMetrics.nmi(detected, truth);
}
