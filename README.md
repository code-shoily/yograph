# Yograph 🌳

> **যোগ** • (*jōg*)
> *noun*
> 1. connection, link, union
> 2. addition, sum

```text
                    ★
                   /|\
                  / | \
                 /  |  \
                Y   |   O--------G
               /    |    \      /
              /     |     \    /
             /      |      \  /
            যো------+-------গ
           / \      |      / \
          /   \     |     /   \
         /     \    |    /     \
        ✦       ✦   |   ✦       ✦
```

[![pub package](https://img.shields.io/pub/v/yograph.svg)](https://pub.dev/packages/yograph)
[![Dart CI](https://github.com/code-shoily/yograph/actions/workflows/dart.yml/badge.svg)](https://github.com/code-shoily/yograph/actions/workflows/dart.yml)

Yograph is a graph theory library for Dart. It provides graph algorithms and data structures through capability-based interfaces.

**[YogEx](https://github.com/code-shoily/yog_ex)** — Elixir implementation with a superset of features.  
**[Yog](https://github.com/code-shoily/yog)** — Gleam implementation with a functional API.

## Features

Yograph includes algorithms for the following areas:

### Pathfinding & Shortest Paths

**Dijkstra** — `Dijkstra.shortestPath()`, `Dijkstra.singleSourceDistances()`  
**A\*** — `AStar.aStar()`, `AStar.implicitAStar()`, `AStar.implicitAStarBy()`  
**Bellman-Ford** — `BellmanFord.shortestPath()`, negative cycle detection  
**Floyd-Warshall** — `FloydWarshall.allPairs()`, all-pairs shortest paths  
**Johnson** — `Johnson.allPairs()`, all-pairs shortest paths with negative weights (no negative cycles)  
**Bidirectional Dijkstra** — `BidirectionalDijkstra.shortestPath()`, faster single-pair search  
**Bidirectional BFS** — `BidirectionalBfs.shortestPath()`, fewest-edge single-pair search  
**Yen's K-Shortest** — `Yen.kShortestPaths()`, up to [k] shortest loopless paths  
**Widest Path** — `Dijkstra.widestPath()`, maximum bottleneck routing  

All pathfinding algorithms support custom semirings via optional `add` and `compare` callbacks.

### Traversal

**BFS & DFS** — `walk()`, `walkUntil()`, `foldWalk()`  
**Best-First** — `bestFirstWalk()`, `bestFirstFold()`  
**Topological Sort** — `topologicalSort()`, `lexicographicalTopologicalSort()`  
**Random Walk** — `randomWalk()` with optional seed  

### Connectivity & Structure

**Connected Components** — `Components.connectedComponents()`, `Components.weaklyConnectedComponents()`  
**Strongly Connected Components** — `SCC.tarjan()`, `SCC.kosaraju()`  
**Bridge & Articulation Point Detection** — `Analysis.analyze()`  
**K-Core Decomposition** — `KCore.detect()`, `KCore.coreNumbers()`, `KCore.degeneracy()`  
**Reachability Counts** — `Reachability.counts()` with DAG fast-path + SCC condensation fallback  
**Structural Predicates** — `Structure.isTree()`, `Structure.isChordal()`, `Structure.isArborescence()`, `Structure.isComplete()`, `Structure.isRegular()`

### Centrality

**Degree** — `Centrality.degree()` with `DegreeMode` (in / out / total)  
**Distance-Based** — `Centrality.closeness()`, `Centrality.harmonic()`, `Centrality.betweenness()` (Brandes' algorithm)  
**Spectral / Iterative** — `Centrality.pageRank()`, `Centrality.eigenvector()`, `Centrality.katz()`, `Centrality.alpha()`  
**Link-Analysis** — `Centrality.hits()` (hub & authority scores)

### Health Metrics

**Distance Metrics** — `Health.diameter()`, `Health.radius()`, `Health.eccentricity()`  
**Structural** — `Health.assortativity()` (Pearson degree correlation)  
**Path Metrics** — `Health.averagePathLength()`  
**Efficiency** — `Health.globalEfficiency()`, `Health.localEfficiency()`, `Health.averageLocalEfficiency()`

### Minimum Spanning Tree

**Kruskal** — `MST.kruskal()`, `MST.kruskalMax()`  
**Prim** — `MST.prim()`, `MST.primMax()`

### DAG Algorithms

**DAG Detection** — `DAG.isDag()`, `DAG.topologicalOrder()`  
**Generations** — `DAG.topologicalGenerations()`  
**Paths** — `DAG.longestPath()`, `DAG.shortestPath()`, `DAG.pathCount()`  
**Distances** — `DAG.singleSourceDistances()`  
**Sources & Sinks** — `DAG.sources()`, `DAG.sinks()`  
**Ancestry** — `DAG.ancestors()`, `DAG.descendants()`, `DAG.lowestCommonAncestors()`

### Matching

**Bipartite Maximum Matching** — `Matching.hopcroftKarp()`  
**Bipartite Minimum/Maximum Weight Perfect Matching** — `Matching.hungarian()`  
**General Maximum Matching** — `Matching.blossomMaximumMatching()` (Edmonds' blossom algorithm)

### Community Detection

**Louvain** — `Community.louvain()` (modularity optimization, hierarchical variant available)  
**Leiden** — `Community.leiden()` (Louvain with refinement, hierarchical variant available)  
**Label Propagation** — `Community.labelPropagation()`  
**Walktrap** — `Community.walktrap()` (random-walk hierarchical clustering)  
**Metrics** — `Community.modularity()`, `Community.clusteringCoefficient()`, `Community.averageClusteringCoefficient()`, `Community.transitivity()`, `Community.countTriangles()`  
**Utilities** — `Community.toMap()`, `Community.sizes()`, `Community.merge()`, `Community.nmi()`

### Graph Transformations

**Transitive Closure** — `Transform.transitiveClosure()`  
**Transitive Reduction** — `Transform.transitiveReduction()`

### Design

**Capability-Based Interfaces** — `Traversable`, `Queryable`, `Mutable`, `Reversible` combine into roles such as `Walkable`, `WeightedWalkable`, and `Bidirectional`.  
**Labeled Builder** — `LabeledBuilder` maps string/enum labels to internal `int` node IDs.  
**Strategy Pattern** — `Pathfinding.shortestPath()` accepts `PointToPointStrategy` implementations.  
**Disjoint Set** — `DisjointSet` with path compression and union by rank.

## Installation

Add yograph to your `pubspec.yaml`:

```yaml
dependencies:
  yograph: ^0.1.0
```

Or via command line:

```sh
dart pub add yograph
```

## Quick Start

```dart
import 'package:yograph/yograph.dart';

void main() {
  // Create a directed graph with String labels on nodes, int weights on edges
  final graph = SimpleGraph<String, int>.directed()
    ..addEdge(0, 1, data: 4)
    ..addEdge(0, 2, data: 2)
    ..addEdge(2, 1, data: 1)
    ..addEdge(1, 3, data: 5)
    ..addEdge(2, 3, data: 8);

  // Find shortest path (default: Dijkstra)
  final path = Pathfinding.shortestPath(graph, 0, 3);
  print(path); // Path(0 -> 2 -> 1 -> 3, weight: 8.0)

  // Use A* with a heuristic
  final astarPath = Pathfinding.shortestPath(
    graph,
    0,
    3,
    strategy: AStar(heuristic: (node, goal) => (goal - node).abs().toDouble()),
  );
  print(astarPath); // Path(0 -> 2 -> 1 -> 3, weight: 8.0)

  // Bellman-Ford handles negative weights
  final bfGraph = SimpleGraph<String, int>.directed()
    ..addEdge(0, 1, data: 4)
    ..addEdge(0, 2, data: 3)
    ..addEdge(1, 2, data: -2)
    ..addEdge(2, 3, data: -3);

  final result = BellmanFord.shortestPath(bfGraph, 0, 3);
  if (result.isSuccess) {
    print(result.path); // Path(0 -> 1 -> 2 -> 3, weight: -1.0)
  } else if (result.hasNegativeCycle) {
    print('Negative cycle detected!');
  }

  // All-pairs shortest paths
  final fw = FloydWarshall.allPairs(graph);
  print(fw.distance(0, 3)); // 8.0

  // Minimum spanning tree (undirected only)
  final undirected = SimpleGraph<String, int>.undirected()
    ..addEdge(0, 1, data: 4)
    ..addEdge(0, 2, data: 1)
    ..addEdge(1, 2, data: 3);

  final mst = MST.kruskal(undirected);
  print(mst.totalWeight); // 4.0

  // Centrality
  final scores = Centrality.betweenness(undirected);
  print(scores); // {0: 0.0, 1: 0.0, 2: 0.0}

  // Health metrics
  print(Health.diameter(undirected)); // 1.0
  print(Health.assortativity(undirected)); // 0.0 (all same degree)

  // Connectivity
  print(Components.connectedComponents(undirected)); // [[0, 1, 2]]
  print(Structure.isTree(undirected)); // false (has a cycle)
}
```

### Using Labels Instead of Integer IDs

```dart
final builder = LabeledBuilder<String, int>.directed()
  ..addEdge('A', 'B', data: 4)
  ..addEdge('A', 'C', data: 2)
  ..addEdge('C', 'B', data: 1);

final graph = builder.toGraph();
final path = Pathfinding.shortestPath(graph, builder.getId('A')!, builder.getId('B')!);
print(path); // Path(0 -> 2 -> 1, weight: 3.0)
```

### Connectivity & Structure

```dart
final graph = SimpleGraph<String, void>.undirected()
  ..addEdge(0, 1)
  ..addEdge(1, 2)
  ..addEdge(2, 0)
  ..addEdge(0, 3);

// Bridges and articulation points
final analysis = Analysis.analyze(graph);
print(analysis.bridges);       // [(0, 3)]
print(analysis.articulationPoints); // {0}

// Strongly connected components (directed)
final directed = SimpleGraph<String, void>.directed()
  ..addEdge(0, 1)
  ..addEdge(1, 2)
  ..addEdge(2, 0)
  ..addEdge(2, 3);

print(SCC.tarjan(directed)); // [[3], [0, 1, 2]]

// K-core decomposition
print(KCore.coreNumbers(graph)); // {0: 2, 1: 2, 2: 2, 3: 1}

// Structural predicates
print(Structure.isChordal(graph)); // true
print(Structure.isComplete(graph)); // false
```

### DAG & Transforms

```dart
final dag = SimpleGraph<String, void>.directed()
  ..addEdge(0, 1)
  ..addEdge(0, 2)
  ..addEdge(1, 3)
  ..addEdge(2, 3)
  ..addEdge(0, 3); // shortcut

// Topological generations
print(DAG.topologicalGenerations(dag)); // [[0], [1, 2], [3]]

// Longest path
print(DAG.longestPath(dag)); // [0, 1, 3] or [0, 2, 3]

// Transitive closure
print(Transform.transitiveClosure(dag));
// {0: {0, 1, 2, 3}, 1: {1, 3}, 2: {2, 3}, 3: {3}}

// Transitive reduction removes the redundant shortcut
final reduced = Transform.transitiveReduction(dag)!;
print(reduced.hasEdge(0, 3)); // false
```

### Community Detection

```dart
final social = SimpleGraph<String, int>.undirected()
  ..addEdge(0, 1, data: 1)
  ..addEdge(1, 2, data: 1)
  ..addEdge(2, 0, data: 1)
  ..addEdge(3, 4, data: 1)
  ..addEdge(4, 5, data: 1)
  ..addEdge(5, 3, data: 1)
  ..addEdge(2, 3, data: 1); // bridge between two cliques

// Louvain modularity optimization
final communities = Community.louvain(social, seed: 42);
print(communities.numCommunities); // 2
print(Community.modularity(social, communities)); // > 0.3

// Clustering metrics
print(Community.transitivity(social)); // global clustering coefficient
print(Community.averageClusteringCoefficient(social));

// Utilities
print(Community.toMap(communities)); // {0: {0, 1, 2}, 1: {3, 4, 5}}
```

### Matching

```dart
// Bipartite maximum cardinality
final bipartite = SimpleGraph<String, void>.undirected()
  ..addEdge(0, 3)
  ..addEdge(0, 4)
  ..addEdge(1, 4)
  ..addEdge(2, 5);

print(Matching.hopcroftKarp(bipartite)); // {0: 3, 1: 4, 2: 5}

// Weighted bipartite matching (Hungarian / Kuhn-Munkres)
final weighted = SimpleGraph<String, int>.undirected()
  ..addEdge(0, 2, data: 1)
  ..addEdge(0, 3, data: 4)
  ..addEdge(1, 2, data: 2)
  ..addEdge(1, 3, data: 3);

final result = Matching.hungarian(weighted, optimization: Optimization.min);
print(result.cost);      // 4.0
print(result.matching);  // {0: 2, 1: 3}

// General graph maximum matching (Edmonds' blossom)
final general = SimpleGraph<String, void>.undirected()
  ..addEdge(0, 1)
  ..addEdge(1, 2)
  ..addEdge(2, 0)
  ..addEdge(2, 3);

print(Matching.blossomMaximumMatching(general)); // {0: 1, 1: 0, 2: 3, 3: 2}
```

## Development

### Running Tests

```sh
# Full test suite
dart test

# With coverage
dart test --coverage=coverage

# Analyze
dart analyze --fatal-infos

# Format check
dart format --output=none --set-exit-if-changed .
```

### Git Pre-Commit Hook

This repository includes a Git pre-commit hook that formats staged `.dart` files and runs `dart analyze` before the commit.

To enable the pre-commit hook in your local clone, run:

```sh
git config core.hooksPath .githooks
```

### Project Structure

- `lib/src/model/` — Capability interfaces (`Traversable`, `Queryable`, `Mutable`, `Reversible`, `Bidirectional`)
- `lib/src/pathfinding/` — Dijkstra, A*, Bellman-Ford, Floyd-Warshall, Johnson
- `lib/src/traversal/` — BFS, DFS, topological sort, random walk
- `lib/src/mst/` — Kruskal's and Prim's MST algorithms
- `lib/src/centrality/` — Brandes' algorithm + degree, closeness, harmonic, betweenness, PageRank, eigenvector, Katz, alpha, HITS
- `lib/src/property/` — Health metrics (`Health`) and structural predicates (`Structure`)
- `lib/src/connectivity/` — Components, SCC (Tarjan / Kosaraju), bridge/articulation-point analysis, K-core, reachability
- `lib/src/dag/` — DAG utilities: topological generations, longest/shortest path, sources/sinks, ancestors/descendants, LCA, path counts
- `lib/src/matching/` — Hopcroft-Karp, Hungarian (Kuhn-Munkres), Edmonds' blossom
- `lib/src/community/` — Louvain, Leiden, label propagation, Walktrap, modularity, clustering, transitivity
- `lib/src/transform/` — Transitive closure and transitive reduction
- `lib/src/builder/` — `LabeledBuilder` for label-based graph construction
- `lib/src/internal/` — Shared utilities (`PriorityQueue`)

## Algorithm Catalog

| Category | Algorithms | Complexity |
|----------|-----------|------------|
| **SSSP** | Dijkstra, A*, Bellman-Ford | O((V+E) log V), O(V×E) |
| **APSP** | Floyd-Warshall, Johnson | O(V³), O(V×E log V) |
| **MST** | Kruskal, Prim | O(E log E), O(E log V) |
| **Traversal** | BFS, DFS, best-first, random walk | O(V+E) |
| **DAG** | Topological sort (Kahn's), generations, longest/shortest path, path count, sources/sinks, ancestors/descendants, LCA | O(V+E) |
| **Union-Find** | Disjoint Set | O(α(V)) amortized |
| **Centrality** | Degree, closeness, harmonic, betweenness (Brandes), PageRank, eigenvector, Katz, alpha, HITS | O(V×E) – O(V³) |
| **Health** | Diameter, radius, eccentricity, assortativity, APL, global/local efficiency | O(V×(V+E) log V) |
| **Components** | Connected, weakly connected | O(V+E) |
| **SCC** | Tarjan, Kosaraju | O(V+E) |
| **Analysis** | Bridges, articulation points | O(V+E) |
| **K-Core** | Core numbers, degeneracy, shell decomposition | O(V+E) |
| **Reachability** | Ancestor/descendant counts (exact), transitive closure | O(V+E) |
| **Structure** | Tree, forest, arborescence, complete, regular, chordal | O(V+E) |
| **Matching** | Hopcroft-Karp, Hungarian (Kuhn-Munkres), Edmonds' blossom | O(E√V), O(V³), O(V⁴) |
| **Community** | Louvain, Leiden, label propagation, Walktrap, modularity, clustering, transitivity | O(E) – O(V² log V) |
| **Transforms** | Transitive closure, transitive reduction | O(V+E), O(V×(V+E)) |

For more details on individual algorithms, see [ALGORITHMS.md](ALGORITHMS.md).

## Related Projects

- **[YogEx](https://github.com/code-shoily/yog_ex)** — Elixir graph library (superset of features)
- **[Yog](https://github.com/code-shoily/yog)** — Gleam graph library (functional API)

## License

MIT

---

**Yograph** — Graph algorithms for Dart
