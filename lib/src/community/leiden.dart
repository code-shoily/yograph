import 'dart:math';

import '../model/roles.dart';
import '../simple_graph.dart';
import 'community_dendrogram.dart';
import 'community_result.dart';

/// Leiden algorithm for community detection.
///
/// An improvement over the Louvain algorithm that guarantees well-connected
/// communities by adding a refinement step between local optimization and
/// aggregation.
abstract final class Leiden {
  const Leiden._();

  /// Detects communities with custom options.
  static CommunityResult detect<N, E>(
    Bidirectional<N, E> graph, {
    double resolution = 1.0,
    double minModularityGain = 1e-6,
    int maxIterations = 100,
    int refinementIterations = 5,
    int? seed,
  }) => detectWithOptions(
    graph,
    resolution: resolution,
    minModularityGain: minModularityGain,
    maxIterations: maxIterations,
    refinementIterations: refinementIterations,
    seed: seed,
  );

  /// Detects communities with custom options.
  ///
  /// Options:
  /// - [resolution]: resolution parameter gamma (default 1.0)
  /// - [minModularityGain]: stop when gain is below this threshold
  /// - [maxIterations]: maximum passes per phase
  /// - [refinementIterations]: refinement passes per community
  /// - [seed]: random seed
  static CommunityResult detectWithOptions<N, E>(
    Bidirectional<N, E> graph, {
    double resolution = 1.0,
    double minModularityGain = 1e-6,
    int maxIterations = 100,
    int refinementIterations = 5,
    int? seed,
  }) {
    final options = _LeidenOptions(
      resolution: resolution,
      minModularityGain: minModularityGain,
      maxIterations: maxIterations,
      refinementIterations: refinementIterations,
      seed: seed ?? 42,
    );

    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) return CommunityResult({});
    if (nodes.length == 1) return CommunityResult({nodes.first: 0});

    final state = _initialState(graph, nodes);
    final (assignments, _) = _doLeiden(graph, state, 0, options);
    return CommunityResult(_normalizeAssignments(assignments));
  }

  /// Hierarchical detection returning a [CommunityDendrogram].
  static CommunityDendrogram detectHierarchical<N, E>(
    Bidirectional<N, E> graph, {
    double resolution = 1.0,
    double minModularityGain = 1e-6,
    int maxIterations = 100,
    int refinementIterations = 5,
    int? seed,
  }) {
    final options = _LeidenOptions(
      resolution: resolution,
      minModularityGain: minModularityGain,
      maxIterations: maxIterations,
      refinementIterations: refinementIterations,
      seed: seed ?? 42,
    );

    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) return CommunityDendrogram([]);
    if (nodes.length == 1) {
      return CommunityDendrogram([
        CommunityResult({nodes.first: 0}),
      ]);
    }

    final state = _initialState(graph, nodes);
    return _doLeidenHierarchical(graph, state, [], 0, options);
  }

  // ---------------------------------------------------------------------------
  // Main Leiden loop
  // ---------------------------------------------------------------------------

  static (Map<int, int>, bool) _doLeiden<N, E>(
    Bidirectional<N, E> graph,
    _LeidenState state,
    int iteration,
    _LeidenOptions options,
  ) {
    if (iteration >= options.maxIterations) {
      return (state.assignments, false);
    }

    final (improvedAfterLocal, stateAfterLocal) = _phase1LocalOptimize(
      graph,
      state,
      options,
    );
    final stateAfterRefinement = _phaseRefinement(
      graph,
      stateAfterLocal,
      options,
    );

    final normalizedAssignments = _normalizeAssignments(
      stateAfterRefinement.assignments,
    );
    final newNumComms = normalizedAssignments.values.toSet().length;
    final oldNumComms = state.assignments.values.toSet().length;
    final converged = newNumComms == oldNumComms && !improvedAfterLocal;

    if (converged || newNumComms <= 1) {
      return (normalizedAssignments, improvedAfterLocal);
    }

    final aggregated = _phase2Aggregate(graph, normalizedAssignments);

    final newState = _rebuildState(aggregated);
    final (aggAssignments, _) = _doLeiden(
      aggregated,
      newState,
      iteration + 1,
      options,
    );

    final composedAssignments = <int, int>{};
    for (final entry in normalizedAssignments.entries) {
      final node = entry.key;
      final comm = entry.value;
      composedAssignments[node] = aggAssignments[comm] ?? comm;
    }

    return (composedAssignments, true);
  }

  static CommunityDendrogram _doLeidenHierarchical<N, E>(
    Bidirectional<N, E> graph,
    _LeidenState state,
    List<CommunityResult> levels,
    int iteration,
    _LeidenOptions options,
  ) {
    if (iteration >= options.maxIterations) {
      return CommunityDendrogram(levels);
    }

    final (improvedAfterLocal, stateAfterLocal) = _phase1LocalOptimize(
      graph,
      state,
      options,
    );
    final stateAfterRefinement = _phaseRefinement(
      graph,
      stateAfterLocal,
      options,
    );

    final normalizedAssignments = _normalizeAssignments(
      stateAfterRefinement.assignments,
    );
    final currentResult = CommunityResult(normalizedAssignments);
    final newLevels = [...levels, currentResult];

    final newNumComms = normalizedAssignments.values.toSet().length;
    final oldNumComms = state.assignments.values.toSet().length;
    final converged =
        (newNumComms == oldNumComms && !improvedAfterLocal) || newNumComms <= 1;

    if (converged) return CommunityDendrogram(newLevels);

    final aggregated = _phase2Aggregate(graph, normalizedAssignments);
    final newState = _rebuildState(aggregated);
    return _doLeidenHierarchical(
      aggregated,
      newState,
      newLevels,
      iteration + 1,
      options,
    );
  }

  // ---------------------------------------------------------------------------
  // Phase 1: local optimization (same as Louvain)
  // ---------------------------------------------------------------------------

  static (bool, _LeidenState) _phase1LocalOptimize<N, E>(
    Bidirectional<N, E> graph,
    _LeidenState state,
    _LeidenOptions options,
  ) {
    final nodes = state.assignments.keys.toList();
    return _doPhase1Iterations(graph, state, nodes, false, 0, options);
  }

  static (bool, _LeidenState) _doPhase1Iterations<N, E>(
    Bidirectional<N, E> graph,
    _LeidenState state,
    List<int> nodes,
    bool improved,
    int iteration,
    _LeidenOptions options,
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

  static (_LeidenState, bool) _doPhase1Pass<N, E>(
    Bidirectional<N, E> graph,
    _LeidenState state,
    List<int> nodes,
    _LeidenOptions options,
  ) {
    final random = Random(options.seed + state.assignments.length);
    final shuffled = List<int>.from(nodes)..shuffle(random);

    var currentState = state;
    var anyImproved = false;

    for (final node in shuffled) {
      final currentComm = currentState.assignments[node] ?? node;
      final nodeWeight = currentState.nodeWeights[node] ?? 0.0;
      final neighborComms = _getNeighborCommunities(graph, currentState, node);

      var bestComm = currentComm;
      var bestGain = 0.0;

      for (final neighborComm in neighborComms) {
        if (neighborComm == currentComm) continue;
        final gain = _modularityGain(
          graph,
          node,
          currentComm,
          neighborComm,
          nodeWeight,
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

  static Set<int> _getNeighborCommunities<N, E>(
    Bidirectional<N, E> graph,
    _LeidenState state,
    int node,
  ) {
    final result = <int>{};
    for (final neighbor in graph.successors(node)) {
      result.add(state.assignments[neighbor] ?? neighbor);
    }
    return result;
  }

  static double _modularityGain<N, E>(
    Bidirectional<N, E> graph,
    int node,
    int currentComm,
    int targetComm,
    double nodeWeight,
    _LeidenState state,
    double gamma,
  ) {
    if (currentComm == targetComm) return 0.0;

    final ki = nodeWeight;
    final m = state.totalWeight;
    if (m == 0.0) return 0.0;

    final kiInTarget = _kiIn(graph, state, node, targetComm);
    final sigmaTotTarget = state.communityTotals[targetComm] ?? 0.0;
    final kiInCurrent = _kiIn(graph, state, node, currentComm);
    final sigmaTotCurrent = state.communityTotals[currentComm] ?? 0.0;

    // Directed modularity gain. For undirected graphs the edge weights are
    // interpreted as directed weights, which is equivalent to the standard
    // undirected formulation.
    return (kiInTarget - kiInCurrent) / m -
        gamma * ki * (sigmaTotTarget - sigmaTotCurrent + ki) / (m * m);
  }

  static double _kiIn<N, E>(
    Bidirectional<N, E> graph,
    _LeidenState state,
    int node,
    int targetComm,
  ) {
    var sum = 0.0;
    for (final neighbor in graph.successors(node)) {
      final comm = state.assignments[neighbor] ?? neighbor;
      if (comm == targetComm) {
        sum += graph.edgeWeight(node, neighbor);
      }
    }
    return sum;
  }

  static _LeidenState _moveNode(
    _LeidenState state,
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

    return _LeidenState(
      assignments: newAssignments,
      nodeWeights: state.nodeWeights,
      communityTotals: newTotals,
      totalWeight: state.totalWeight,
    );
  }

  // ---------------------------------------------------------------------------
  // Refinement phase
  // ---------------------------------------------------------------------------

  static _LeidenState _phaseRefinement<N, E>(
    Bidirectional<N, E> graph,
    _LeidenState state,
    _LeidenOptions options,
  ) {
    final nodes = state.assignments.keys.toList();
    final refinedAssignments = <int, int>{for (final n in nodes) n: n};
    final refinedTotals = Map<int, double>.from(state.nodeWeights);
    final refinedSizes = <int, int>{for (final n in nodes) n: 1};

    final coarseCommunities = _groupByCommunity(state.assignments);

    var currentAssignments = refinedAssignments;
    var currentTotals = refinedTotals;
    var currentSizes = refinedSizes;

    for (var pass = 0; pass < options.refinementIterations; pass++) {
      var changed = false;

      for (final nodesInC in coarseCommunities.values) {
        if (nodesInC.length <= 1) continue;

        final nodeList = nodesInC.toList();
        final random = Random(options.seed + pass + nodesInC.length);
        final shuffled = List<int>.from(nodeList)..shuffle(random);

        for (final u in shuffled) {
          final commU = currentAssignments[u]!;
          if (currentSizes[commU] != 1) continue;

          final ku = state.nodeWeights[u] ?? 0.0;
          final neighborWeights = _refinedNeighborWeights(
            graph,
            u,
            nodesInC,
            currentAssignments,
          );

          var bestComm = commU;
          var bestGain = 0.0;

          for (final entry in neighborWeights.entries) {
            final cRef = entry.key;
            if (cRef == commU) continue;

            final kCRef = currentTotals[cRef] ?? 0.0;
            final wUCRef = entry.value;
            final gain =
                wUCRef - options.resolution * ku * kCRef / state.totalWeight;

            if (gain > bestGain) {
              bestComm = cRef;
              bestGain = gain;
            }
          }

          if (bestGain > options.minModularityGain && bestComm != commU) {
            currentAssignments = Map<int, int>.from(currentAssignments)
              ..[u] = bestComm;
            currentTotals = Map<int, double>.from(currentTotals)
              ..update(commU, (v) => v - ku)
              ..update(bestComm, (v) => v + ku);
            currentSizes = Map<int, int>.from(currentSizes)
              ..[commU] = 0
              ..update(bestComm, (v) => v + 1);
            changed = true;
          }
        }
      }

      if (!changed) break;
    }

    final finalTotals = _calculateCommunityTotals(
      currentAssignments,
      state.nodeWeights,
    );
    return _LeidenState(
      assignments: currentAssignments,
      nodeWeights: state.nodeWeights,
      communityTotals: finalTotals,
      totalWeight: state.totalWeight,
    );
  }

  static Map<int, double> _refinedNeighborWeights<N, E>(
    Bidirectional<N, E> graph,
    int u,
    Set<int> nodesInC,
    Map<int, int> refinedAssignments,
  ) {
    final result = <int, double>{};
    for (final v in graph.successors(u)) {
      if (!nodesInC.contains(v)) continue;
      final commV = refinedAssignments[v]!;
      final weight = graph.edgeWeight(u, v);
      result[commV] = (result[commV] ?? 0.0) + weight;
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Aggregation
  // ---------------------------------------------------------------------------

  static SimpleGraph<N, double> _phase2Aggregate<N, E>(
    Bidirectional<N, E> graph,
    Map<int, int> assignments,
  ) {
    final newGraph = SimpleGraph<N, double>.undirected();
    final communities = _groupByCommunity(assignments);

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

  static _LeidenState _initialState<N, E>(
    Bidirectional<N, E> graph,
    List<int> nodes,
  ) {
    final assignments = <int, int>{
      for (var i = 0; i < nodes.length; i++) nodes[i]: i,
    };
    final nodeWeights = _calculateNodeWeights(graph);
    final communityTotals = _calculateCommunityTotals(assignments, nodeWeights);
    final totalWeight = _calculateTotalWeight(graph);

    return _LeidenState(
      assignments: assignments,
      nodeWeights: nodeWeights,
      communityTotals: communityTotals,
      totalWeight: totalWeight,
    );
  }

  static _LeidenState _rebuildState(Bidirectional<dynamic, double> graph) {
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
      result[entry.value] =
          (result[entry.value] ?? 0.0) + (nodeWeights[entry.key] ?? 0.0);
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

  static Map<int, Set<int>> _groupByCommunity(Map<int, int> assignments) {
    final result = <int, Set<int>>{};
    for (final entry in assignments.entries) {
      result.putIfAbsent(entry.value, () => <int>{}).add(entry.key);
    }
    return result;
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

class _LeidenOptions {
  final double resolution;
  final double minModularityGain;
  final int maxIterations;
  final int refinementIterations;
  final int seed;

  _LeidenOptions({
    required this.resolution,
    required this.minModularityGain,
    required this.maxIterations,
    required this.refinementIterations,
    required this.seed,
  });
}

class _LeidenState {
  final Map<int, int> assignments;
  final Map<int, double> nodeWeights;
  final Map<int, double> communityTotals;
  final double totalWeight;

  _LeidenState({
    required this.assignments,
    required this.nodeWeights,
    required this.communityTotals,
    required this.totalWeight,
  });
}
