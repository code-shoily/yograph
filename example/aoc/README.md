# Advent of Code (AoC) with Yograph

Welcome to the Advent of Code puzzle examples! This directory showcases how to solve complex spatial, flow, and pathfinding puzzles from the popular [Advent of Code](https://adventofcode.com) events using the high-performance features of `yograph`.

---

## 📜 AoC Policy Compliance

To fully respect the Advent of Code policy, **we do not commit raw puzzle inputs or personal answer outputs** to this repository. 

### How to Run:
1. Copy your personal input from the Advent of Code website for the respective day.
2. Save it in a text file alongside the solution script (e.g. `example/aoc/inputs/2023_day25.txt`).
3. Run the solution using the `dart` command.

---

## 📂 Layout

Each solution is organized by the year and day of the puzzle:

```text
example/aoc/
├── README.md               # This layout and running guide
└── yyyy/                   # Year folder (e.g. 2023)
    ├── dayxx.dart          # Self-contained solution executable
    └── inputs/             # Place your personal input files here
```

---

## 🚀 Running Solutions

You can run any of the solved days directly from the root of the project using the Dart SDK:

```bash
# Example: Run 2023 Day 25 "Snowverload"
dart run example/aoc/2023/day25.dart
```

Each solution includes a built-in mock/sample input from the AoC problem description, so you can execute them out-of-the-box even without providing a personal input file!

---

## 🏎️ Performance & Algorithm Migration Catalog

The following table summarizes the high-performance graph solvers migrated from the Elixir puzzle library, detailing the native execution speedups and the specific `yograph` library primitives utilized:

| Year / Day | Puzzle Name | Dart Time | Elixir Time | Speedup | Graph Algorithms & `yograph` Primitives Used |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **2015 / 07** | [Some Assembly Required](2015/day07.dart) | **<10ms** | ~110ms | **>11.0x** | `LabeledBuilder`, Topological Sort & DAG evaluation |
| **2015 / 09** | [All in a Single Night](2015/day09.dart) | **<10ms** | ~100ms | **>10.0x** | `LabeledBuilder`, Floyd-Warshall TSP / Hamiltonian path |
| **2015 / 13** | [Knights of the Dinner Table](2015/day13.dart) | **<10ms** | ~120ms | **>12.0x** | `LabeledBuilder`, Seating Arrangement TSP / Hamiltonian cycle |
| **2015 / 22** | [Wizard Simulator 20XX](2015/day22.dart) | **45ms** | ~400ms | **8.8x** | Implicit graph Dijkstra state-space search |
| **2016 / 11** | [Radioisotope Generators](2016/day11.dart) | **146ms** | ~2,000ms | **13.7x** | `AStar.implicitAStarBy` state-space search, symmetry pruning |
| **2016 / 13** | [A Maze of Twisty Little Cubes](2016/day13.dart) | **<10ms** | ~90ms | **>9.0x** | Implicit BFS pathfinding on coordinate grid |
| **2016 / 24** | [Air Duct Spelunking](2016/day24.dart) | **57ms** | ~1,000ms | **17.5x** | `GridBuilder.from2DList` rook graph, `Dijkstra.singleSourceDistances`, TSP search |
| **2017 / 07** | [Recursive Circus](2017/day07.dart) | **13ms** | ~120ms | **9.2x** | `LabeledBuilder`, Arborescence tree balancing search |
| **2017 / 12** | [Digital Plumber](2017/day12.dart) | **<10ms** | ~95ms | **>9.5x** | `SimpleGraph`, `Components.connectedComponents` |
| **2017 / 14** | [Disk Defragmentation](2017/day14.dart) | **52ms** | ~300ms | **5.7x** | Knot Hash, `SimpleGraph` undirected connected components |
| **2018 / 07** | [The Sum of Its Parts](2018/day07.dart) | **<10ms** | ~120ms | **12.0x** | `LabeledBuilder`, `lexicographicalTopologicalSort` |
| **2018 / 25** | [Four-Dimensional Adventure](2018/day25.dart) | **23ms** | ~180ms | **7.8x** | `Components.connectedComponents` distance clusters |
| **2019 / 06** | [Universal Orbit Map](2019/day06.dart) | **12ms** | ~95ms | **7.9x** | `LabeledBuilder`, `Dijkstra.shortestPath` |
| **2019 / 18** | [Many-Worlds Interpretation](2019/day18.dart) | **157ms** | ~2,000ms | **12.7x** | Bitmask search space representation, `AStar.implicitAStar` |
| **2020 / 07** | [Handy Haversacks](2020/day07.dart) | **15ms** | ~110ms | **7.3x** | `LabeledBuilder`, `Bidirectional` predecessor BFS traversal |
| **2021 / 09** | [Smoke Basin](2021/day09.dart) | **49ms** | ~300ms | **6.1x** | `GridBuilder.from2DList` rook graph, `Components.connectedComponents` on sub-graph |
| **2021 / 15** | [Chiton](2021/day15.dart) | **202ms** | ~2,000ms | **10.0x** | Integer-packed coordinate states, `AStar.implicitAStarBy` |
| **2022 / 08** | [Treetop Tree House](2022/day08.dart) | **1,112ms** | ~900ms | **0.8x** | `GridBuilder.from2DList` graph, cardinal `implicitFoldBy` walking |
| **2022 / 12** | [Hill Climbing Algorithm](2022/day12.dart) | **39ms** | ~300ms | **7.7x** | `GridBuilder` graph, `Dijkstra.shortestPath` & `Dijkstra.singleSourceDistances` |
| **2022 / 16** | [Proboscidea Volcanium](2022/day16.dart) | **119ms** | ~2,700ms | **22.6x** | `LabeledBuilder`, `FloydWarshall.allPairs`, bitmask state DFS search |
| **2022 / 24** | [Blizzard Basin](2022/day24.dart) | **228ms** | ~1,200ms | **5.2x** | `AStar.implicitAStarBy` 3D temporal state-space search, cyclic blizzards |
| **2023 / 10** | [Pipe Maze](2023/day10.dart) | **73ms** | ~300ms | **4.1x** | `GridBuilder.from2DList` directed, `Dijkstra.singleSourceDistances` loop pruning, scanline crossing parity |
| **2023 / 17** | [Clumsy Crucible](2023/day17.dart) | **1,510ms** | ~3,200ms | **2.1x** | `AStar.implicitAStarBy` state-space search with turning constraints |
| **2023 / 23** | [A Long Walk](2023/day23.dart) | **1,271ms** | ~5,800ms | **4.5x** | Graph compression, `SimpleGraph.directed` compressed segments, bitmasked DFS |
| **2023 / 25** | [Snowverload](2023/day25.dart) | **45ms** | ~650ms | **14.4x** | Minimum cut / Karger's / Stoer-Wagner graph partitioning |
| **2024 / 05** | [Print Queue](2024/day05.dart) | **27ms** | ~250ms | **9.2x** | `SimpleGraph.directed`, `topologicalSort` Kahn's algorithm |
| **2024 / 18** | [RAM Run](2024/day18.dart) | **15ms** | ~160ms | **10.6x** | `AStar.implicitAStar` grid pathfinding under falling bytes |
| **2024 / 23** | [LAN Party](2024/day23.dart) | **25ms** | ~280ms | **11.2x** | `SimpleGraph`, Bron-Kerbosch maximal clique algorithm |
| **2025 / 04** | [Printing Department](2025/day04.dart) | **146ms** | ~900ms | **6.1x** | `GridBuilder.from2DListWithTopology` (`GridTopologies.queen`), `SimpleGraph.removeNode` |
| **2025 / 10** | [Factory](2025/day10.dart) | **68ms** | ~400ms | **5.8x** | `AStar.implicitAStar` guidance, set bits mismatch heuristic, parity dynamic programming |
| **2025 / 11** | [Reactor](2025/day11.dart) | **13ms** | ~120ms | **9.2x** | `SimpleGraph`, `LabeledBuilder`, native `topologicalSort` path sums |

### 🛠️ Key Architectural Design Patterns Used:
* **Implicit State-Space Searches**: For grid search problems (like 2021/15, 2019/18, 2024/18, 2016/13), we avoided materializing physical graphs on the heap by leveraging **implicit state generation** using packed integers or compact strings. This keeps the memory footprint near zero and optimizes CPU cache hits.
* **Lexicographical sorts & Kahn's Algorithm**: For task precedence scheduling (like 2018/07, 2024/05, 2015/07), we leveraged native topological sorts to ensure correct dependencies.
* **Component Partitioning & Min Cuts**: For clustering or graph-splitting challenges (like 2023/25, 2018/25, 2017/12, 2017/14), we utilized native community and connectivity solvers to identify distinct disjoint subgraphs effortlessly.
