import 'dart:math';

import '../model/graph_kind.dart';
import '../model/roles.dart';
import 'community_result.dart';

/// Quality metrics and graph statistics for community detection.
///
/// Provides modularity, triangle counts, clustering coefficients, transitivity,
/// density, and partition comparison (NMI).
abstract final class CommunityMetrics {
  const CommunityMetrics._();

  // ---------------------------------------------------------------------------
  // Modularity
  // ---------------------------------------------------------------------------

  /// Calculates modularity for a given [result] partition.
  ///
  /// Modularity measures the quality of a division of a network into modules.
  /// Values typically range from [-0.5, 1.0]; values > 0.3 indicate significant
  /// community structure.
  ///
  /// The [resolution] parameter (gamma) controls the size of communities.
  /// Supports both undirected and directed graphs.
  static double modularity<N, E>(
    Bidirectional<N, E> graph,
    CommunityResult result, {
    double resolution = 1.0,
  }) {
    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) return 0.0;

    final totalWeight = _totalEdgeWeight(graph);
    if (totalWeight == 0.0) return 0.0;

    final m = graph.kind == GraphKind.undirected
        ? totalWeight / 2.0
        : totalWeight;
    final communities = _groupByCommunityToSet(result.assignments);

    var q = 0.0;
    for (final entry in communities.entries) {
      final nodeSet = entry.value;
      if (nodeSet.isEmpty) continue;

      var internalWeight = 0.0;
      for (final node in nodeSet) {
        for (final neighbor in graph.successors(node)) {
          if (nodeSet.contains(neighbor)) {
            internalWeight += graph.edgeWeight(node, neighbor);
          }
        }
      }

      final term1 = graph.kind == GraphKind.undirected
          ? internalWeight / 2.0 / m
          : internalWeight / m;

      final term2 = graph.kind == GraphKind.undirected
          ? _undirectedModularityTerm(graph, nodeSet, m, resolution)
          : _directedModularityTerm(graph, nodeSet, m, resolution);

      q += term1 - term2;
    }
    return q;
  }

  static double _undirectedModularityTerm<N, E>(
    Bidirectional<N, E> graph,
    Set<int> nodeSet,
    double m,
    double gamma,
  ) {
    var degreeSum = 0.0;
    for (final node in nodeSet) {
      for (final neighbor in graph.successors(node)) {
        degreeSum += graph.edgeWeight(node, neighbor);
      }
    }
    return gamma * pow(degreeSum / (2.0 * m), 2);
  }

  static double _directedModularityTerm<N, E>(
    Bidirectional<N, E> graph,
    Set<int> nodeSet,
    double m,
    double gamma,
  ) {
    var inDegreeSum = 0.0;
    var outDegreeSum = 0.0;
    for (final node in nodeSet) {
      for (final neighbor in graph.successors(node)) {
        outDegreeSum += graph.edgeWeight(node, neighbor);
      }
      for (final neighbor in graph.predecessors(node)) {
        inDegreeSum += graph.edgeWeight(neighbor, node);
      }
    }
    return gamma * (inDegreeSum * outDegreeSum / (m * m));
  }

  // ---------------------------------------------------------------------------
  // Triangles
  // ---------------------------------------------------------------------------

  /// Counts the total number of triangles in an undirected graph.
  ///
  /// Each triangle is counted exactly once. For directed graphs, the
  /// underlying undirected adjacency is used.
  static int countTriangles<N, E>(Bidirectional<N, E> graph) {
    final neighborSets = _neighborSets(graph);
    final nodes = graph.nodeIds.toList()..sort();

    var count = 0;
    for (final u in nodes) {
      final uNeighbors = neighborSets[u]!;
      for (final v in uNeighbors.where((x) => x > u)) {
        final vNeighbors = neighborSets[v]!;
        for (final w in vNeighbors.where((x) => x > v)) {
          if (uNeighbors.contains(w)) count++;
        }
      }
    }
    return count;
  }

  /// Returns the number of triangles each node participates in.
  static Map<int, int> trianglesPerNode<N, E>(Bidirectional<N, E> graph) {
    final neighborSets = _neighborSets(graph);
    final result = <int, int>{};

    for (final node in graph.nodeIds) {
      final neighbors = neighborSets[node]!.toList()..sort();
      var count = 0;
      for (var i = 0; i < neighbors.length; i++) {
        final a = neighbors[i];
        final aNeighbors = neighborSets[a]!;
        for (var j = i + 1; j < neighbors.length; j++) {
          final b = neighbors[j];
          if (aNeighbors.contains(b)) count++;
        }
      }
      result[node] = count;
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Clustering coefficients
  // ---------------------------------------------------------------------------

  /// Local clustering coefficient of [node].
  ///
  /// Measures how close the node's neighbors are to forming a complete clique.
  /// Range: [0.0, 1.0]. Returns 0.0 for nodes with fewer than two neighbors.
  static double clusteringCoefficient<N, E>(
    Bidirectional<N, E> graph,
    int node,
  ) {
    final neighbors = graph.successors(node).toList();
    final k = neighbors.length;
    if (k < 2) return 0.0;

    var edges = 0;
    for (var i = 0; i < neighbors.length; i++) {
      final a = neighbors[i];
      for (var j = i + 1; j < neighbors.length; j++) {
        final b = neighbors[j];
        if (graph.hasEdge(a, b)) edges++;
      }
    }
    return 2.0 * edges / (k * (k - 1));
  }

  /// Average local clustering coefficient over all nodes.
  static double averageClusteringCoefficient<N, E>(Bidirectional<N, E> graph) {
    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) return 0.0;

    var total = 0.0;
    for (final node in nodes) {
      total += clusteringCoefficient(graph, node);
    }
    return total / nodes.length;
  }

  /// Transitivity (global clustering coefficient) of the graph.
  ///
  /// Formula: `3 × triangles / connected_triples`.
  static double transitivity<N, E>(Bidirectional<N, E> graph) {
    final neighborSets = _neighborSets(graph);
    final nodes = graph.nodeIds.toList()..sort();

    var triples = 0;
    var triangles = 0;

    for (final u in nodes) {
      final uNeighbors = neighborSets[u]!;
      final k = uNeighbors.length;
      triples += (k * (k - 1)) ~/ 2;

      for (final v in uNeighbors.where((x) => x > u)) {
        final vNeighbors = neighborSets[v]!;
        for (final w in vNeighbors.where((x) => x > v)) {
          if (uNeighbors.contains(w)) triangles++;
        }
      }
    }

    if (triples == 0) return 0.0;
    return 3.0 * triangles / triples;
  }

  // ---------------------------------------------------------------------------
  // Density
  // ---------------------------------------------------------------------------

  /// Graph density: ratio of actual edges to possible edges.
  static double density<N, E>(Bidirectional<N, E> graph) {
    final n = graph.nodeCount;
    if (n < 2) return 0.0;

    final m = _edgeCountUndirected(graph);
    return 2.0 * m / (n * (n - 1));
  }

  /// Density of edges within a specific set of [nodes].
  static double communityDensity<N, E>(
    Bidirectional<N, E> graph,
    Set<int> nodes,
  ) {
    final n = nodes.length;
    if (n < 2) return 0.0;

    var internalEdges = 0;
    for (final u in nodes) {
      for (final v in graph.successors(u)) {
        if (u < v && nodes.contains(v)) internalEdges++;
      }
    }
    return 2.0 * internalEdges / (n * (n - 1));
  }

  /// Average density across all communities in [result].
  static double averageCommunityDensity<N, E>(
    Bidirectional<N, E> graph,
    CommunityResult result,
  ) {
    final communities = _groupByCommunityToSet(result.assignments);
    if (communities.isEmpty) return 0.0;

    var total = 0.0;
    for (final nodes in communities.values) {
      total += communityDensity(graph, nodes);
    }
    return total / communities.length;
  }

  // ---------------------------------------------------------------------------
  // Partition comparison
  // ---------------------------------------------------------------------------

  /// Normalized Mutual Information between two partitions.
  ///
  /// Range: [0.0, 1.0], where 1.0 means perfect agreement.
  static double nmi(Map<int, int> detected, Map<int, int> truth) {
    final nodes = truth.keys.toList();
    final n = nodes.length;
    if (n == 0) return 0.0;

    final detectedCommunities = _groupByCommunity(detected);
    final truthCommunities = _groupByCommunity(truth);

    final hDetected = _entropy(detectedCommunities, n);
    final hTruth = _entropy(truthCommunities, n);
    final mi = _mutualInformation(detectedCommunities, truthCommunities, n);

    final denominator = hDetected + hTruth;
    if (denominator == 0.0) return 1.0;
    return 2.0 * mi / denominator;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  static double _totalEdgeWeight<N, E>(Bidirectional<N, E> graph) {
    var total = 0.0;
    for (final node in graph.nodeIds) {
      for (final neighbor in graph.successors(node)) {
        total += graph.edgeWeight(node, neighbor);
      }
    }
    return total;
  }

  static int _edgeCountUndirected<N, E>(Bidirectional<N, E> graph) {
    var count = 0;
    for (final node in graph.nodeIds) {
      for (final neighbor in graph.successors(node)) {
        if (node <= neighbor) count++;
      }
    }
    return count;
  }

  static Map<int, Set<int>> _neighborSets<N, E>(Bidirectional<N, E> graph) {
    final result = <int, Set<int>>{};
    for (final node in graph.nodeIds) {
      final neighbors = <int>{};
      for (final neighbor in graph.successors(node)) {
        neighbors.add(neighbor);
      }
      if (graph.kind == GraphKind.directed) {
        for (final neighbor in graph.predecessors(node)) {
          neighbors.add(neighbor);
        }
      }
      result[node] = neighbors;
    }
    return result;
  }

  static Map<int, Set<int>> _groupByCommunityToSet(Map<int, int> assignments) {
    final result = <int, Set<int>>{};
    for (final entry in assignments.entries) {
      result.putIfAbsent(entry.value, () => <int>{}).add(entry.key);
    }
    return result;
  }

  static Map<int, List<int>> _groupByCommunity(Map<int, int> assignments) {
    final result = <int, List<int>>{};
    for (final entry in assignments.entries) {
      result.putIfAbsent(entry.value, () => []).add(entry.key);
    }
    return result;
  }

  static double _entropy(Map<int, List<int>> communities, int n) {
    var entropy = 0.0;
    for (final members in communities.values) {
      final p = members.length / n;
      if (p > 0) entropy -= p * log(p) / log(2);
    }
    return entropy;
  }

  static double _mutualInformation(
    Map<int, List<int>> detected,
    Map<int, List<int>> truth,
    int n,
  ) {
    final truthSets = {
      for (final entry in truth.entries) entry.key: Set<int>.from(entry.value),
    };

    var mi = 0.0;
    for (final dMembers in detected.values) {
      final dSet = Set<int>.from(dMembers);
      final pD = dMembers.length / n;
      for (final entry in truthSets.entries) {
        final overlap = dSet.intersection(entry.value).length;
        if (overlap == 0) continue;

        final pDt = overlap / n;
        final pT = entry.value.length / n;
        mi += pDt * log(pDt / (pD * pT)) / log(2);
      }
    }
    return mi;
  }
}
