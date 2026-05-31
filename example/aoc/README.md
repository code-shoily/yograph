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
| **2016 / 11** | [Radioisotope Generators](2016/day11.dart) | **114ms** | ~2,000ms | **17.5x** | State-space BFS, Symmetry-Pruned State representation |
| **2016 / 24** | [Air Duct Spelunking](2016/day24.dart) | **71ms** | ~1,000ms | **14.0x** | Coordinate Bitmask BFS, TSP Permutation Search |
| **2017 / 07** | [Recursive Circus](2017/day07.dart) | **13ms** | ~120ms | **9.2x** | `LabeledBuilder`, Arborescence tree balancing search |
| **2017 / 14** | [Disk Defragmentation](2017/day14.dart) | **29ms** | ~300ms | **10.3x** | Knot Hash, Grid region DFS connected components |
| **2018 / 07** | [The Sum of Its Parts](2018/day07.dart) | **<10ms** | ~120ms | **12.0x** | `LabeledBuilder`, `lexicographicalTopologicalSort` |
| **2018 / 25** | [Four-Dimensional Adventure](2018/day25.dart) | **23ms** | ~180ms | **7.8x** | `Components.connectedComponents` |
| **2019 / 06** | [Universal Orbit Map](2019/day06.dart) | **12ms** | ~95ms | **7.9x** | `LabeledBuilder`, `Dijkstra.shortestPath` |
| **2019 / 18** | [Many-Worlds Interpretation](2019/day18.dart) | **157ms** | ~2,000ms | **12.7x** | Bitmask search space state representation, `AStar.implicitAStar` |
| **2020 / 07** | [Handy Haversacks](2020/day07.dart) | **15ms** | ~110ms | **7.3x** | `LabeledBuilder`, `Bidirectional` predecessor BFS traversal |
| **2021 / 15** | [Chiton](2021/day15.dart) | **202ms** | ~2,000ms | **10.0x** | Integer-packed coordinate states, `AStar.implicitAStarBy` |
| **2022 / 12** | [Hill Climbing Algorithm](2022/day12.dart) | **21ms** | ~250ms | **12.0x** | Backwards step logic, Forward/Backward BFS Pathfinding |
| **2025 / 04** | [Printing Department](2025/day04.dart) | **146ms** | ~900ms | **6.1x** | `GridBuilder.from2DListWithTopology` (`GridTopologies.queen`), `SimpleGraph.removeNode` |

### 🛠️ Key Architectural Design Patterns Used:
* **Implicit State-Space Searches**: For grid search problems (like 2021/15, 2019/18), we avoided materializing physical graphs on the heap by leveraging **implicit state generation** using packed integers or compact strings. This keeps the memory footprint near zero and optimizes CPU cache hits.
* **Symmetry Pruning**: In complex permutation/combination state spaces (like 2016/11), elements were mapped to sorted pairs `(m_floor, g_floor)` to shrink the graph lookup size by multiple orders of magnitude.
* **Backwards Search Traversals**: For multi-start grid pathfinding (like 2022/12), we reversed the step logic to run a single backwards search from the goal. The very first start node popped is mathematically guaranteed to be the shortest path.

