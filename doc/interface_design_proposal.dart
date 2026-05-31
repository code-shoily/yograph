// ============================================================================
// PROPOSAL: Graph Interface Architecture for Yograph
// ============================================================================
// This file sketches three approaches for translating YogEx's model.ex
// contract into Dart. Only one will be chosen; this doc compares them.
//
// GOAL: Algorithms should declare WHAT they need, not WHICH class they take.
// This lets us swap SimpleGraph (dual-map) for MatrixGraph, SingleMapGraph,
// or even a lazy proxy graph in the future.
// ============================================================================

// =============================================================================
// APPROACH A: Single Fat Interface
// =============================================================================
// One interface exposes every capability. Algorithms accept it.
// Pros: Simple, no generics gymnastics.
// Cons: Algorithms don't declare minimum requirements. Hard to know if a
//       MatrixGraph (no in_edges) can be passed to betweenness().
//
// Verdict: Too rigid. Rejected.

abstract class GraphModel<N, E> {
  GraphKind get kind;
  bool get isEmpty;
  int get nodeCount;
  int get edgeCount;
  Iterable<Object> get nodeIds;
  bool hasNode(Object id);
  N? nodeData(Object id);
  bool hasEdge(Object from, Object to);
  E? edgeData(Object from, Object to);
  double edgeWeight(Object from, Object to); // throws if unweighted
  Iterable<Object> successors(Object id);
  Iterable<Object> predecessors(Object id);
  int outDegree(Object id);
  int inDegree(Object id);
  GraphModel<N, E> copy();
}

// =============================================================================
// APPROACH B: Fine-Grained Capability Interfaces (RECOMMENDED)
// =============================================================================
// Split capabilities into small interfaces. Algorithms declare what they need
// via COMBINED interfaces. Dart supports this cleanly with 'implements' chains.
//
// Pros:
//   - Algorithms self-document their requirements.
//   - MatrixGraph can implement Traversable + Queryable but NOT Reversible.
//   - Compile-time safety: you cannot pass an undirected-only view to an
//     algorithm that needs predecessors.
//
// Cons:
//   - Need to define "combo" interfaces for common pairs.
//   - Slightly more boilerplate (but only once).
//
// How it works in Dart:
//   Dart does NOT support `T extends A & B` in function type parameters.
//   BUT Dart DOES support `class C implements A, B`, so we create small
//   combined interfaces and use those as bounds. This is idiomatic Dart.

// ---------------------------------------------------------------------------
// Base capability interfaces
// ---------------------------------------------------------------------------

abstract class Traversable {
  /// All node IDs in the graph.
  Iterable<Object> get nodeIds;

  /// IDs reachable directly from [id] via outgoing edges.
  Iterable<Object> successors(Object id);

  /// Number of nodes.
  int get nodeCount;

  /// True if the graph contains no nodes.
  bool get isEmpty;
}

abstract class Queryable<E> {
  /// True if [id] is a node in the graph.
  bool hasNode(Object id);

  /// Data attached to node [id], or null if missing / no data.
  N? nodeData<N>(Object id);

  /// True if there is a directed edge from -> to.
  bool hasEdge(Object from, Object to);

  /// Data attached to edge from -> to, or null.
  E? edgeData(Object from, Object to);

  /// Weight of edge from -> to. For unweighted graphs, returns 1.0.
  double edgeWeight(Object from, Object to);
}

abstract class Reversible<E> implements Traversable {
  /// IDs that have an edge pointing TO [id].
  Iterable<Object> predecessors(Object id);

  /// Number of incoming edges to [id].
  int inDegree(Object id);
}

abstract class Mutable<N, E> implements Traversable, Queryable<E> {
  void addNode(Object id, {N? data});
  void removeNode(Object id);
  void addEdge(Object from, Object to, {E? data, double? weight});
  void removeEdge(Object from, Object to);
}

// ---------------------------------------------------------------------------
// Combined "role" interfaces — these are what algorithms actually accept.
// ---------------------------------------------------------------------------

/// Anything you can walk over (BFS/DFS/traversal).
abstract class Walkable<E> implements Traversable, Queryable<E> {}

/// Anything you can run shortest-path on.
/// Needs successors (to explore) + edge weights (to prioritize).
abstract class WeightedWalkable<E>
    implements Traversable, Queryable<E> {}

/// Anything you can compute betweenness / SCC / transpose on.
/// Needs both out-edges and in-edges.
abstract class Bidirectional<E>
    implements Traversable, Reversible<E>, Queryable<E> {}

// ---------------------------------------------------------------------------
// Algorithm signatures under Approach B
// ---------------------------------------------------------------------------

class PathResult {
  final List<Object> nodes;
  final double weight;
  PathResult(this.nodes, this.weight);
}

// BFS only needs to walk successors.
List<Object>? bfsPath(Walkable graph, Object from, Object to) {
  // ...
  return null;
}

// Dijkstra needs successors + edge weights.
PathResult? dijkstra<W extends WeightedWalkable>(
    W graph, Object from, Object to) {
  // ...
  return null;
}

// Betweenness needs predecessors (dual-index).
Map<Object, double> betweenness<B extends Bidirectional>(B graph) {
  // ...
  return {};
}

// Kosaraju needs transpose => needs in_edges.
List<List<Object>> kosaraju<B extends Bidirectional>(B graph) {
  // ...
  return [];
}

// ---------------------------------------------------------------------------
// Concrete implementation: SimpleGraph (dual-map, like YogEx)
// ---------------------------------------------------------------------------

enum GraphKind { directed, undirected }

class SimpleGraph<N, E> implements Walkable<E>, Bidirectional<E>, Mutable<N, E> {
  final GraphKind kind;
  final Map<Object, N> _nodes = {};
  final Map<Object, Map<Object, E>> _out = {};
  final Map<Object, Map<Object, E>> _in = {};

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
  N? nodeData<N>(Object id) {
    final v = _nodes[id];
    return v is N ? v : null;
  }

  @override
  bool hasEdge(Object from, Object to) => _out[from]?.containsKey(to) ?? false;

  @override
  E? edgeData(Object from, Object to) => _out[from]?[to];

  @override
  double edgeWeight(Object from, Object to) {
    final data = edgeData(from, to);
    if (data == null) return double.infinity;
    if (data is num) return data.toDouble();
    return 1.0; // unweighted default
  }

  @override
  Iterable<Object> successors(Object id) => _out[id]?.keys ?? const [];

  @override
  Iterable<Object> predecessors(Object id) => _in[id]?.keys ?? const [];

  @override
  int inDegree(Object id) => _in[id]?.length ?? 0;

  @override
  void addNode(Object id, {N? data}) {
    _nodes[id] = data as N;
    _out.putIfAbsent(id, () => {});
    _in.putIfAbsent(id, () => {});
  }

  @override
  void addEdge(Object from, Object to, {E? data, double? weight}) {
    _out.putIfAbsent(from, () => {})[to] = data as E;
    _in.putIfAbsent(to, () => {})[from] = data as E;
    if (kind == GraphKind.undirected) {
      _out.putIfAbsent(to, () => {})[from] = data as E;
      _in.putIfAbsent(from, () => {})[to] = data as E;
    }
  }

  @override
  void removeNode(Object id) {
    // ...
  }

  @override
  void removeEdge(Object from, Object to) {
    // ...
  }
}

// ---------------------------------------------------------------------------
// Concrete implementation: SingleMapGraph (out-edges only, for DAGs/trees)
// ---------------------------------------------------------------------------
// This can implement Walkable but NOT Bidirectional.
// Compile-time safety: betweenness(SingleMapGraph) is a type error!

class SingleMapGraph<N, E> implements Walkable<E>, Mutable<N, E> {
  final Map<Object, N> _nodes = {};
  final Map<Object, Map<Object, E>> _out = {};

  @override
  Iterable<Object> get nodeIds => _nodes.keys;

  @override
  int get nodeCount => _nodes.length;

  @override
  bool get isEmpty => _nodes.isEmpty;

  @override
  bool hasNode(Object id) => _nodes.containsKey(id);

  @override
  N? nodeData<N2>(Object id) {
    final v = _nodes[id];
    return v is N2 ? v : null;
  }

  @override
  bool hasEdge(Object from, Object to) => _out[from]?.containsKey(to) ?? false;

  @override
  E? edgeData(Object from, Object to) => _out[from]?[to];

  @override
  double edgeWeight(Object from, Object to) {
    final data = edgeData(from, to);
    if (data == null) return double.infinity;
    if (data is num) return data.toDouble();
    return 1.0;
  }

  @override
  Iterable<Object> successors(Object id) => _out[id]?.keys ?? const [];

  @override
  void addNode(Object id, {N? data}) {
    _nodes[id] = data as N;
    _out.putIfAbsent(id, () => {});
  }

  @override
  void addEdge(Object from, Object to, {E? data, double? weight}) {
    _out.putIfAbsent(from, () => {})[to] = data as E;
  }

  @override
  void removeNode(Object id) {/* ... */}

  @override
  void removeEdge(Object from, Object to) {/* ... */}
}

// =============================================================================
// APPROACH C: Extension-Type Views (Dart 3.2+)
// =============================================================================
// Use `extension type` to create zero-cost views that implement the
// capability interfaces over any underlying storage.
//
// Pros: Zero overhead, decouples storage from interface.
// Cons: Requires Dart 3.2+, slightly exotic for contributors.
//
// This is APPROACH B's companion — we can use both.

// Example: a view over a Map-of-Lists adjacency list (no edge data).
extension type AdjListView._(Map<Object, List<Object>> _adj)
    implements Traversable {
  @override
  Iterable<Object> get nodeIds => _adj.keys;

  @override
  int get nodeCount => _adj.length;

  @override
  bool get isEmpty => _adj.isEmpty;

  @override
  Iterable<Object> successors(Object id) => _adj[id] ?? const [];
}

// =============================================================================
// USAGE EXAMPLES
// =============================================================================

void main() {
  // --- SimpleGraph (full dual-map) ---
  final full = SimpleGraph<String, int>.directed()
    ..addNode('A', data: 'Start')
    ..addNode('B', data: 'End')
    ..addEdge('A', 'B', data: 42);

  // All of these compile:
  bfsPath(full, 'A', 'B');
  dijkstra(full, 'A', 'B');
  betweenness(full);

  // --- SingleMapGraph (out-edges only) ---
  final dag = SingleMapGraph<String, int>()
    ..addNode('A')
    ..addNode('B')
    ..addEdge('A', 'B');

  // These compile:
  bfsPath(dag, 'A', 'B');
  dijkstra(dag, 'A', 'B');

  // This is a COMPILE ERROR:
  // betweenness(dag);  // ERROR: SingleMapGraph doesn't implement Bidirectional

  // --- Extension type view over raw data ---
  final raw = {'A': ['B', 'C'], 'B': ['C']};
  final view = AdjListView(raw);
  bfsPath(view, 'A', 'C'); // compiles! Traversable only.
}
