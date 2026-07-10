import 'dart:math';

import '../model/roles.dart';
import '../simple_graph.dart';
import 'community_dendrogram.dart';
import 'community_result.dart';

/// Louvain method for community detection.
///
/// A fast hierarchical algorithm that optimizes modularity. It alternates
/// between local optimization (moving nodes to neighbor communities) and
/// aggregation (communities become super-nodes) until no improvement.
///
/// **Graph Assumptions:**
/// - This algorithm assumes and is designed for **undirected graphs**.
/// - If a directed graph is passed, it will be treated as undirected. Specifically,
///   all edges are treated as undirected, and the aggregation step collapses edges
///   between communities symmetrically, returning an undirected representation of the
///   aggregated graph.
abstract final class Louvain {
  const Louvain._();

  /// Detects communities with custom options.
  static CommunityResult detect<N, E>(
    Bidirectional<N, E> graph, {
    double resolution = 1.0,
    double minModularityGain = 1e-6,
    int maxIterations = 100,
    int? seed,
  }) => detectWithOptions(
    graph,
    resolution: resolution,
    minModularityGain: minModularityGain,
    maxIterations: maxIterations,
    seed: seed,
  );

  /// Detects communities with custom options.
  ///
  /// Options:
  /// - [resolution]: resolution parameter gamma (default 1.0)
  /// - [minModularityGain]: stop when gain is below this threshold
  /// - [maxIterations]: maximum passes per phase
  /// - [seed]: random seed for node ordering tie-breaking
  static CommunityResult detectWithOptions<N, E>(
    Bidirectional<N, E> graph, {
    double resolution = 1.0,
    double minModularityGain = 1e-6,
    int maxIterations = 100,
    int? seed,
  }) {
    final result = _detectWithStats(
      graph,
      resolution: resolution,
      minModularityGain: minModularityGain,
      maxIterations: maxIterations,
      seed: seed ?? 42,
    );
    return result;
  }

  /// Hierarchical detection returning a [CommunityDendrogram].
  static CommunityDendrogram detectHierarchical<N, E>(
    Bidirectional<N, E> graph, {
    double resolution = 1.0,
    double minModularityGain = 1e-6,
    int maxIterations = 100,
    int? seed,
  }) {
    final options = _LouvainOptions(
      resolution: resolution,
      minModularityGain: minModularityGain,
      maxIterations: maxIterations,
      seed: seed ?? 42,
    );
    final nodes = graph.nodeIds.toList();
    final state = _initialState(graph, nodes);
    return _doLouvainHierarchical(graph, state, [], 0, options);
  }

  // ---------------------------------------------------------------------------
  // Internal algorithm
  // ---------------------------------------------------------------------------

  static CommunityResult _detectWithStats<N, E>(
    Bidirectional<N, E> graph, {
    required double resolution,
    required double minModularityGain,
    required int maxIterations,
    required int seed,
  }) {
    final options = _LouvainOptions(
      resolution: resolution,
      minModularityGain: minModularityGain,
      maxIterations: maxIterations,
      seed: seed,
    );
    final nodes = graph.nodeIds.toList();
    final state = _initialState(graph, nodes);

    final (assignments, _) = _doLouvain(graph, state, 0, options);
    return CommunityResult(_normalizeAssignments(assignments));
  }

  static (Map<int, int>, bool) _doLouvain<N, E>(
    Bidirectional<N, E> graph,
    _LouvainState state,
    int phase,
    _LouvainOptions options,
  ) {
    final (improvedAfterLocal, stateAfterLocal) = _phase1LocalOptimize(
      graph,
      state,
      options,
    );

    final normalizedAssignments = _normalizeAssignments(
      stateAfterLocal.assignments,
    );
    final numComms = normalizedAssignments.values.toSet().length;

    if (!improvedAfterLocal ||
        phase >= options.maxIterations ||
        numComms <= 1) {
      return (normalizedAssignments, improvedAfterLocal);
    }

    final aggregated = _phase2Aggregate(graph, normalizedAssignments);
    final newState = _rebuildState(aggregated);

    final (aggAssignments, _) = _doLouvain(
      aggregated,
      newState,
      phase + 1,
      options,
    );

    final finalAssignments = <int, int>{};
    for (final entry in normalizedAssignments.entries) {
      final node = entry.key;
      final comm = entry.value;
      finalAssignments[node] = aggAssignments[comm] ?? comm;
    }

    return (finalAssignments, true);
  }

  static CommunityDendrogram _doLouvainHierarchical<N, E>(
    Bidirectional<N, E> graph,
    _LouvainState state,
    List<CommunityResult> levels,
    int phase,
    _LouvainOptions options,
  ) {
    final (improvedAfterLocal, stateAfterLocal) = _phase1LocalOptimize(
      graph,
      state,
      options,
    );

    final normalizedAssignments = _normalizeAssignments(
      stateAfterLocal.assignments,
    );
    final currentResult = CommunityResult(normalizedAssignments);
    final newLevels = [...levels, currentResult];

    final numComms = normalizedAssignments.values.toSet().length;

    if (!improvedAfterLocal ||
        phase >= options.maxIterations ||
        numComms <= 1) {
      return CommunityDendrogram(newLevels);
    }

    final aggregated = _phase2Aggregate(graph, normalizedAssignments);
    final newState = _rebuildState(aggregated);

    return _doLouvainHierarchical(
      aggregated,
      newState,
      newLevels,
      phase + 1,
      options,
    );
  }

  // ---------------------------------------------------------------------------
  // Phase 1: local optimization
  // ---------------------------------------------------------------------------

  static (bool, _LouvainState) _phase1LocalOptimize<N, E>(
    Bidirectional<N, E> graph,
    _LouvainState state,
    _LouvainOptions options,
  ) {
    final nodes = state.assignments.keys.toList();
    return _doPhase1Iterations(graph, state, nodes, false, 0, options);
  }

  static (bool, _LouvainState) _doPhase1Iterations<N, E>(
    Bidirectional<N, E> graph,
    _LouvainState state,
    List<int> nodes,
    bool improved,
    int iteration,
    _LouvainOptions options,
  ) {
    if (iteration >= options.maxIterations) return (improved, state);

    final (newState, localImproved) = _doPhase1Pass(
      graph,
      state,
      nodes,
      options,
    );

    if (localImproved) {
      return _doPhase1Iterations(
        graph,
        newState,
        nodes,
        true,
        iteration + 1,
        options,
      );
    }
    return (improved, newState);
  }

  static (_LouvainState, bool) _doPhase1Pass<N, E>(
    Bidirectional<N, E> graph,
    _LouvainState state,
    List<int> nodes,
    _LouvainOptions options,
  ) {
    final random = Random(options.seed + state.assignments.length);
    final shuffled = List<int>.from(nodes)..shuffle(random);

    var currentState = state;
    var anyImproved = false;

    for (final node in shuffled) {
      final currentComm = currentState.assignments[node] ?? node;
      final nodeWeight = currentState.nodeWeights[node] ?? 0.0;
      final neighborWeights = _neighborWeightsByComm(graph, currentState, node);
      final kiInCurrent = neighborWeights[currentComm] ?? 0.0;

      var bestComm = currentComm;
      var bestGain = 0.0;

      for (final neighborComm in neighborWeights.keys) {
        if (neighborComm == currentComm) continue;
        final kiInTarget = neighborWeights[neighborComm] ?? 0.0;
        final gain = _modularityGainFast(
          nodeWeight,
          kiInCurrent,
          kiInTarget,
          currentComm,
          neighborComm,
          currentState,
          options.resolution,
        );
        if (gain > bestGain) {
          bestComm = neighborComm;
          bestGain = gain;
        }
      }

      if (bestGain > options.minModularityGain && bestComm != currentComm) {
        currentState = _moveNode(
          currentState,
          node,
          currentComm,
          bestComm,
          nodeWeight,
        );
        anyImproved = true;
      }
    }

    return (currentState, anyImproved);
  }

  static Map<int, double> _neighborWeightsByComm<N, E>(
    Bidirectional<N, E> graph,
    _LouvainState state,
    int node,
  ) {
    final result = <int, double>{};
    for (final neighbor in graph.successors(node)) {
      final comm = state.assignments[neighbor] ?? neighbor;
      final weight = graph.edgeWeight(node, neighbor);
      result[comm] = (result[comm] ?? 0.0) + weight;
    }
    return result;
  }

  static double _modularityGainFast(
    double nodeWeight,
    double kiInCurrent,
    double kiInTarget,
    int currentComm,
    int targetComm,
    _LouvainState state,
    double gamma,
  ) {
    if (currentComm == targetComm) return 0.0;

    final ki = nodeWeight;
    final m = state.totalWeight;
    if (m == 0.0) return 0.0;

    final sigmaTotTarget = state.communityTotals[targetComm] ?? 0.0;
    final sigmaTotCurrent = state.communityTotals[currentComm] ?? 0.0;

    // Directed modularity gain. For undirected graphs the edge weights are
    // interpreted as directed weights (each undirected edge counts twice),
    // which is equivalent to the standard undirected formulation.
    return (kiInTarget - kiInCurrent) / m -
        gamma * ki * (sigmaTotTarget - sigmaTotCurrent + ki) / (m * m);
  }

  static _LouvainState _moveNode(
    _LouvainState state,
    int node,
    int fromComm,
    int toComm,
    double nodeWeight,
  ) {
    final newAssignments = Map<int, int>.from(state.assignments)
      ..[node] = toComm;
    final newTotals = Map<int, double>.from(state.communityTotals)
      ..update(fromComm, (v) => v - nodeWeight, ifAbsent: () => -nodeWeight)
      ..update(toComm, (v) => v + nodeWeight, ifAbsent: () => nodeWeight);

    return _LouvainState(
      assignments: newAssignments,
      nodeWeights: state.nodeWeights,
      communityTotals: newTotals,
      totalWeight: state.totalWeight,
    );
  }

  // ---------------------------------------------------------------------------
  // Phase 2: aggregation
  // ---------------------------------------------------------------------------

  static SimpleGraph<N, double> _phase2Aggregate<N, E>(
    Bidirectional<N, E> graph,
    Map<int, int> assignments,
  ) {
    final communities = <int, Set<int>>{};
    for (final entry in assignments.entries) {
      communities.putIfAbsent(entry.value, () => <int>{}).add(entry.key);
    }

    final newGraph = SimpleGraph<N, double>.undirected();
    for (final comm in communities.keys) {
      newGraph.addNode(comm);
    }

    final edgeWeights = <(int, int), double>{};
    for (final u in graph.nodeIds) {
      final commU = assignments[u] ?? u;
      for (final v in graph.successors(u)) {
        final commV = assignments[v] ?? v;
        final key = commU <= commV ? (commU, commV) : (commV, commU);
        final weight = graph.edgeWeight(u, v);
        edgeWeights[key] = (edgeWeights[key] ?? 0.0) + weight;
      }
    }

    for (final entry in edgeWeights.entries) {
      final (u, v) = entry.key;
      newGraph.addEdge(u, v, data: entry.value);
    }

    return newGraph;
  }

  // ---------------------------------------------------------------------------
  // State helpers
  // ---------------------------------------------------------------------------

  static _LouvainState _initialState<N, E>(
    Bidirectional<N, E> graph,
    List<int> nodes,
  ) {
    final assignments = <int, int>{
      for (var i = 0; i < nodes.length; i++) nodes[i]: i,
    };
    final nodeWeights = _calculateNodeWeights(graph);
    final communityTotals = _calculateCommunityTotals(assignments, nodeWeights);
    final totalWeight = _calculateTotalWeight(graph);

    return _LouvainState(
      assignments: assignments,
      nodeWeights: nodeWeights,
      communityTotals: communityTotals,
      totalWeight: totalWeight,
    );
  }

  static _LouvainState _rebuildState(Bidirectional<dynamic, double> graph) {
    final nodes = graph.nodeIds.toList();
    return _initialState(graph, nodes);
  }

  static Map<int, double> _calculateNodeWeights<N, E>(
    Bidirectional<N, E> graph,
  ) {
    final result = <int, double>{};
    for (final node in graph.nodeIds) {
      var sum = 0.0;
      for (final neighbor in graph.successors(node)) {
        sum += graph.edgeWeight(node, neighbor);
      }
      result[node] = sum;
    }
    return result;
  }

  static Map<int, double> _calculateCommunityTotals(
    Map<int, int> assignments,
    Map<int, double> nodeWeights,
  ) {
    final result = <int, double>{};
    for (final entry in assignments.entries) {
      final node = entry.key;
      final comm = entry.value;
      result[comm] = (result[comm] ?? 0.0) + (nodeWeights[node] ?? 0.0);
    }
    return result;
  }

  static double _calculateTotalWeight<N, E>(Bidirectional<N, E> graph) {
    var total = 0.0;
    for (final node in graph.nodeIds) {
      for (final neighbor in graph.successors(node)) {
        total += graph.edgeWeight(node, neighbor);
      }
    }
    return total;
  }

  static Map<int, int> _normalizeAssignments(Map<int, int> assignments) {
    final unique = assignments.values.toSet().toList()..sort();
    final mapping = <int, int>{
      for (var i = 0; i < unique.length; i++) unique[i]: i,
    };
    return {
      for (final entry in assignments.entries) entry.key: mapping[entry.value]!,
    };
  }
}

class _LouvainOptions {
  final double resolution;
  final double minModularityGain;
  final int maxIterations;
  final int seed;

  _LouvainOptions({
    required this.resolution,
    required this.minModularityGain,
    required this.maxIterations,
    required this.seed,
  });
}

class _LouvainState {
  final Map<int, int> assignments;
  final Map<int, double> nodeWeights;
  final Map<int, double> communityTotals;
  final double totalWeight;

  _LouvainState({
    required this.assignments,
    required this.nodeWeights,
    required this.communityTotals,
    required this.totalWeight,
  });
}
