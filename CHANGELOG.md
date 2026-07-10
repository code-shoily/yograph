## 0.5.0 - 2026-07-10

### Weight Algebra

- Add `WeightAlgebra<E>` for typed edge-weight semantics across weighted algorithms.
- Add built-in `DoubleAlgebra`, `IntAlgebra`, and `MaxPlusAlgebra` implementations.
- Update pathfinding, MST, DAG, centrality, health, and all-pairs shortest-path algorithms to accept custom edge-weight algebras.
- Preserve default behavior for `double`, `int`, and unweighted graphs while allowing custom domain-specific edge data.

### Optimization & Generalization

- Optimize [SimpleGraph] operations (`edgeWeight`, `addEdge`, `removeEdge`, `removeNode`) by reducing redundant map lookups.
- Fix nondeterminism bug in [LabelPropagation] by replacing randomized `Object.hash` with a deterministic hash mixer.
- Generalize max-flow, min-cut, and rendering algorithms to accept role-based interfaces ([WeightedWalkable], [Mutable], [Queryable]) instead of concrete [SimpleGraph] parameters.

### Property-Based Testing

- Port Elixir properties and implement property-based tests using `glados` for:
  - [DisjointSet] (symmetry, transitivity, union set count, partitioning coverage)
  - [PriorityQueue] (heap ordering, peek-pop, size invariants, custom max-heap)
  - [Traversal] (BFS uniqueness, DFS-BFS node agreement, correct topological ordering on DAGs)
  - [Pathfinding] (Dijkstra/Bellman-Ford/A* weight agreement, Bidirectional Dijkstra correctness, Floyd-Warshall agreement)
  - [MST] (Prim/Kruskal weight agreement, $V - c$ edge count invariant, cycle-freedom)
  - [Max Flow / Min Cut] (max-flow min-cut duality, node flow conservation, residual graph path termination, zero-flow on disconnected components)
  - [Connectivity] (Tarjan/Kosaraju SCC agreement)
  - [Matching] (maximum matching against a brute-force oracle on small graphs)
  - [Graph I/O] (`edgelist`, `csv`, `adjlist`, and `tgf` round trips)

### Graph Generators

- Add **Classic Generators** (`ClassicGenerator`) for complete, cycle, path, star, wheel, grid2d, complete bipartite, binary tree, Petersen, empty, hypercube, and ladder graphs.
- Add **Random Generators** (`RandomGenerator`) for Erdős-Rényi $G(n, p)$, Erdős-Rényi $G(n, m)$, Barabási-Albert, Watts-Strogatz, random tree, and random regular graphs.
- Add **Maze Generators** (`MazeGenerator`) for Binary Tree, Sidewinder, and Recursive Backtracker perfect mazes.

### Graph I/O

- Add **Graph I/O utility** (`GraphIO`) to read and write graphs in `edgelist`, `csv`, `adjlist`, `tgf`, and `pajek` formats.

### Visualization Renderers

- Add **DOT/Graphviz Renderer** (`DotRenderer`) supporting custom graph attributes, node/edge defaults, nested subgraphs, rank constraints, highlighting, and dynamic attribute callbacks.
- Add **Mermaid.js Renderer** (`MermaidRenderer`) supporting layout directions, node shapes/styles, edge styles, subgraphs, and highlighting.
- Add **SVG Renderer** (`SvgRenderer`) for generating pure XML/SVG layout visualizations from 2D coordinates.

### Pathfinding


- Add **Bidirectional Dijkstra** (`BidirectionalDijkstra.shortestPath()`) for single-pair shortest-path queries on [Bidirectional] graphs; falls back to Dijkstra otherwise.
- Add **Bidirectional BFS** (`BidirectionalBfs.shortestPath()`) for fewest-edge single-pair paths; falls back to unidirectional BFS otherwise.
- Add **Yen's K-Shortest Paths** (`Yen.kShortestPaths()`) for finding up to [k] shortest loopless paths, ordered by weight.

### Documentation

- Update README, `ALGORITHMS.md`, and `roadmap.md` to reflect the new pathfinding algorithms and `WeightAlgebra<E>` support.

## 0.3.0 - Paths, DAGs, Matching, Transforms & Communities

### Pathfinding

- Add **Johnson's algorithm** (`Johnson.allPairs()`, `Johnson.hasNegativeCycle()`) for all-pairs shortest paths on sparse graphs with negative weights (no negative cycles).
- Add **Brandes** accumulation helper for edge-betweenness computations.

### DAG Algorithms

- Add `DAG` static utility class:
  - `isDag`, `topologicalOrder`, `topologicalGenerations`
  - `longestPath`, `longestPathNodes`, `shortestPath`, `singleSourceDistances`
  - `sources`, `sinks`, `ancestors`, `descendants`, `lowestCommonAncestors`, `pathCount`

### Matching

- Add `Matching` static class:
  - `hopcroftKarp` — bipartite maximum cardinality matching
  - `hungarian` — bipartite minimum/maximum weight perfect matching (Kuhn-Munkres)
  - `blossomMaximumMatching` — general graph maximum cardinality matching via Edmonds' blossom algorithm

### Graph Transformations

- Add `Transform` static class:
  - `transitiveClosure` — reachability map with DAG fast-path and BFS fallback
  - `transitiveReduction` — smallest equivalent DAG

### Community Detection

- Add `CommunityResult` and `CommunityDendrogram` result types.
- Add `CommunityMetrics`:
  - `modularity` (undirected and directed)
  - `countTriangles`, `trianglesPerNode`
  - `clusteringCoefficient`, `averageClusteringCoefficient`, `transitivity`
  - `density`, `communityDensity`, `averageCommunityDensity`
  - `nmi` — Normalized Mutual Information for partition comparison
- Add `Community` facade with utility helpers: `toMap`, `sizes`, `largest`, `nodesIn`, `forNode`, `merge`.
- Add community detection algorithms:
  - `LabelPropagation.detect`
  - `Louvain.detect` + `Louvain.detectHierarchical`
  - `Leiden.detect` + `Leiden.detectHierarchical`
  - `Walktrap.detect` + `Walktrap.detectHierarchical`

### Documentation

- Rewrite README feature sections and examples to cover Johnson, DAG, Matching, Transforms, and Community Detection.
- Add `ALGORITHMS.md` catalog documenting all implemented algorithms, return types, and complexities.
- Update `roadmap.md` to mark DAG, Matching, Transforms, and Community Detection sections as completed.

## 0.2.0 - Flows & Grids

- Add Max-Flow algorithms: Edmonds-Karp, Dinic, and Push-Relabel.
- Add Min-Cut algorithms: s-t Min-Cut and global Min-Cut.
- Add `GridBuilder` and `GridGraph` classes for working with 2D grid structures.
- Add AoC examples for 2015-2024.

## 0.1.0 - Foundations

- Create the foundational graph structures and base interfaces.
- Implement the first simple concrete graph implementation: `SimpleGraph`.
- Implement design docs (WIP).
- Add `LabeledBuilder` to allow for `string`-based node id construction.
- Add `walk` and related traversal helpers (`walkUntil`, `foldWalk`, `implicitFold`, etc.)
- Add topological sort implementation.
- Add Disjoint Set Union implementation and Union Find based algorithms.
- Add Kruskal's and Prim's algorithms for MST.
- Add pathfinding implementations - Dijkstra, A*, Bellman-Ford, and Floyd-Warshall.
- Add Centrality algorithms: Degree, Closeness, Harmonic, Betweenness, Pagerank, Eigenvector, Katz, and Hits.
- Add health metrics: Diameter, Local efficiency, and Average local efficiency.
- Add connectivity algorithms: Bridges and articulation points.
