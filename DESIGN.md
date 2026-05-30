# Yograph Design Document

> **Status:** Draft — v0.1  
> **Reference:** [YogEx](https://github.com/code-shoily/yog_ex) (Elixir) — our north star for depth and breadth.

---

## 1. Project Goals

Build the most comprehensive graph theory library for Dart and Flutter. Pure Dart core (no FFI in v1), with optional Flutter rendering widgets for graph visualization.

**Target users:**
- Flutter developers building network visualization apps
- Dart backend developers doing graph analytics
- Researchers and students needing graph algorithms

**Core principles:**
1. **Completeness** — match YogEx's algorithmic breadth (60+ algorithms)
2. **Ergonomics** — fluent builder API, named parameters, clear error messages
3. **Performance** — pure Dart optimized for small-to-medium graphs; FFI reserved for v2
4. **Type safety** — generic `Graph<N, E>` with compile-time node/edge type safety
5. **Testability** — every algorithm has property-based and example-based tests

---

## 2. Core Data Model

### 2.1 `Graph<N, E>`

Dual-indexed adjacency list — directly ported from YogEx's `%Yog.Graph{}`.

```dart
class Graph<N, E> {
  final GraphKind kind;                    // directed or undirected
  final Map<Object, N> nodes;              // node_id => node_data
  final Map<Object, Map<Object, E>> outEdges;  // node_id => {neighbor_id => edge_data}
  final Map<Object, Map<Object, E>> inEdges;   // node_id => {neighbor_id => edge_data}
}
```

**Why dual-indexed?**
| Operation | Single-indexed | Dual-indexed (YogEx style) |
|-----------|---------------|---------------------------|
| Transpose | O(V + E) | O(1) — swap maps |
| Predecessors | O(V + E) scan | O(1) lookup |
| In-degree | O(V + E) scan | O(1) — `inEdges[id].length` |
| Edge count (undirected) | O(V + E) | O(V) — sum `outEdges` values, adjust for self-loops |

**Node ID type:** `Object` (anything with `==` and `hashCode`). Common: `String`, `int`.

### 2.2 Immutability vs. Mutability

**Decision:** Mutable by default, with optional copy-on-write variants.

```dart
// Mutable (default) — idiomatic Dart
final graph = Graph<String, int>.directed()
  ..addNode('A', data: 'Start')
  ..addNode('B', data: 'End')
  ..addEdge('A', 'B', weight: 10);

// Immutable variant — returns new Graph
final graph2 = graph.addedNode('C', data: 'Middle'); // graph is unchanged
```

Rationale: Dart OOP is overwhelmingly mutable. The `..` cascade operator makes fluent building ergonomic. We offer `addedNode`, `addedEdge`, etc. as immutable alternatives where needed.

### 2.3 Result Types

Algorithms return structured result objects rather than raw collections:

```dart
// Pathfinding
final path = Pathfinding.dijkstra(graph, from: 'A', to: 'B');
print(path.nodes);     // ['A', 'C', 'B']
print(path.weight);    // 15
print(path.algorithm); // Algorithm.dijkstra

// Centrality
final scores = Centrality.betweenness(graph);
print(scores['A']);    // 0.42

// Community detection
final communities = Community.louvain(graph);
print(communities.assignments);      // {'A': 0, 'B': 0, 'C': 1}
print(communities.numCommunities);   // 2
```

---

## 3. Module Architecture

Each YogEx module maps to a Dart static utility class or extension:

| YogEx Module | Dart Class/Namespace | Status |
|-------------|---------------------|--------|
| `Yog` (facade) | `Graph` constructors + top-level helpers | ⬜ Not started |
| `Yog.Graph` | `Graph<N, E>` class | ⬜ Not started |
| `Yog.Model` | `Graph<N, E>` methods (`addNode`, `addEdge`, etc.) | ⬜ Not started |
| `Yog.Pathfinding` | `Pathfinding` static class | ⬜ Not started |
| `Yog.Centrality` | `Centrality` static class | ⬜ Not started |
| `Yog.Connectivity` | `Connectivity` static class | ⬜ Not started |
| `Yog.Community` | `Community` static class | ⬜ Not started |
| `Yog.Traversal` | `Traversal` static class | ⬜ Not started |
| `Yog.Generator.Classic` | `Generator` static class | ⬜ Not started |
| `Yog.Generator.Random` | `Generator` static class | ⬜ Not started |
| `Yog.Operation` | `GraphOperations` static class | ⬜ Not started |
| `Yog.Transform` | `GraphTransform` static class | ⬜ Not started |
| `Yog.DAG` | `DagGraph<N, E>` wrapper class | ⬜ Not started |
| `Yog.IO.JSON` | `GraphJson` static class | ⬜ Not started |
| `Yog.Render.DOT` | `DotRenderer` static class | ⬜ Not started |
| `Yog.Render.Mermaid` | `MermaidRenderer` static class | ⬜ Not started |
| `Yog.Multi` | `MultiGraph<N, E>` class | ⬜ Not started |
| `Yog.Matching` | `Matching` static class | ⬜ Not started |
| `Yog.Flow` | `Flow` static class | ⬜ Not started |
| `Yog.MST` | `MST` static class | ⬜ Not started |

---

## 4. Algorithm Catalog

### 4.1 Pathfinding (`lib/pathfinding/`)

| Algorithm | Function | Complexity | Notes |
|-----------|----------|------------|-------|
| Dijkstra (single-source) | `Pathfinding.dijkstra()` | O((V+E) log V) | Uses `MinHeap` from existing algorithms repo |
| Dijkstra (all-pairs unweighted) | `Pathfinding.allPairsUnweighted()` | O(V² + VE) | Parallel BFS from each node |
| A* | `Pathfinding.aStar()` | O((V+E) log V) | Requires heuristic function |
| Bellman-Ford | `Pathfinding.bellmanFord()` | O(VE) | Detects negative cycles |
| Bidirectional Dijkstra | `Pathfinding.bidirectional()` | O((V+E) log V) | Faster for single-pair |
| Bidirectional BFS | `Pathfinding.bidirectionalUnweighted()` | O(V + E) | For unweighted graphs |
| Floyd-Warshall | `Pathfinding.floydWarshall()` | O(V³) | All-pairs dense graphs |
| Johnson's | `Pathfinding.johnson()` | O(V² log V + VE) | All-pairs sparse, negative weights |
| Yen (k-shortest) | `Pathfinding.kShortestPaths()` | O(k · V · (V+E) log V) | Loopless paths |
| Widest Path | `Pathfinding.widestPath()` | O((V+E) log V) | Max bottleneck (min edge) |
| Chinese Postman | `Pathfinding.chinesePostman()` | O(V³) | Route inspection |
| LCA (binary lifting) | `Pathfinding.lca()` | O(V log V) preprocess, O(log V) query | Tree only |

**Result type:** `Path` class with `nodes`, `weight`, `algorithm`, `metadata`.

### 4.2 Centrality (`lib/centrality/`)

| Measure | Function | Complexity | Parallel? |
|---------|----------|------------|-----------|
| Degree | `Centrality.degree()` | O(V) | No |
| Closeness | `Centrality.closeness()` | O(V · (V+E) log V) | Yes (isolates) |
| Harmonic | `Centrality.harmonic()` | O(V · (V+E) log V) | Yes (isolates) |
| Betweenness (Brandes) | `Centrality.betweenness()` | O(VE) unweighted, O(VE + V² log V) weighted | Yes (isolates) |
| PageRank | `Centrality.pagerank()` | O(k · (V+E)) | No |
| HITS | `Centrality.hits()` | O(k · (V+E)) | No |
| Eigenvector | `Centrality.eigenvector()` | O(k · (V+E)) | No |
| Katz | `Centrality.katz()` | O(k · (V+E)) | No |
| Alpha | `Centrality.alpha()` | O(k · (V+E)) | No |

**Result type:** `Map<Object, double>`.

### 4.3 Connectivity (`lib/connectivity/`)

| Algorithm | Function | Complexity |
|-----------|----------|------------|
| Tarjan SCC | `Connectivity.stronglyConnectedComponents()` | O(V + E) |
| Kosaraju | `Connectivity.kosaraju()` | O(V + E) |
| Connected Components | `Connectivity.connectedComponents()` | O(V + E) |
| Weakly Connected Components | `Connectivity.weaklyConnectedComponents()` | O(V + E) |
| Bridges | `Connectivity.bridges()` | O(V + E) |
| Articulation Points | `Connectivity.articulationPoints()` | O(V + E) |
| K-Core | `Connectivity.kCore()` | O(V + E) |
| Core Numbers | `Connectivity.coreNumbers()` | O(V + E) |
| Reachability Counts | `Connectivity.reachabilityCounts()` | O(V · (V+E)) |

### 4.4 Community Detection (`lib/community/`)

| Algorithm | Function | Complexity | Best For |
|-----------|----------|------------|----------|
| Louvain | `Community.louvain()` | O(V log V) | Large graphs |
| Leiden | `Community.leiden()` | O(V log V) | Quality guarantee |
| Label Propagation | `Community.labelPropagation()` | O(V + E) | Speed |
| Girvan-Newman | `Community.girvanNewman()` | O(V · E²) | Hierarchical |
| Infomap | `Community.infomap()` | O(V log V) | Flow-based |
| Walktrap | `Community.walktrap()` | O(V² log V) | Random walks |
| Clique Percolation | `Community.cliquePercolation()` | Exponential | Overlapping |
| Fluid Communities | `Community.fluidCommunities()` | O(V + E) | Exact k partitions |

**Result type:** `CommunityResult` with `assignments` (Map), `numCommunities`, `metadata`.

**Metrics:** `Community.modularity()`, `Community.countTriangles()`, `Community.clusteringCoefficient()`, `Community.density()`.

### 4.5 Traversal (`lib/traversal/`)

| Algorithm | Function | Notes |
|-----------|----------|-------|
| BFS walk | `Traversal.bfs()` | Returns visited order |
| DFS walk | `Traversal.dfs()` | Returns visited order |
| Generic fold walk | `Traversal.foldWalk()` | Universal abstraction — all others build on this |
| Find path (unweighted) | `Traversal.findPath()` | BFS with parent map |
| Reachable? | `Traversal.isReachable()` | Boolean connectivity check |
| Topological sort | `Traversal.topologicalSort()` | Kahn's algorithm |
| Lexicographical topological sort | `Traversal.lexicographicalTopologicalSort()` | Kahn's + priority queue |

**Control signals:** `WalkControl.continue`, `WalkControl.stop`, `WalkControl.halt`.

**Metadata per node:** `depth`, `parent`.

### 4.6 Generators (`lib/generator/`)

**Classic (deterministic):**

| Generator | Function |
|-----------|----------|
| Complete | `Generator.complete(n)` |
| Cycle | `Generator.cycle(n)` |
| Path | `Generator.path(n)` |
| Star | `Generator.star(n)` |
| Wheel | `Generator.wheel(n)` |
| Grid 2D | `Generator.grid2d(rows, cols)` |
| Ladder | `Generator.ladder(n)` |
| Binary Tree | `Generator.binaryTree(height)` |
| Petersen | `Generator.petersen()` |
| Hypercube | `Generator.hyperCube(dimensions)` |
| Platonic solids | `Generator.tetrahedron()`, `Generator.cube()`, etc. |

**Random (stochastic):**

| Model | Function |
|-------|----------|
| Erdős-Rényi G(n,p) | `Generator.erdosRenyiGnp(n, p)` |
| Erdős-Rényi G(n,m) | `Generator.erdosRenyiGnm(n, m)` |
| Barabási-Albert | `Generator.barabasiAlbert(n, m)` |
| Watts-Strogatz | `Generator.wattsStrogatz(n, k, p)` |
| Random Tree | `Generator.randomTree(n)` |
| Random Regular | `Generator.randomRegular(n, d)` |
| SBM | `Generator.sbm(...)` |
| R-MAT | `Generator.rmat(...)` |
| Geometric | `Generator.geometric(n, radius)` |

### 4.7 Graph Operations (`lib/operation/`)

| Operation | Function |
|-----------|----------|
| Union | `GraphOperations.union(a, b)` |
| Intersection | `GraphOperations.intersection(a, b)` |
| Difference | `GraphOperations.difference(a, b)` |
| Symmetric Difference | `GraphOperations.symmetricDifference(a, b)` |
| Cartesian Product | `GraphOperations.cartesianProduct(a, b)` |
| Compose | `GraphOperations.compose(a, b)` |
| Line Graph | `GraphOperations.lineGraph(graph)` |
| Power (k-th) | `GraphOperations.power(graph, k)` |
| Subgraph check | `GraphOperations.isSubgraph(small, large)` |
| Isomorphism | `GraphOperations.isIsomorphic(a, b)` |

### 4.8 Transformations (`lib/transform/`)

| Transform | Function | Complexity |
|-----------|----------|------------|
| Transpose | `GraphTransform.transpose(graph)` | O(1) |
| To directed | `GraphTransform.toDirected(graph)` | O(1) |
| To undirected | `GraphTransform.toUndirected(graph, resolve)` | O(E) |
| Subgraph | `GraphTransform.subgraph(graph, nodeIds)` | O(Vₛ + Eₛ) |
| Ego graph | `GraphTransform.egoGraph(graph, center, radius)` | O(BFS radius) |
| Contract nodes | `GraphTransform.contract(graph, a, b, combine)` | O(deg(a) + deg(b)) |
| Quotient graph | `GraphTransform.quotient(graph, partition, combine)` | O(V + E) |
| Transitive closure | `GraphTransform.transitiveClosure(graph)` | O(V · (V+E)) |
| Transitive reduction | `GraphTransform.transitiveReduction(graph)` | O(V · (V+E)) |
| Map nodes | `GraphTransform.mapNodes(graph, fn)` | O(V) |
| Filter nodes | `GraphTransform.filterNodes(graph, predicate)` | O(V + E) |
| Map edges | `GraphTransform.mapEdges(graph, fn)` | O(E) |
| Filter edges | `GraphTransform.filterEdges(graph, predicate)` | O(E) |
| Relabel nodes | `GraphTransform.relabelNodes(graph, mapping)` | O(V + E) |
| Normalize IDs | `GraphTransform.normalizeNodeIds(graph)` | O(V + E) |

### 4.9 DAG-Specific (`lib/dag/`)

`DagGraph<N, E>` is a wrapper around `Graph<N, E>` that validates acyclicity at construction.

| Algorithm | Function | Complexity |
|-----------|----------|------------|
| Topological sort | `dag.topologicalSort()` | O(V + E) |
| Topological generations | `dag.topologicalGenerations()` | O(V + E) |
| Shortest path | `dag.shortestPath(from, to)` | O(V + E) |
| Longest path | `dag.longestPath(from, to)` | O(V + E) |
| Single-source distances | `dag.singleSourceDistances(from)` | O(V + E) |
| Path count | `dag.pathCount(from, to)` | O(V + E) |
| Sources | `dag.sources()` | O(V) |
| Sinks | `dag.sinks()` | O(V) |
| Ancestors | `dag.ancestors(node)` | O(V + E) |
| Descendants | `dag.descendants(node)` | O(V + E) |
| LCA | `dag.lowestCommonAncestors(a, b)` | O(V · (V+E)) |

### 4.10 Matching (`lib/matching/`)

| Algorithm | Function | Complexity |
|-----------|----------|------------|
| Hopcroft-Karp | `Matching.hopcroftKarp(graph)` | O(E · √V) |

### 4.11 Flow (`lib/flow/`)

| Algorithm | Function | Complexity |
|-----------|----------|------------|
| Edmonds-Karp | `Flow.edmondsKarp(graph, source, sink)` | O(V · E²) |
| Stoer-Wagner | `Flow.stoerWagner(graph)` | O(V · E + V² log V) |

### 4.12 Minimum Spanning Tree (`lib/mst/`)

| Algorithm | Function | Complexity |
|-----------|----------|------------|
| Prim | `MST.prim(graph)` | O(E log V) |
| Kruskal | `MST.kruskal(graph)` | O(E log E) |
| Borůvka | `MST.boruvka(graph)` | O(E log V) |

### 4.13 Multigraph (`lib/multi/`)

`MultiGraph<N, E>` supports parallel edges between the same node pair.

| Feature | Function |
|---------|----------|
| Add edge (allows parallel) | `multiGraph.addEdge(from, to, data)` |
| All edges between pair | `multiGraph.edgesBetween(a, b)` |
| Edge count between pair | `multiGraph.edgeCountBetween(a, b)` |

---

## 5. I/O & Rendering

### 5.1 Export Formats

| Format | Function | Status |
|--------|----------|--------|
| DOT (Graphviz) | `DotRenderer.render(graph, options)` | ⬜ |
| Mermaid.js | `MermaidRenderer.render(graph, options)` | ⬜ |
| JSON (generic) | `GraphJson.toJson(graph)` | ⬜ |
| JSON (D3.js) | `GraphJson.toD3Json(graph)` | ⬜ |
| JSON (Cytoscape) | `GraphJson.toCytoscapeJson(graph)` | ⬜ |
| JSON (NetworkX) | `GraphJson.toNetworkXJson(graph)` | ⬜ |
| Adjacency Matrix | `GraphMatrix.toMatrix(graph)` | ⬜ |
| Adjacency List | `GraphList.toList(graph)` | ⬜ |
| GraphML | `GraphML.write(graph)` | ⬜ |
| GEXF | `GEXF.write(graph)` | ⬜ |
| GDF | `GDF.write(graph)` | ⬜ |
| Pajek (.net) | `Pajek.write(graph)` | ⬜ |
| LEDA | `LEDA.write(graph)` | ⬜ |
| TGF | `TGF.write(graph)` | ⬜ |
| Graph6 / Sparse6 | `Graph6.encode(graph)` | ⬜ |

### 5.2 Import Formats

| Format | Function | Status |
|--------|----------|--------|
| JSON (auto-detect) | `GraphJson.fromJson(json)` | ⬜ |
| Adjacency Matrix | `GraphMatrix.fromMatrix(matrix)` | ⬜ |
| Adjacency List | `GraphList.fromList(list)` | ⬜ |
| GraphML | `GraphML.read(xml)` | ⬜ |
| Graph6 / Sparse6 | `Graph6.decode(string)` | ⬜ |

### 5.3 Renderer Options Pattern

Both DOT and Mermaid use a consistent options + theme system:

```dart
final options = DotOptions.dark()
  .withNodeLabel((id, data) => '$id: $data')
  .withHighlightedNodes({'A', 'B'})
  .withSubgraphs([
    DotSubgraph(name: 'cluster_1', label: 'Team A', nodeIds: {'A', 'B'}),
  ]);

final dot = DotRenderer.render(graph, options);
```

**Adapter functions** convert algorithm results into highlight sets:
- `DotOptions.pathToOptions(path, baseOptions)`
- `DotOptions.communityToOptions(communities, baseOptions)`
- `DotOptions.mstToOptions(mst, baseOptions)`

---

## 6. Dart-Specific Design Decisions

### 6.1 Error Handling

**Decision:** Use exceptions for programmer errors, nullable returns for missing data.

```dart
// Programmer error → Exception
graph.addEdge('A', 'B', weight: 10);  // throws if 'A' or 'B' doesn't exist

// Missing data → Nullable
final path = Pathfinding.dijkstra(graph, from: 'A', to: 'B');
if (path == null) { /* no path exists */ }

// Validation → Exception with clear message
final dag = DagGraph.fromGraph(graph);  // throws CycleDetectedException if cyclic
```

Rationale: Dart idiomatically uses exceptions. The `{:ok, _} / {:error, _}` tuple pattern from Elixir feels foreign in Dart.

### 6.2 Parallelization

**Decision:** Use `Future.wait` + isolates for heavy parallel workloads only.

```dart
// Centrality: parallel Dijkstra from each node
final scores = await Centrality.closeness(graph);  // internally uses Isolate.run
```

**When NOT to parallelize:**
- Single-source algorithms (Dijkstra from one node)
- Small graphs (< 1000 nodes)
- Real-time Flutter UI updates

**When to parallelize:**
- All-pairs shortest paths
- Centrality measures (independent per-node computations)
- Community detection iterations

### 6.3 Generics

```dart
// Node data type N, edge data type E
Graph<String, int> graph = Graph.directed();
graph.addNode('A', data: 'Start Node');
graph.addEdge('A', 'B', weight: 10);

// Unweighted graph: use `Null` or `bool` for E
Graph<String, Null> unweighted = Graph.undirected();
unweighted.addEdge('A', 'B');  // weight is null/omitted
```

### 6.4 Enums

```dart
enum GraphKind { directed, undirected }
enum TraversalOrder { breadthFirst, depthFirst, bestFirst }
enum WalkControl { continueWalk, stopBranch, halt }
enum DotTheme { defaultTheme, dark, minimal, presentation }
```

### 6.5 Extension Methods (Optional)

For discoverability, algorithms can be exposed as extension methods:

```dart
// Alternative to static class
final path = graph.shortestPath(from: 'A', to: 'B');
final scores = graph.betweennessCentrality();
```

**Decision:** Provide both. Static classes for algorithm modules, extension methods for convenience.

---

## 7. Testing Strategy

### 7.1 Test Organization

```
test/
├── graph_test.dart              # Core graph construction, mutation, queries
├── pathfinding/
│   ├── dijkstra_test.dart
│   ├── a_star_test.dart
│   ├── bellman_ford_test.dart
│   ├── floyd_warshall_test.dart
│   └── path_test.dart
├── centrality_test.dart
├── connectivity_test.dart
├── community/
│   ├── louvain_test.dart
│   └── label_propagation_test.dart
├── traversal_test.dart
├── generator/
│   ├── classic_test.dart
│   └── random_test.dart
├── operation_test.dart
├── transform_test.dart
├── dag_test.dart
├── io/
│   ├── json_test.dart
│   └── dot_test.dart
└── support/
    ├── fixtures.dart            # Sample graphs
    └── matchers.dart            # Custom test matchers
```

### 7.2 Test Patterns

**Example-based tests:** Small known graphs with expected outputs.

```dart
test('Dijkstra on linear chain', () {
  final graph = Graph.undirected()
    ..addEdge('A', 'B', weight: 1)
    ..addEdge('B', 'C', weight: 2)
    ..addEdge('C', 'D', weight: 3);

  final path = Pathfinding.dijkstra(graph, from: 'A', to: 'D');
  expect(path.nodes, ['A', 'B', 'C', 'D']);
  expect(path.weight, 6);
});
```

**Property-based tests:** Generate random graphs, verify invariants.

```dart
test('Betweenness sum invariant', () {
  final graph = Generator.complete(5);
  final scores = Centrality.betweenness(graph);
  // In a complete graph, all betweenness scores should be 0
  expect(scores.values.every((s) => s == 0.0), isTrue);
});
```

**Custom matchers:**

```dart
expect(graph, isValidGraph);
expect(path, isShortestPath(graph, from: 'A', to: 'B'));
expect(communities, hasModularityGreaterThan(0.3));
```

---

## 8. Performance Targets

| Graph Size | Target Use Case | Expected Performance |
|-----------|-----------------|---------------------|
| < 100 nodes | UI demos, education | Real-time (< 16ms) |
| 100 – 1,000 nodes | Small networks, dashboards | < 100ms for most algorithms |
| 1,000 – 10,000 nodes | Medium social networks | < 1s for single algorithms; batch acceptable |
| 10,000 – 100,000 nodes | Large networks | Requires isolates; some algorithms may take seconds |
| > 100,000 nodes | Massive networks | **v2 only** — needs FFI to native code |

**Memory target:** A graph with 10K nodes and 100K edges should use < 100MB in pure Dart.

---

## 9. Flutter Integration (v2)

### 9.1 `GraphBrowser` Widget

```dart
GraphBrowser(
  graph: myGraph,
  layout: ForceDirectedLayout(),  // or HierarchicalLayout(), CircularLayout()
  onNodeTap: (nodeId) => showDetails(nodeId),
  onEdgeTap: (from, to) => showEdgeDetails(from, to),
  nodeBuilder: (context, nodeId, nodeData) => MyNodeWidget(...),
  edgeBuilder: (context, from, to, edgeData) => MyEdgeWidget(...),
)
```

### 9.2 Layout Algorithms (v2)

| Layout | Class | Best For |
|--------|-------|----------|
| Force-directed | `ForceDirectedLayout` | General exploratory |
| Hierarchical | `HierarchicalLayout` | DAGs, trees |
| Circular | `CircularLayout` | Small dense graphs |
| Grid | `GridLayout` | Regular structures |
| Radial | `RadialLayout` | Tree-like |

---

## 10. Roadmap

### Phase 1 — Core + Pathfinding (v0.1)
- [ ] `Graph<N, E>` class with dual-indexed adjacency list
- [ ] Builder API: `addNode`, `addEdge`, `removeNode`, `removeEdge`
- [ ] Query API: `successors`, `predecessors`, `neighbors`, `degree`
- [ ] `Path` result class
- [ ] Dijkstra (with `MinHeap`)
- [ ] BFS/DFS traversal
- [ ] Topological sort (Kahn's)
- [ ] Tests for all above

### Phase 2 — Connectivity + Components (v0.2)
- [ ] Tarjan SCC
- [ ] Kosaraju
- [ ] Connected / weakly connected components
- [ ] Bridges + articulation points
- [ ] K-core decomposition

### Phase 3 — Centrality (v0.3)
- [ ] Degree, closeness, harmonic
- [ ] Betweenness (Brandes)
- [ ] PageRank
- [ ] HITS, eigenvector, Katz

### Phase 4 — Community + Generators (v0.4)
- [ ] Louvain, Leiden, label propagation
- [ ] Modularity, triangle counting, clustering coefficient
- [ ] Classic generators (complete, cycle, grid, star, etc.)
- [ ] Random generators (Erdős-Rényi, Barabási-Albert)

### Phase 5 — Operations + Transformations (v0.5)
- [ ] Union, intersection, difference, Cartesian product
- [ ] Transpose, subgraph, ego graph
- [ ] Transitive closure / reduction
- [ ] DAG wrapper + DAG algorithms

### Phase 6 — I/O + Rendering (v0.6)
- [ ] DOT renderer with themes
- [ ] Mermaid renderer with themes
- [ ] JSON export/import (multiple formats)
- [ ] Adjacency matrix/list conversion

### Phase 7 — Advanced Algorithms (v0.7)
- [ ] Matching (Hopcroft-Karp)
- [ ] Flow (Edmonds-Karp, Stoer-Wagner)
- [ ] MST (Prim, Kruskal, Borůvka)
- [ ] Multigraph support

### Phase 8 — Flutter (v1.0)
- [ ] `GraphBrowser` widget
- [ ] Force-directed layout
- [ ] Hierarchical layout
- [ ] Interactive pan/zoom/select

### Phase 9 — Performance (v1.x)
- [ ] `dart:ffi` backend for large graphs
- [ ] Isolated compute for parallel algorithms
- [ ] Streaming algorithms for massive graphs

---

## 11. Comparison: YogEx → Yograph

| Feature | YogEx (Elixir) | Yograph (Dart) | Status |
|--------|---------------|----------------|--------|
| Graph struct | `%Yog.Graph{kind, nodes, out_edges, in_edges}` | `Graph<N, E>` | ⬜ |
| Immutable by default | Yes (functional updates) | No (mutable by default, immutable variants available) | ⬜ |
| Error handling | `{:ok, _} / {:error, _}` tuples | Exceptions + nullable returns | ⬜ |
| Pipeline operator | `\|>` | `..` cascade + method chaining | ⬜ |
| Parallelism | `Task.async_stream` | `Future.wait` + `Isolate.run` | ⬜ |
| Native acceleration | Zig NIFs via `zigler` | `dart:ffi` (v2 only) | ⬜ |
| Protocols | `Enumerable`, `Inspect` | `Iterable`, `toString()` | ⬜ |
| Pairing heap | `Yog.PairingHeap` | Port from `algorithms-in-dart` `MinHeap` | ⬜ |
| Disjoint set | `Yog.DisjointSet` | New implementation | ⬜ |

---

## 12. Open Questions

1. **Should we use a custom `Result<T>` type?** Dart doesn't have built-in Result. Options:
   - Throw exceptions (most idiomatic)
   - Return nullable (`Path?`)
   - Custom `Result<T, E>` class (most explicit, least idiomatic)
   - **Current leaning:** Exceptions for errors, nullable for "not found".

2. **Node ID type: `Object` or generic `ID extends Object`?**
   - `Object` is simpler but loses type safety on algorithm inputs.
   - `ID extends Object` is more type-safe but adds generic noise.
   - **Current leaning:** `Graph<N, E>` with `Object` IDs. A separate `Graph<ID, N, E>` could be added later.

3. **Should `addEdge` auto-create missing nodes?**
   - YogEx has both `add_edge` (strict) and `add_edge_ensure` (auto-creates).
   - **Current leaning:** Yes, `addEdge` auto-creates by default (convenient). `addEdgeStrict` throws if nodes missing.

4. **Package structure: monolithic or multi-package?**
   - Option A: Single `yograph` package with everything.
   - Option B: `yograph_core` + `yograph_flutter`.
   - **Current leaning:** Single package for v0.x. Split only if Flutter widgets bloat the dependency tree.

---

*This document is a living spec. Update it as design decisions are made during implementation.*
