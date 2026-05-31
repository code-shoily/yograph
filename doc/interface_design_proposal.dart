// ============================================================================
// PROPOSAL: Graph Interface Architecture for Yograph
// ============================================================================
// This file sketches three approaches for translating YogEx's model.ex
// contract into Dart. Only Approach B was chosen; this doc is kept for
// historical reference.
//
// NOTE: This proposal has been SUPERSEDED by the production implementation
// in lib/src/model/ and lib/src/simple_graph.dart. The production code
// resolved all type-system issues shown in the original sketch.
// ============================================================================

// =============================================================================
// APPROACH A: Single Fat Interface — REJECTED
// =============================================================================
// One interface exposes every capability. Algorithms accept it.
// Verdict: Too rigid. Doesn't let algorithms declare minimum requirements.

abstract class GraphModel<N, E> {
  bool get isEmpty;
  int get nodeCount;
  int get edgeCount;
  Iterable<Object> get nodeIds;
  bool hasNode(Object id);
  N? nodeData(Object id);
  bool hasEdge(Object from, Object to);
  E? edgeData(Object from, Object to);
  double edgeWeight(Object from, Object to);
  Iterable<Object> successors(Object id);
  Iterable<Object> predecessors(Object id);
  int outDegree(Object id);
  int inDegree(Object id);
}

// =============================================================================
// APPROACH B: Fine-Grained Capability Interfaces — ADOPTED
// =============================================================================
// Split capabilities into small interfaces. Algorithms declare what they need
// via COMBINED role interfaces.
//
// Key design decisions (from production implementation):
//   - BOTH N and E are class-level generic parameters on ALL interfaces.
//   - nodeData/edgeData return N?/E? (nullable), using hasNode/hasEdge to
//     distinguish "missing" from "present but null data".
//   - Internal maps are Map<Object, N?> and Map<Object, Map<Object, E?>>
//     so null data can be stored without runtime casts.
//   - Algorithm signatures propagate <N, E> generics; they never use raw
//     types or default to dynamic.

// ---------------------------------------------------------------------------
// Base capability interfaces
// ---------------------------------------------------------------------------

abstract class Traversable {
  Iterable<Object> get nodeIds;
  Iterable<Object> successors(Object id);
  int get nodeCount;
  bool get isEmpty;
}

/// Queryable is parameterized over BOTH node data (N) and edge data (E).
/// nodeData takes NO method-level generic — it returns the class-level N?.
abstract class Queryable<N, E> {
  bool hasNode(Object id);
  N? nodeData(Object id);
  bool hasEdge(Object from, Object to);
  E? edgeData(Object from, Object to);
  double edgeWeight(Object from, Object to);
}

abstract class Reversible<E> implements Traversable {
  Iterable<Object> predecessors(Object id);
  int inDegree(Object id);
}

abstract class Mutable<N, E> implements Traversable, Queryable<N, E> {
  void addNode(Object id, {N? data});
  void removeNode(Object id);
  void addEdge(Object from, Object to, {E? data});
  void removeEdge(Object from, Object to);
}

// ---------------------------------------------------------------------------
// Combined "role" interfaces — parameterized over BOTH N and E.
// ---------------------------------------------------------------------------

abstract class Walkable<N, E> implements Traversable, Queryable<N, E> {}

abstract class WeightedWalkable<N, E> implements Traversable, Queryable<N, E> {}

abstract class Bidirectional<N, E>
    implements Traversable, Reversible<E>, Queryable<N, E> {}

// ---------------------------------------------------------------------------
// Algorithm signatures — propagate <N, E> to avoid dynamic.
// ---------------------------------------------------------------------------

class PathResult {
  final List<Object> nodes;
  final double weight;
  PathResult(this.nodes, this.weight);
}

List<Object>? bfsPath<N, E>(Walkable<N, E> graph, Object from, Object to) {
  return null;
}

PathResult? dijkstra<N, E>(
  WeightedWalkable<N, E> graph,
  Object from,
  Object to,
) {
  return null;
}

Map<Object, double> betweenness<N, E>(Bidirectional<N, E> graph) {
  return {};
}

List<List<Object>> kosaraju<N, E>(Bidirectional<N, E> graph) {
  return [];
}

// ---------------------------------------------------------------------------
// Concrete: SimpleGraph (dual-map, like YogEx)
// ---------------------------------------------------------------------------
// Internal maps store N? and E? so null data is valid without casts.

enum GraphKind { directed, undirected }

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

  int get edgeCount => _edgeCount;

  SimpleGraph.directed() : kind = GraphKind.directed;
  SimpleGraph.undirected() : kind = GraphKind.undirected;

  @override
  bool get isEmpty => _nodes.isEmpty;

  @override
  int get nodeCount => _nodes.length;

  @override
  Iterable<Object> get nodeIds => _nodes.keys;

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
    if (data is num) return data.toDouble();
    return 1.0;
  }

  @override
  Iterable<Object> successors(Object id) => _out[id]?.keys ?? const [];

  @override
  Iterable<Object> predecessors(Object id) => _in[id]?.keys ?? const [];

  @override
  int inDegree(Object id) => _in[id]?.length ?? 0;

  @override
  void addNode(Object id, {N? data}) {
    _nodes[id] = data;
    _out.putIfAbsent(id, () => {});
    _in.putIfAbsent(id, () => {});
  }

  @override
  void addEdge(Object from, Object to, {E? data}) {
    if (!hasNode(from)) addNode(from);
    if (!hasNode(to)) addNode(to);

    final existed = _out[from]!.containsKey(to);
    if (!existed) _edgeCount++;

    _out[from]![to] = data;
    _in[to]![from] = data;

    if (kind == GraphKind.undirected && from != to) {
      _out[to]![from] = data;
      _in[from]![to] = data;
    }
  }

  @override
  void removeNode(Object id) {
    for (final to in List<Object>.from(_out[id]!.keys)) {
      removeEdge(id, to);
    }
    for (final from in List<Object>.from(_in[id]!.keys)) {
      removeEdge(from, id);
    }
    _nodes.remove(id);
    _out.remove(id);
    _in.remove(id);
  }

  @override
  void removeEdge(Object from, Object to) {
    if (_out[from]?.containsKey(to) != true) return;
    _out[from]!.remove(to);
    _in[to]!.remove(from);
    _edgeCount--;
    if (kind == GraphKind.undirected && from != to) {
      _out[to]!.remove(from);
      _in[from]!.remove(to);
    }
  }
}

// ---------------------------------------------------------------------------
// Concrete: SingleMapGraph (out-edges only)
// ---------------------------------------------------------------------------
// Implements Walkable but NOT Bidirectional.

class SingleMapGraph<N, E>
    implements Walkable<N, E>, WeightedWalkable<N, E>, Mutable<N, E> {
  final Map<Object, N?> _nodes = {};
  final Map<Object, Map<Object, E?>> _out = {};

  @override
  Iterable<Object> get nodeIds => _nodes.keys;

  @override
  int get nodeCount => _nodes.length;

  @override
  bool get isEmpty => _nodes.isEmpty;

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
    if (data is num) return data.toDouble();
    return 1.0;
  }

  @override
  Iterable<Object> successors(Object id) => _out[id]?.keys ?? const [];

  @override
  void addNode(Object id, {N? data}) {
    _nodes[id] = data;
    _out.putIfAbsent(id, () => {});
  }

  @override
  void addEdge(Object from, Object to, {E? data}) {
    if (!hasNode(from)) addNode(from);
    if (!hasNode(to)) addNode(to);
    _out[from]![to] = data;
  }

  @override
  void removeNode(Object id) {/* ... */}

  @override
  void removeEdge(Object from, Object to) {/* ... */}
}

// =============================================================================
// APPROACH C: Extension-Type Views — DEFERRED
// =============================================================================
// Extension types (Dart 3.2+) can create zero-cost views, but they cannot
// implement an interface unless their representation type is a subtype.
// A Map is not a Traversable, so AdjListView must be a regular class or
// delegate to an inner object. Deferred until a concrete use case arises.

// =============================================================================
// USAGE EXAMPLES
// =============================================================================

void main() {
  // --- SimpleGraph (full dual-map) ---
  final full = SimpleGraph<String, int>.directed()
    ..addNode('A', data: 'Start')
    ..addNode('B', data: 'End')
    ..addEdge('A', 'B', data: 42);

  // All of these compile with strict generics:
  bfsPath<String, int>(full, 'A', 'B');
  dijkstra<String, int>(full, 'A', 'B');
  betweenness<String, int>(full);

  // --- SingleMapGraph (out-edges only) ---
  final dag = SingleMapGraph<String, int>()
    ..addNode('A')
    ..addNode('B')
    ..addEdge('A', 'B');

  // These compile:
  bfsPath<String, int>(dag, 'A', 'B');
  dijkstra<String, int>(dag, 'A', 'B');

  // This is a COMPILE ERROR:
  // betweenness<String, int>(dag);
  // ERROR: SingleMapGraph doesn't implement Bidirectional
}
