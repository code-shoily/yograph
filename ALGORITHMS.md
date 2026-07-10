# Yograph Algorithm Catalog

This document provides a detailed inventory of the graph algorithms implemented in Yograph, their capabilities, return types, and complexity notes.

For installation and usage examples, see [README.md](README.md).

## Table of Contents

- [Pathfinding & Shortest Paths](#pathfinding--shortest-paths)
- [Traversal](#traversal)
- [Connectivity & Structure](#connectivity--structure)
- [Centrality](#centrality)
- [Health & Quality Metrics](#health--quality-metrics)
- [Minimum Spanning Tree](#minimum-spanning-tree)
- [DAG Algorithms](#dag-algorithms)
- [Matching](#matching)
- [Community Detection](#community-detection)
- [Graph Transformations](#graph-transformations)

---

## Pathfinding & Shortest Paths

Shortest path algorithms operate on `WeightedWalkable<N, E>` graphs. Point-to-point paths and single-source distances preserve the typed accumulated weight `E` through `WeightAlgebra<E>`. Some all-pairs algorithms expose scalar distance matrices via `WeightAlgebra.toDouble`.

| Algorithm | Entry Point | Supports Negative Weights | Negative Cycle Detection | Notes |
|-----------|-------------|---------------------------|--------------------------|-------|
| **Dijkstra** | `Dijkstra.shortestPath()`, `Dijkstra.singleSourceDistances()`, `Dijkstra.widestPath()` | No | No | Uses a binary heap priority queue; optional `WeightAlgebra<E>` for custom edge-weight semantics. |
| **A\*** | `AStar.aStar()`, `AStar.implicitAStar()`, `AStar.implicitAStarBy()` | No | No | Admissible heuristic required for optimality; implicit variants build neighbors on demand. |
| **Bellman-Ford** | `BellmanFord.shortestPath()` | Yes | Yes | Returns success path, negative-cycle, or unreachable result. |
| **Floyd-Warshall** | `FloydWarshall.allPairs()` | Yes | Yes | Dense APSP; returns full distance matrix. |
| **Johnson** | `Johnson.allPairs()`, `Johnson.hasNegativeCycle()` | Yes | Yes | Sparse APSP via Bellman-Ford potentials + Dijkstra per node. |
| **Bidirectional Dijkstra** | `BidirectionalDijkstra.shortestPath()` | No | No | Simultaneous forward/backward search; falls back to Dijkstra on non-[Bidirectional] graphs. |
| **Bidirectional BFS** | `BidirectionalBfs.shortestPath()` | No | No | Fewest-edge path; falls back to unidirectional BFS on non-[Bidirectional] graphs. |
| **Yen's K-Shortest** | `Yen.kShortestPaths()` | No | No | Returns up to [k] shortest loopless paths, ordered by weight. |
| **Strategy Router** | `Pathfinding.shortestPath()` | No | No | Default strategy is Dijkstra; accepts pluggable `PointToPointStrategy`. |

### Complexity

- Dijkstra: `O((V + E) log V)`
- A\*: `O((V + E) log V)` worst case, typically sublinear in explored nodes
- Bellman-Ford: `O(V × E)`
- Floyd-Warshall: `O(V³)`
- Johnson: `O(V × E log V)` with Fibonacci-style heap; `O(V × E + V² log V)` amortized for non-negative reweighted edges
- Bidirectional Dijkstra: `O((V + E) log V)` worst case, typically visits far fewer nodes
- Bidirectional BFS: `O(V + E)` worst case, typically visits far fewer nodes
- Yen's K-Shortest: `O(k × N × (E + V log V))`

---

## Traversal

| Algorithm | Entry Point | Order | Notes |
|-----------|-------------|-------|-------|
| **BFS** | `walk(strategy: BreadthFirst())` | FIFO | Level-order exploration. |
| **DFS** | `walk(strategy: DepthFirst())` | LIFO | Pre-order style via explicit stack. |
| **Best-First** | `bestFirstWalk()`, `bestFirstFold()` | Priority queue | Greedy node expansion by heuristic. |
| **Topological Sort** | `topologicalSort()`, `lexicographicalTopologicalSort()` | Kahn's algorithm | Returns `null` for cyclic graphs. |
| **Random Walk** | `randomWalk()` | Random | Deterministic with optional seed. |
| **Generic Walk** | `walk()`, `walkUntil()`, `foldWalk()` | Configurable | Visitor API with start node and termination predicate. |

### Complexity

All traversal algorithms are `O(V + E)` for the portion of the graph explored.

---

## Connectivity & Structure

| Algorithm | Entry Point | Complexity | Notes |
|-----------|-------------|------------|-------|
| **Connected Components** | `Components.connectedComponents()` | `O(V + E)` | Undirected graphs only. |
| **Weakly Connected Components** | `Components.weaklyConnectedComponents()` | `O(V + E)` | Treats directed graph as undirected. |
| **Strongly Connected Components (Tarjan)** | `SCC.tarjan()` | `O(V + E)` | Single DFS pass. |
| **Strongly Connected Components (Kosaraju)** | `SCC.kosaraju()` | `O(V + E)` | Two-pass DFS on graph and transpose. |
| **Bridge & Articulation Points** | `Analysis.analyze()` | `O(V + E)` | Low-link DFS algorithm. |
| **K-Core Decomposition** | `KCore.detect()`, `KCore.coreNumbers()`, `KCore.degeneracy()` | `O(V + E)` | Iterative smallest-degree removal. |
| **Reachability Counts** | `Reachability.counts()` | `O(V + E)` DAG; fallback to SCC condensation | Counts ancestors and descendants for every node. |
| **Tree** | `Structure.isTree()` | `O(V + E)` | Connected acyclic undirected graph. |
| **Forest** | `Structure.isForest()` | `O(V + E)` | Acyclic undirected graph. |
| **Arborescence** | `Structure.isArborescence()` | `O(V + E)` | Rooted directed tree reaching all nodes. |
| **Complete** | `Structure.isComplete()` | `O(V + E)` | Every pair of distinct nodes has an edge. |
| **Regular** | `Structure.isRegular()` | `O(V + E)` | All vertices share the same degree. |
| **Chordal** | `Structure.isChordal()` | `O(V + E)` | Perfect elimination ordering via MCS. |

---

## Centrality

| Algorithm | Entry Point | Complexity | Notes |
|-----------|-------------|------------|-------|
| **Degree** | `Centrality.degree()` | `O(V + E)` | In-, out-, or total degree. |
| **Closeness** | `Centrality.closeness()` | `O(V × (V + E) log V)` | Reciprocal of average shortest-path distance. |
| **Harmonic** | `Centrality.harmonic()` | `O(V × (V + E) log V)` | Handles disconnected graphs. |
| **Betweenness** | `Centrality.betweenness()` | `O(V × E)` unweighted; `O(V × (V + E) log V)` weighted | Brandes' algorithm. |
| **PageRank** | `Centrality.pageRank()` | `O(k × (V + E))` | Iterative power method with damping. |
| **Eigenvector** | `Centrality.eigenvector()` | `O(k × V²)` | Power iteration on adjacency. |
| **Katz** | `Centrality.katz()` | `O(k × V²)` | Attenuated centrality with alpha parameter. |
| **Alpha** | `Centrality.alpha()` | `O(k × V²)` | Alpha centrality variant. |
| **HITS** | `Centrality.hits()` | `O(k × (V + E))` | Hub and authority scores via mutual recursion. |

---

## Health & Quality Metrics

| Metric | Entry Point | Complexity | Notes |
|--------|-------------|------------|-------|
| **Diameter** | `Health.diameter()` | `O(V × (V + E) log V)` | Longest shortest-path distance. |
| **Radius** | `Health.radius()` | `O(V × (V + E) log V)` | Minimum eccentricity. |
| **Eccentricity** | `Health.eccentricity()` | `O(V × (V + E) log V)` | Maximum distance from a node. |
| **Average Path Length** | `Health.averagePathLength()` | `O(V × (V + E) log V)` | Mean shortest-path distance. |
| **Global Efficiency** | `Health.globalEfficiency()` | `O(V × (V + E) log V)` | Average inverse shortest-path distance. |
| **Local Efficiency** | `Health.localEfficiency()` | `O(V² × (V + E) log V)` | Efficiency of node neighborhoods. |
| **Assortativity** | `Health.assortativity()` | `O(V + E)` | Pearson degree correlation. |

---

## Minimum Spanning Tree

| Algorithm | Entry Point | Complexity | Notes |
|-----------|-------------|------------|-------|
| **Kruskal** | `MST.kruskal()`, `MST.kruskalMax()` | `O(E log E)` | Sorting + disjoint set. |
| **Prim** | `MST.prim()`, `MST.primMax()` | `O(E log V)` | Priority queue from arbitrary start. |

Both algorithms operate on undirected weighted graphs and return an `MSTResult` containing the total weight and edge list.

---

## DAG Algorithms

All DAG utilities return `null` or empty results when the input graph is not a directed acyclic graph.

| Algorithm | Entry Point | Complexity | Notes |
|-----------|-------------|------------|-------|
| **DAG Check** | `DAG.isDag()` | `O(V + E)` | Checks directedness and acyclicity. |
| **Topological Order** | `DAG.topologicalOrder()` | `O(V + E)` | Returns Kahn's ordering. |
| **Topological Generations** | `DAG.topologicalGenerations()` | `O(V + E)` | Antichain layers of the DAG. |
| **Longest Path** | `DAG.longestPath()` | `O(V + E)` | DP over topological order. |
| **Longest Path Nodes** | `DAG.longestPathNodes(from, to)` | `O(V + E)` | Reconstructs node path. |
| **Shortest Path** | `DAG.shortestPath(from, to)` | `O(V + E)` | DP over topological order. |
| **Single Source Distances** | `DAG.singleSourceDistances(from)` | `O(V + E)` | All distances from one source. |
| **Sources** | `DAG.sources()` | `O(V + E)` | Nodes with no incoming edges. |
| **Sinks** | `DAG.sinks()` | `O(V + E)` | Nodes with no outgoing edges. |
| **Ancestors** | `DAG.ancestors(node)` | `O(V + E)` | All nodes that can reach `node`. |
| **Descendants** | `DAG.descendants(node)` | `O(V + E)` | All nodes reachable from `node`. |
| **Lowest Common Ancestors** | `DAG.lowestCommonAncestors(a, b)` | `O(V + E)` | Minimal common ancestors. |
| **Path Count** | `DAG.pathCount(from, to)` | `O(V + E)` | Number of directed paths. |

---

## Matching

| Algorithm | Entry Point | Graph Class | Complexity | Notes |
|-----------|-------------|-------------|------------|-------|
| **Hopcroft-Karp** | `Matching.hopcroftKarp()` | Bipartite undirected | `O(E √V)` | Maximum cardinality matching. |
| **Hungarian (Kuhn-Munkres)** | `Matching.hungarian()` | Bipartite weighted | `O(V² × E)` or `O(V³)` dense | Minimum/maximum weight perfect matching. |
| **Edmonds' Blossom** | `Matching.blossomMaximumMatching()` | General undirected | `O(V⁴)` simple implementation | Maximum cardinality matching in non-bipartite graphs. |

`hopcroftKarp` and `blossomMaximumMatching` return a symmetric `Map<int, int>` of node pairings. `Matching.hungarian` returns a `HungarianResult` with `cost` and `matching`.

---

## Community Detection

All community algorithms operate on `Bidirectional<N, E>` graphs and return either a `CommunityResult` (node → community assignment) or a `CommunityDendrogram` (hierarchical sequence of results).

| Algorithm | Entry Point | Output | Complexity | Notes |
|-----------|-------------|--------|------------|-------|
| **Louvain** | `Community.louvain()`, `Louvain.detect()` | `CommunityResult` | `O(E × iterations)` typical | Modularity optimization with local moving + aggregation. |
| **Leiden** | `Community.leiden()`, `Leiden.detect()` | `CommunityResult` | `O(E × iterations)` typical | Louvain with refinement phase for well-connected communities. |
| **Label Propagation** | `Community.labelPropagation()`, `LabelPropagation.detect()` | `CommunityResult` | `O(E × iterations)` | Asynchronous label updates. |
| **Walktrap** | `Community.walktrap()`, `Walktrap.detect()` | `CommunityResult` | `O(V² log V)` hierarchical | Random-walk distance + agglomerative clustering. |
| **Modularity** | `Community.modularity()`, `CommunityMetrics.modularity()` | `double` | `O(V + E)` | Quality score for a partition; undirected and directed support. |
| **Clustering Coefficient** | `Community.clusteringCoefficient()` | `double` (per node) | `O(deg(v)²)` | Watts-Strogatz local clustering. |
| **Average Clustering** | `Community.averageClusteringCoefficient()` | `double` | `O(V × E)` | Mean local clustering coefficient. |
| **Transitivity** | `Community.transitivity()` | `double` | `O(V × E)` | Global clustering coefficient (`3×triangles / triples`). |
| **Triangle Counts** | `Community.countTriangles()`, `Community.trianglesPerNode()` | `int` / `Map<int, int>` | `O(V × E)` | Neighbor-intersection counting. |
| **Density** | `Community.density()`, `Community.communityDensity()` | `double` | `O(V + E)` | Graph and per-community density. |
| **NMI** | `Community.nmi()` | `double` | `O(V)` | Normalized Mutual Information between two partitions. |
| **Utilities** | `Community.toMap()`, `Community.sizes()`, `Community.merge()`, `Community.largest()` | various | `O(V)` | Community-centric helpers. |

Hierarchical variants (`Louvain.detectHierarchical`, `Leiden.detectHierarchical`, `Walktrap.detectHierarchical`) return `CommunityDendrogram` with levels ordered finest → coarsest.

---

## Graph Transformations

| Operation | Entry Point | Input | Output | Complexity | Notes |
|-----------|-------------|-------|--------|------------|-------|
| **Transitive Closure** | `Transform.transitiveClosure()` | `Bidirectional<N, E>` | `Map<int, Set<int>>` | `O(V + E)` DAG; `O(V × (V + E))` cyclic fallback | Maps each node to all reachable nodes, including itself. |
| **Transitive Reduction** | `Transform.transitiveReduction()` | `Bidirectional<N, E>` directed acyclic | `SimpleGraph<N, E>?` | `O(V × (V + E))` | Smallest equivalent DAG; returns `null` for cyclic or undirected graphs. |

The closure returns a map rather than a graph because closure edges have no natural user-supplied `E` payload. A future overload may accept `E Function(int from, int to) closureEdgeData` for graph construction.

---

## Capability-Based Roles

Yograph algorithms are decoupled from concrete graph implementations through capability interfaces:

| Role | Provides | Used By |
|------|----------|---------|
| `Traversable` | Iterate neighbors | BFS, DFS, topological sort |
| `Queryable` | Check node/edge existence | Analysis, Structure |
| `Mutable` | Add/remove nodes and edges | Builders, transforms |
| `Reversible` | Reverse iteration (predecessors) | Kosaraju, flow algorithms |
| `Walkable` | `Traversable + Queryable` | Most traversal and connectivity algorithms |
| `WeightedWalkable` | `Walkable + edge weights` | All shortest-path and MST algorithms |
| `Bidirectional` | `Walkable + successors/predecessors` | DAG utilities, matching, transforms, community detection |

`SimpleGraph` implements all roles and is the default implementation. Custom graph backends can implement the relevant roles to reuse Yograph algorithms without data duplication.

---

## Complexity Legend

- `V` — number of vertices (nodes)
- `E` — number of edges
- `k` — number of iterations (for iterative / power-method algorithms)
- `α(V)` — inverse Ackermann function, effectively < 5 for all practical inputs

---

## Contributing Algorithms

When adding a new algorithm:

1. Prefer `WeightedWalkable` or `Bidirectional` over `SimpleGraph` when possible.
2. Return a result object or clear sentinel values rather than throwing.
3. Document expected preconditions (e.g., DAG-only, undirected-only) in doc comments.
4. Add tests under `test/<category>/` mirroring existing patterns.
5. Update this file and the README Algorithm Catalog table.
6. Run `dart analyze`, `dart format`, and `dart test` before committing.

For the pre-commit hook, see [README.md#git-pre-commit-hook](README.md#git-pre-commit-hook).
