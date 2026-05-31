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
