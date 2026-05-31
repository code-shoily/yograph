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

Yograph is a comprehensive graph theory library for Dart, providing classic and research-grade graph algorithms with a clean, capability-based API.

**[YogEx](https://github.com/code-shoily/yog_ex)** — Elixir implementation with a superset of features.  
**[Yog](https://github.com/code-shoily/yog)** — Gleam implementation with a functional API.

## Features

Yograph provides balanced graph algorithms across multiple domains:

### Pathfinding & Shortest Paths

**Dijkstra** — `Dijkstra.shortestPath()`, `Dijkstra.singleSourceDistances()`  
**A\*** — `AStar.aStar()`, `AStar.implicitAStar()`, `AStar.implicitAStarBy()`  
**Bellman-Ford** — `BellmanFord.shortestPath()`, negative cycle detection  
**Floyd-Warshall** — `FloydWarshall.allPairs()`, all-pairs shortest paths  
**Widest Path** — `Dijkstra.widestPath()`, maximum bottleneck routing

All pathfinding algorithms support custom semirings via optional `add` and `compare` callbacks.

### Traversal

**BFS & DFS** — `walk()`, `walkUntil()`, `foldWalk()`  
**Best-First** — `bestFirstWalk()`, `bestFirstFold()`  
**Topological Sort** — `topologicalSort()`, `lexicographicalTopologicalSort()`  
**Random Walk** — `randomWalk()` with seeded reproducibility

### Connectivity & Structure

**Minimum Spanning Tree** — `MST.kruskal()`, `MST.prim()`, min/max variants  
**Disjoint Set** — `DisjointSet` with path compression and union by rank

### Developer Experience

**Capability-Based Interfaces** — `Traversable`, `Queryable`, `Mutable`, `Reversible` compose into role interfaces like `Walkable`, `WeightedWalkable`, `Bidirectional`  
**Labeled Builder** — `LabeledBuilder` bridges ergonomic string/enum labels to internal `int` node IDs  
**Strategy Pattern** — `Pathfinding.shortestPath()` accepts pluggable `PointToPointStrategy` implementations

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

### Project Structure

- `lib/src/model/` — Capability interfaces (`Traversable`, `Queryable`, `Mutable`, etc.)
- `lib/src/pathfinding/` — Dijkstra, A*, Bellman-Ford, Floyd-Warshall
- `lib/src/traversal/` — BFS, DFS, topological sort, random walk
- `lib/src/mst/` — Kruskal's and Prim's MST algorithms
- `lib/src/builder/` — `LabeledBuilder` for ergonomic graph construction
- `lib/src/internal/` — Shared utilities (`PriorityQueue`)

## Algorithm Catalog

| Category | Algorithms | Complexity |
|----------|-----------|------------|
| **SSSP** | Dijkstra, A*, Bellman-Ford | O((V+E) log V), O(V×E) |
| **APSP** | Floyd-Warshall | O(V³) |
| **MST** | Kruskal, Prim | O(E log E), O(E log V) |
| **Traversal** | BFS, DFS, best-first, random walk | O(V+E) |
| **DAG** | Topological sort (Kahn's) | O(V+E) |
| **Union-Find** | Disjoint Set | O(α(V)) amortized |

## Related Projects

- **[YogEx](https://github.com/code-shoily/yog_ex)** — Elixir graph library (superset of features)
- **[Yog](https://github.com/code-shoily/yog)** — Gleam graph library (functional API)

## License

MIT

---

**Yograph** — Graph algorithms for Dart
