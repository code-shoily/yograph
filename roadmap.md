# Yograph Roadmap 🗺️

This document outlines the visual gap analysis and algorithm feature parity between the pure-Elixir **[YogEx](https://github.com/code-shoily/yog_ex)** library (the superset reference) and the Dart **[yograph](https://github.com/code-shoily/yograph)** library.

Our goal is systematic functional parity with identical modular structures and robust, high-performance graph verification.

---

## 🚦 Parity Status Legend
- `[x]` **Completed**: Ported, optimized, fully tested, and verified with **>90% test coverage**.
- `[ ]` **Planned**: Scheduled for upcoming releases.

---

## 1. Pathfinding & Shortest Paths
| Algorithm | Elixir Module | Dart Support | Status |
| :--- | :--- | :--- | :---: |
| **Dijkstra** | `Yog.Pathfinding.Dijkstra` | `Dijkstra` | `[x]` |
| **A\*** | `Yog.Pathfinding.AStar` | `AStar` | `[x]` |
| **Bellman-Ford** | `Yog.Pathfinding.BellmanFord` | `BellmanFord` | `[x]` |
| **Floyd-Warshall** | `Yog.Pathfinding.FloydWarshall` | `FloydWarshall` | `[x]` |
| **Widest Path** | `Yog.Pathfinding` | `Dijkstra.widestPath` | `[x]` |
| **Unweighted SSSP** | `Yog.Pathfinding` | `Traversal` / BFS shortest path | `[x]` |
| **Johnson's** | `Yog.Pathfinding.Johnson` | `Johnson` | `[x]` |
| **Bidirectional Dijkstra** | `Yog.Pathfinding.Bidirectional` | - | `[ ]` |
| **Bidirectional BFS** | `Yog.Pathfinding.Bidirectional` | - | `[ ]` |
| **Yen's K-Shortest** | `Yog.Pathfinding.Yen` | - | `[ ]` |
| **Brandes SSSP** | `Yog.Pathfinding.Brandes` | `Brandes` (Accumulation) | `[x]` |
| **Chinese Postman** | `Yog.Pathfinding.ChinesePostman` | - | `[ ]` |
| **LCA (Binary Lifting)** | `Yog.Pathfinding.LCA` | - | `[ ]` |

---

## 2. Spanning Trees
| Algorithm | Elixir Module | Dart Support | Status |
| :--- | :--- | :--- | :---: |
| **Kruskal's** | `Yog.MST` | `MST.kruskal` | `[x]` |
| **Prim's** | `Yog.MST` | `MST.prim` | `[x]` |
| **Max Spanning Tree** | `Yog.MST` | `MST.kruskalMax` / `MST.primMax` | `[x]` |
| **Borůvka's** | `Yog.MST` | - | `[ ]` |
| **Edmonds' (Directed)** | `Yog.MST` | - | `[ ]` |
| **Wilson's (Uniform)** | `Yog.MST` | - | `[ ]` |

---

## 3. Matching
| Algorithm | Elixir Module | Dart Support | Status |
| :--- | :--- | :--- | :---: |
| **Hopcroft–Karp** | `Yog.Matching` | `Matching.hopcroftKarp` | `[x]` |
| **Hungarian** | `Yog.Matching` | `Matching.hungarian` | `[x]` |
| **Blossom (Edmonds)** | `Yog.Matching` | `Matching.blossomMaximumMatching` | `[x]` |
| **Bipartite Maximum Matching** | `Yog.Property.Bipartite` | `Bipartite.maximumMatching` | `[x]` |
| **Stable Marriage** | `Yog.Property.Bipartite` | `Bipartite.stableMarriage` | `[x]` |

---

## 4. Connectivity & Components
| Algorithm | Elixir Module | Dart Support | Status |
| :--- | :--- | :--- | :---: |
| **Connected Components** | `Yog.Connectivity` | `Components.connectedComponents` | `[x]` |
| **Weakly Connected** | `Yog.Connectivity.Components` | `Components.weaklyConnectedComponents` | `[x]` |
| **Tarjan's SCC** | `Yog.Connectivity` | `SCC.tarjan` | `[x]` |
| **Kosaraju's SCC** | `Yog.Connectivity` | `SCC.kosaraju` | `[x]` |
| **Tarjan's Bridges** | `Yog.Connectivity.Analysis` | `Analysis.analyze` (bridges) | `[x]` |
| **Tarjan's Articulation** | `Yog.Connectivity.Analysis` | `Analysis.analyze` (articulationPoints) | `[x]` |
| **K-Core Decomposition** | `Yog.Connectivity.KCore` | `KCore.detect` / `coreNumbers` | `[x]` |
| **Reachability Exact** | `Yog.Connectivity.Reachability` | `Reachability.counts` | `[x]` |
| **Reachability HLL** | `Yog.Connectivity.Reachability` | - | `[ ]` |

---

## 5. Centrality Measures
| Algorithm | Elixir Module | Dart Support | Status |
| :--- | :--- | :--- | :---: |
| **Degree Centrality** | `Yog.Centrality` | `Centrality.degree` | `[x]` |
| **Closeness Centrality** | `Yog.Centrality` | `Centrality.closeness` | `[x]` |
| **Harmonic Centrality** | `Yog.Centrality` | `Centrality.harmonic` | `[x]` |
| **Betweenness Centrality** | `Yog.Centrality` | `Centrality.betweenness` | `[x]` |
| **PageRank** | `Yog.Centrality` | `Centrality.pageRank` | `[x]` |
| **HITS** | `Yog.Centrality` | `Centrality.hits` | `[x]` |
| **Eigenvector Centrality** | `Yog.Centrality` | `Centrality.eigenvector` | `[x]` |
| **Katz Centrality** | `Yog.Centrality` | `Centrality.katz` | `[x]` |
| **Alpha Centrality** | `Yog.Centrality` | `Centrality.alpha` | `[x]` |

---

## 6. Traversal & Search
| Algorithm | Elixir Module | Dart Support | Status |
| :--- | :--- | :--- | :---: |
| **BFS** | `Yog.Traversal` | `walk` (BFS mode) | `[x]` |
| **DFS** | `Yog.Traversal` | `walk` (DFS mode) | `[x]` |
| **Topological Sort** | `Yog.Traversal` | `topologicalSort` | `[x]` |
| **Kahn's Algorithm** | `Yog.Traversal.Sort` | `topologicalSort` | `[x]` |
| **Lexicographical TopSort** | `Yog.Traversal.Sort` | `lexicographicalTopologicalSort` | `[x]` |
| **Best-First Walk** | `Yog.Traversal.Walk` | `bestFirstWalk` | `[x]` |
| **Random Walk** | `Yog.Traversal.Walk` | `randomWalk` | `[x]` |

---

## 7. DAG Algorithms
| Algorithm | Elixir Module | Dart Support | Status |
| :--- | :--- | :--- | :---: |
| **DAG Validation** | `Yog.DAG` / `Yog.Property.Cyclicity` | `DAG.isDag` | `[x]` |
| **Topological Sort** | `Yog.Traversal` | `topologicalSort` | `[x]` |
| **Topological Generations** | `Yog.DAG` | `DAG.topologicalGenerations` | `[x]` |
| **Sources / Sinks** | `Yog.DAG` | `DAG.sources` / `DAG.sinks` | `[x]` |
| **Single-Source Distances** | `Yog.DAG.Algorithm` | `DAG.singleSourceDistances` | `[x]` |
| **Shortest Path** | `Yog.DAG.Algorithm` | `DAG.shortestPath` | `[x]` |
| **Longest Path** | `Yog.DAG.Algorithm` | `DAG.longestPath` / `DAG.longestPathNodes` | `[x]` |
| **Ancestors / Descendants** | `Yog.DAG` | `DAG.ancestors` / `DAG.descendants` | `[x]` |
| **Lowest Common Ancestors** | `Yog.DAG` | `DAG.lowestCommonAncestors` | `[x]` |
| **Path Count** | `Yog.DAG.Algorithm` | `DAG.pathCount` | `[x]` |
| **Transitive Closure** | `Yog.Transform` | `Transform.transitiveClosure` | `[x]` |
| **Transitive Reduction** | `Yog.Transform` | `Transform.transitiveReduction` | `[x]` |

---

## 8. Structural Properties
| Algorithm | Elixir Module | Dart Support | Status |
| :--- | :--- | :--- | :---: |
| **Bipartite Check / Coloring**| `Yog.Property.Bipartite` | `Bipartite.isBipartite` / `coloring` | `[x]` |
| **Max Bipartite Matching** | `Yog.Property.Bipartite` | `Bipartite.maximumMatching` | `[x]` |
| **Stable Marriage** | `Yog.Property.Bipartite` | `Bipartite.stableMarriage` (Gale-Shapley) | `[x]` |
| **Acyclicity Check** | `Yog.Property.Cyclicity` | `Cyclicity.isCyclic` / `isAcyclic` | `[x]` |
| **Eulerian Circuit & Path** | `Yog.Property.Eulerian` | `Eulerian.eulerianCircuit` / `eulerianPath` | `[x]` |
| **Bron-Kerbosch (Clique)** | `Yog.Property.Clique` | `Clique.allMaximalCliques` / `maxClique`| `[x]` |
| **Complete Graph Check** | `Yog.Property.Structure` | `Structure.isComplete` | `[x]` |
| **Tree Check** | `Yog.Property.Structure` | `Structure.isTree` | `[x]` |
| **Forest Check** | `Yog.Property.Structure` | `Structure.isForest` | `[x]` |
| **Branching Check** | `Yog.Property.Structure` | `Structure.isBranching` | `[x]` |
| **Chordality Test** | `Yog.Property.Structure` | `Structure.isChordal` | `[x]` |
| **Regular Graph Check** | `Yog.Property.Structure` | `Structure.isRegular` | `[x]` |
| **Isomorphism (WL)** | `Yog.Property` | - | `[ ]` |
| **Graph Hash** | `Yog.Property` | - | `[ ]` |
| **Planarity LR-Test** | `Yog.Property.Structure` | - | `[ ]` |

---

## 9. Network Flows & Cuts
| Algorithm | Elixir Module | Dart Support | Status |
| :--- | :--- | :--- | :---: |
| **Edmonds-Karp** | `Yog.Flow.MaxFlow` | `MaxFlow.edmondsKarp` | `[x]` |
| **Dinic's** | `Yog.Flow.MaxFlow` | `MaxFlow.dinic` | `[x]` |
| **Push-Relabel** | `Yog.Flow.MaxFlow` | `MaxFlow.pushRelabel` | `[x]` |
| **Successive Shortest Path** | `Yog.Flow.SuccessiveShortestPath`| - | `[ ]` |
| **Stoer-Wagner** | `Yog.Flow.MinCut` | `MinCut.globalMinCut` | `[x]` |
| **s-t Min-Cut** | `Yog.Flow.MinCut` | `MinCut.stMinCut` | `[x]` |

---

## 10. Community Detection & Metrics
| Algorithm | Elixir Module | Dart Support | Status |
| :--- | :--- | :--- | :---: |
| **Louvain** | `Yog.Community.Louvain` | `Community.louvain` / `Louvain.detect` | `[x]` |
| **Leiden** | `Yog.Community.Leiden` | `Community.leiden` / `Leiden.detect` | `[x]` |
| **Label Propagation** | `Yog.Community.LabelPropagation`| `Community.labelPropagation` / `LabelPropagation.detect` | `[x]` |
| **Walktrap** | `Yog.Community.Walktrap`| `Community.walktrap` / `Walktrap.detect` | `[x]` |
| **Transitivity** | `Yog.Community.Metrics` | `Community.transitivity` / `CommunityMetrics.transitivity` | `[x]` |
| **Clustering Coefficient** | `Yog.Community` | `Community.clusteringCoefficient` / `CommunityMetrics.clusteringCoefficient` | `[x]` |
| **Modularity** | `Yog.Community` | `Community.modularity` / `CommunityMetrics.modularity` | `[x]` |

---

## 11. Data Structures
| Structure | Elixir Module | Dart Support | Status |
| :--- | :--- | :--- | :---: |
| **Disjoint Set** | `Yog.DisjointSet` | `DisjointSet` | `[x]` |
| **Priority Queue** | `Yog.PairingHeap` | `PriorityQueue` (heap-backed) | `[x]` |
| **HyperLogLog** | `Reachability.HLL` | - | `[ ]` |

---

## 12. Builders & Generators
| Builder / Generator | Elixir Module | Dart Support | Status |
| :--- | :--- | :--- | :---: |
| **Labeled Graph Builder** | `Yog.Builder.Labeled` | `LabeledBuilder` | `[x]` |
| **2D Grid Graph Builder** | `Yog.Builder.Grid` / `GridGraph` | `GridBuilder` / `GridGraph` | `[x]` |
