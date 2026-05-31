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
  Iterable<int> get nodeIds;
  bool hasNode(int id);
  N? nodeData(int id);
  bool hasEdge(int from, int to);
  E? edgeData(int from, int to);
  double edgeWeight(int from, int to);
  Iterable<int> successors(int id);
  Iterable<int> predecessors(int id);
  int outDegree(int id);
  int inDegree(int id);
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
//   - Internal maps are Map<int, N?> and Map<int, Map<int, E?>>
//     so null data can be stored without runtime casts.
//   - Algorithm signatures propagate <N, E> generics; they never use raw
//     types or default to dynamic.

// ---------------------------------------------------------------------------
// Base capability interfaces
// ---------------------------------------------------------------------------

abstract class Traversable {
  Iterable<int> get nodeIds;
  Iterable<int> successors(int id);
  int get nodeCount;
  bool get isEmpty;
}

/// Queryable is parameterized over BOTH node data (N) and edge data (E).
/// nodeData takes NO method-level generic — it returns the class-level N?.
abstract class Queryable<N, E> {
  bool hasNode(int id);
  N? nodeData(int id);
  bool hasEdge(int from, int to);
  E? edgeData(int from, int to);
  double edgeWeight(int from, int to);
}

abstract class Reversible<E> implements Traversable {
  Iterable<int> predecessors(int id);
  int inDegree(int id);
}

abstract class Mutable<N, E> implements Traversable, Queryable<N, E> {
  void addNode(int id, {N? data});
  void removeNode(int id);
  void addEdge(int from, int to, {E? data});
  void removeEdge(int from, int to);
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
  final List<int> nodes;
  final double weight;
  PathResult(this.nodes, this.weight);
}

List<int>? bfsPath<N, E>(Walkable<N, E> graph, int from, int to) {
  return null;
}

PathResult? dijkstra<N, E>(WeightedWalkable<N, E> graph, int from, int to) {
  return null;
}

Map<int, double> betweenness<N, E>(Bidirectional<N, E> graph) {
  return {};
}

List<List<int>> kosaraju<N, E>(Bidirectional<N, E> graph) {
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
  final Map<int, N?> _nodes = {};
  final Map<int, Map<int, E?>> _out = {};
  final Map<int, Map<int, E?>> _in = {};
  int _edgeCount = 0;

  int get edgeCount => _edgeCount;

  SimpleGraph.directed() : kind = GraphKind.directed;
  SimpleGraph.undirected() : kind = GraphKind.undirected;

  @override
  bool get isEmpty => _nodes.isEmpty;

  @override
  int get nodeCount => _nodes.length;

  @override
  Iterable<int> get nodeIds => _nodes.keys;

  @override
  bool hasNode(int id) => _nodes.containsKey(id);

  @override
  N? nodeData(int id) => _nodes[id];

  @override
  bool hasEdge(int from, int to) => _out[from]?.containsKey(to) ?? false;

  @override
  E? edgeData(int from, int to) => _out[from]?[to];

  @override
  double edgeWeight(int from, int to) {
    if (!hasEdge(from, to)) {
      throw StateError('No edge from $from to $to');
    }
    final data = edgeData(from, to);
    if (data is num) return data.toDouble();
    return 1.0;
  }

  @override
  Iterable<int> successors(int id) => _out[id]?.keys ?? const [];

  @override
  Iterable<int> predecessors(int id) => _in[id]?.keys ?? const [];

  @override
  int inDegree(int id) => _in[id]?.length ?? 0;

  @override
  void addNode(int id, {N? data}) {
    _nodes[id] = data;
    _out.putIfAbsent(id, () => {});
    _in.putIfAbsent(id, () => {});
  }

  @override
  void addEdge(int from, int to, {E? data}) {
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
  void removeNode(int id) {
    for (final to in List<int>.from(_out[id]!.keys)) {
      removeEdge(id, to);
    }
    for (final from in List<int>.from(_in[id]!.keys)) {
      removeEdge(from, id);
    }
    _nodes.remove(id);
    _out.remove(id);
    _in.remove(id);
  }

  @override
  void removeEdge(int from, int to) {
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
  final Map<int, N?> _nodes = {};
  final Map<int, Map<int, E?>> _out = {};

  @override
  Iterable<int> get nodeIds => _nodes.keys;

  @override
  int get nodeCount => _nodes.length;

  @override
  bool get isEmpty => _nodes.isEmpty;

  @override
  bool hasNode(int id) => _nodes.containsKey(id);

  @override
  N? nodeData(int id) => _nodes[id];

  @override
  bool hasEdge(int from, int to) => _out[from]?.containsKey(to) ?? false;

  @override
  E? edgeData(int from, int to) => _out[from]?[to];

  @override
  double edgeWeight(int from, int to) {
    if (!hasEdge(from, to)) {
      throw StateError('No edge from $from to $to');
    }
    final data = edgeData(from, to);
    if (data is num) return data.toDouble();
    return 1.0;
  }

  @override
  Iterable<int> successors(int id) => _out[id]?.keys ?? const [];

  @override
  void addNode(int id, {N? data}) {
    _nodes[id] = data;
    _out.putIfAbsent(id, () => {});
  }

  @override
  void addEdge(int from, int to, {E? data}) {
    if (!hasNode(from)) addNode(from);
    if (!hasNode(to)) addNode(to);
    _out[from]![to] = data;
  }

  @override
  void removeNode(int id) {
    /* ... */
  }

  @override
  void removeEdge(int from, int to) {
    /* ... */
  }
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
    ..addNode(0, data: 'Start')
    ..addNode(1, data: 'End')
    ..addEdge(0, 1, data: 42);

  // All of these compile with strict generics:
  bfsPath<String, int>(full, 0, 1);
  dijkstra<String, int>(full, 0, 1);
  betweenness<String, int>(full);

  // --- SingleMapGraph (out-edges only) ---
  final dag = SingleMapGraph<String, int>()
    ..addNode(0)
    ..addNode(1)
    ..addEdge(0, 1);

  // These compile:
  bfsPath<String, int>(dag, 0, 1);
  dijkstra<String, int>(dag, 0, 1);

  // This is a COMPILE ERROR:
  // betweenness<String, int>(dag);
  // ERROR: SingleMapGraph doesn't implement Bidirectional
}
