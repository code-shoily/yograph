import 'model/graph_kind.dart';
import 'model/mutable.dart';
import 'model/roles.dart';

/// A mutable graph backed by a dual-indexed adjacency list.
///
/// [N] is the type of data stored on nodes; [E] is the type of data stored
/// on edges.  Either may be `Null` when you do not need to attach data.
///
/// The internal representation keeps two maps:
/// * `_out[id]`  → `{neighbor => edgeData}` for outgoing edges
/// * `_in[id]`   → `{neighbor => edgeData}` for incoming edges
///
/// For undirected graphs the two maps are symmetric: every edge is stored
/// in both directions, so [successors] and [predecessors] return the same
/// set and [outDegree] == [inDegree].
///
/// Implements the full [Bidirectional] and [Mutable] contracts, so it can
/// be passed to every algorithm in the library.
class SimpleGraph<N, E>
    implements
        Walkable<N, E>,
        WeightedWalkable<N, E>,
        Bidirectional<N, E>,
        Mutable<N, E> {
  final GraphKind kind;

  final Map<Object, N?> _nodes = {};
  final Map<Object, Map<Object, E?>> _out = {};
  final Map<Object, Map<Object, E?>> _in = {};
  int _edgeCount = 0;

  SimpleGraph.directed() : kind = GraphKind.directed;

  SimpleGraph.undirected() : kind = GraphKind.undirected;

  // -----------------------------------------------------------------------
  // Traversable
  // -----------------------------------------------------------------------

  @override
  bool get isEmpty => _nodes.isEmpty;

  @override
  int get nodeCount => _nodes.length;

  @override
  Iterable<Object> get nodeIds => _nodes.keys;

  @override
  Iterable<Object> successors(Object id) => _out[id]?.keys ?? const [];

  // -----------------------------------------------------------------------
  // Queryable
  // -----------------------------------------------------------------------

  @override
  bool hasNode(Object id) => _nodes.containsKey(id);

  @override
  N? nodeData(Object id) => _nodes[id];

  @override
  bool hasEdge(Object from, Object to) => _out[from]?.containsKey(to) ?? false;

  @override
  E? edgeData(Object from, Object to) => _out[from]?[to];

  @override
  double edgeWeight(Object from, Object to) {
    if (!hasEdge(from, to)) {
      throw StateError('No edge from $from to $to');
    }
    final data = edgeData(from, to);
    if (data is num) {
      return data.toDouble();
    }
    return 1.0;
  }

  // -----------------------------------------------------------------------
  // Reversible
  // -----------------------------------------------------------------------

  @override
  Iterable<Object> predecessors(Object id) => _in[id]?.keys ?? const [];

  @override
  int inDegree(Object id) => _in[id]?.length ?? 0;

  /// Number of outgoing edges from [id].
  int outDegree(Object id) => _out[id]?.length ?? 0;

  // -----------------------------------------------------------------------
  // Mutable
  // -----------------------------------------------------------------------

  @override
  void addNode(Object id, {N? data}) {
    _nodes[id] = data;
    _out.putIfAbsent(id, () => {});
    _in.putIfAbsent(id, () => {});
  }

  @override
  void addEdge(Object from, Object to, {E? data}) {
    // Auto-create missing endpoint nodes.
    if (!_nodes.containsKey(from)) {
      addNode(from);
    }
    if (!_nodes.containsKey(to)) {
      addNode(to);
    }

    final bool existed = _out[from]!.containsKey(to);
    if (!existed) {
      _edgeCount++;
    }

    _out[from]![to] = data;
    _in[to]![from] = data;

    if (kind == GraphKind.undirected && from != to) {
      _out[to]![from] = data;
      _in[from]![to] = data;
    }
  }

  @override
  void removeNode(Object id) {
    if (!hasNode(id)) {
      throw ArgumentError.value(id, 'id', 'Node does not exist');
    }

    // Remove all outgoing edges first.
    final outNeighbors = List<Object>.from(_out[id]!.keys);
    for (final to in outNeighbors) {
      removeEdge(id, to);
    }

    // Remove all incoming edges.
    final inNeighbors = List<Object>.from(_in[id]!.keys);
    for (final from in inNeighbors) {
      removeEdge(from, id);
    }

    _nodes.remove(id);
    _out.remove(id);
    _in.remove(id);
  }

  @override
  void removeEdge(Object from, Object to) {
    if (_out[from]?.containsKey(to) != true) {
      return; // idempotent
    }

    _out[from]!.remove(to);
    _in[to]!.remove(from);
    _edgeCount--;

    if (kind == GraphKind.undirected && from != to) {
      _out[to]!.remove(from);
      _in[from]!.remove(to);
    }
  }

  // -----------------------------------------------------------------------
  // Convenience
  // -----------------------------------------------------------------------

  /// Total number of edges in the graph.
  ///
  /// For undirected graphs each unordered pair is counted once.
  int get edgeCount => _edgeCount;

  /// Neighbors of [id] — for undirected graphs this is identical to
  /// [successors]; for directed graphs it is also identical (only outgoing
  /// neighbors are considered "neighbors" in the standard definition).
  Iterable<Object> neighbors(Object id) => successors(id);

  /// Degree of [id].
  ///
  /// For undirected graphs this equals [outDegree] (and [inDegree]).
  /// For directed graphs this returns the out-degree.
  int degree(Object id) => outDegree(id);

  /// `true` if the graph contains no edges.
  bool get hasNoEdges => _edgeCount == 0;

  @override
  String toString() {
    final name = kind == GraphKind.directed ? 'Directed' : 'Undirected';
    return '$name SimpleGraph($nodeCount nodes, $_edgeCount edges)';
  }
}
