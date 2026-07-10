import '../internal/priority_queue.dart';
import '../model/graph_kind.dart';
import '../model/roles.dart';
import '../model/weight_algebra.dart';
import '../path.dart';
import 'a_star.dart';
import 'dijkstra.dart';

/// Yen's algorithm for finding the [k] shortest loopless paths.
///
/// The returned paths are ordered from shortest to longest.  All edge
/// weights must be non-negative; otherwise the underlying Dijkstra calls
/// are not guaranteed to be correct.
///
/// **Time complexity:** O(k · N · (E + V log V))
abstract final class Yen {
  /// Returns up to [k] shortest loopless paths from [from] to [to].
  ///
  /// Returns an empty list when [from] or [to] is missing or when no path
  /// exists.  If fewer than [k] distinct loopless paths exist, all of them
  /// are returned.
  static List<Path<E>> kShortestPaths<N, E>(
    WeightedWalkable<N, E> graph,
    int from,
    int to,
    int k, {
    WeightAlgebra<E>? algebra,
  }) {
    if (k <= 0) return [];
    if (!graph.hasNode(from) || !graph.hasNode(to)) return [];

    final alg = resolveAlgebra<E>(algebra);

    final first = Dijkstra.shortestPath(graph, from, to, algebra: alg);
    if (first == null) return [];

    final result = <Path<E>>[first];
    if (k == 1) return result;

    final candidates = PriorityQueue<Path<E>>((a, b) {
      final cmp = alg.compare(a.weight, b.weight);
      if (cmp != 0) return cmp;
      // Deterministic tie-break for equal-weight paths.
      return a.nodes.join(',').compareTo(b.nodes.join(','));
    });
    final candidateKeys = <String>{};
    final resultKeys = <String>{_pathKey(first.nodes)};

    for (var i = 1; i < k; i++) {
      final previous = result[i - 1];

      for (var j = 0; j < previous.length; j++) {
        final spurNode = previous.nodes[j];
        final rootPath = previous.nodes.sublist(0, j + 1);

        // Block edges that leave the root path in previously found paths.
        final blockedEdges = <(int, int)>{};
        for (final path in result) {
          if (path.nodes.length > j + 1 &&
              _listPrefixEquals(path.nodes, rootPath, j + 1)) {
            blockedEdges.add((path.nodes[j], path.nodes[j + 1]));
          }
        }

        // Block root-path nodes except the spur node itself.
        final blockedNodes = rootPath.toSet()..remove(spurNode);

        final filtered = _FilteredGraph(graph, blockedNodes, blockedEdges);

        final spurPath = Dijkstra.shortestPath(
          filtered,
          spurNode,
          to,
          algebra: alg,
        );

        if (spurPath == null) continue;

        final totalNodes = [...rootPath, ...spurPath.nodes.skip(1)];
        final key = _pathKey(totalNodes);
        if (resultKeys.contains(key) || candidateKeys.contains(key)) continue;

        var rootWeight = alg.zero;
        for (var e = 0; e < rootPath.length - 1; e++) {
          rootWeight = alg.add(
            rootWeight,
            edgeValue(graph, rootPath[e], rootPath[e + 1], alg),
          );
        }
        final totalWeight = alg.add(rootWeight, spurPath.weight);

        final candidate = Path(totalNodes, totalWeight);
        candidates.push(candidate);
        candidateKeys.add(key);
      }

      if (candidates.isEmpty) break;

      final next = candidates.pop()!;
      candidateKeys.remove(_pathKey(next.nodes));
      if (resultKeys.contains(_pathKey(next.nodes))) continue;

      result.add(next);
      resultKeys.add(_pathKey(next.nodes));
    }

    return result;
  }

  static String _pathKey(List<int> nodes) => nodes.join(',');

  static bool _listPrefixEquals(List<int> a, List<int> b, int length) {
    if (a.length < length || b.length < length) return false;
    for (var i = 0; i < length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// A [WeightedWalkable] view that hides a set of blocked nodes and edges.
class _FilteredGraph<N, E> implements WeightedWalkable<N, E> {
  final WeightedWalkable<N, E> _graph;
  final Set<int> _blockedNodes;
  final Set<(int, int)> _blockedEdges;

  _FilteredGraph(this._graph, this._blockedNodes, this._blockedEdges);

  @override
  GraphKind get kind => _graph.kind;

  @override
  Iterable<int> get nodeIds =>
      _graph.nodeIds.where((id) => !_blockedNodes.contains(id));

  @override
  bool get isEmpty => nodeIds.isEmpty;

  @override
  bool get isNotEmpty => nodeIds.isNotEmpty;

  @override
  int get nodeCount => nodeIds.length;

  @override
  int get edgeCount {
    var count = 0;
    for (final u in nodeIds) {
      count += successors(u).length;
    }
    return _graph.kind == GraphKind.undirected ? count ~/ 2 : count;
  }

  @override
  bool hasNode(int id) => !_blockedNodes.contains(id) && _graph.hasNode(id);

  @override
  N? nodeData(int id) => _graph.nodeData(id);

  @override
  bool hasEdge(int from, int to) =>
      !_blockedEdges.contains((from, to)) && _graph.hasEdge(from, to);

  @override
  E? edgeData(int from, int to) => _graph.edgeData(from, to);

  @override
  double edgeWeight(int from, int to) => _graph.edgeWeight(from, to);

  @override
  Iterable<int> successors(int id) sync* {
    for (final succ in _graph.successors(id)) {
      if (_blockedNodes.contains(succ)) continue;
      if (_blockedEdges.contains((id, succ))) continue;
      yield succ;
    }
  }
}
