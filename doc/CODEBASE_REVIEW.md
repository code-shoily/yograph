# Yograph Technical & Type-Safety Review

This document provides an architectural and type-safety review of the **Yograph** codebase. It evaluates the current implementation (`lib/`), analyzes the design proposals (`doc/`), identifies type-system pitfalls, and outlines the correct path forward to ensure zero-error, zero-warning compile-time and runtime type safety.

---

## 1. Executive Summary

- **Current Implementation (`lib/` & `test/`):** **100% Clean.** Static analysis (`dart analyze`) passes with zero errors, warnings, or infos. The test suite (`dart test`) passes all 31 test cases. The generic design is sound, robust, and correctly leverages Dart's sound null safety.
- **Interface Design Proposal (`doc/interface_design_proposal.dart`):** **14 Issues Detected.** Running static analysis on the proposal reveals **6 compilation errors**, **7 warnings**, and **1 info warning**. These range from severe type-parameter shadowing to invalid overrides and illegal extension type implementations.
- **Architectural Verification:** The production capability interfaces in `lib/src/model/` successfully resolved the core problems of the design proposal by promoting generic parameters (`N` and `E`) to class-level parameters, avoiding type shadowing and raw-type mismatches.

---

## 2. Production Codebase Review (`lib/`)

The current implementation is clean, idiomatic, and highly type-safe. Here is a breakdown of why it is solid:

### 2.1 Generic Class-Level Architecture
Unlike the proposal's Approach B (which tried to parameterize only the edge type `E` on the class level and use generic method parameters for node data `N`), the production interfaces in `lib/src/model/` correctly parameterize both `N` (Node Data) and `E` (Edge Data) at the class level:
```dart
abstract interface class Queryable<N, E> {
  N? nodeData(Object id);
  E? edgeData(Object from, Object to);
  ...
}
```
This guarantees that any implementation of `Queryable` maintains strict type parity between the graph instances and the queries made on them.

### 2.2 Sound Null Safety Compliance
- **Lookup Types:** `nodeData` returns `N?` and `edgeData` returns `E?`. This is the correct representation. Since node and edge data are optional, they can be `null` at runtime. Dart forces downstream developers to handle the nullable return, preventing runtime `NullThrownError` exceptions.
- **Map Indexes:** In `SimpleGraph`, the internal maps are typed as `Map<Object, N?>` and `Map<Object, Map<Object, E?>>`. The keys are `Object` to support any ID type with consistent equality, while the values are correctly marked nullable.
- **Auto-creation:** In `addEdge`, missing endpoints are auto-created using `addNode(from)` and `addNode(to)` which defaults the data to `null` (valid under `N?`). The bang operators `_out[from]!` are 100% safe because the keys are guaranteed to exist immediately after the auto-creation block.

---

## 3. Review of the Interface Design Proposal (`doc/interface_design_proposal.dart`)

Analyzing `doc/interface_design_proposal.dart` reveals several systemic type-system errors. Below is a deep-dive analysis of these issues:

### 3.1 Severe: Type Parameter Shadowing (Line 191)
```dart
class SimpleGraph<N, E> implements Walkable<E>, Bidirectional<E>, Mutable<N, E> {
  ...
  @override
  N? nodeData<N>(Object id) {
    final v = _nodes[id];
    return v is N ? v : null;
  }
}
```
> [!WARNING]
> **Issue:** The type parameter `<N>` on the `nodeData` method shadows the class-level type parameter `N` of `SimpleGraph<N, E>`.
>
> **Implications:** Inside this method, `N` refers to the *method's* type parameter, which defaults to `dynamic` if called without explicit type arguments. The expression `v is N` will check against this dynamic parameter instead of the class's node type, completely breaking generic type checks and returning incorrect values or `null`.

### 3.2 Severe: Invalid Overrides (Line 270)
```dart
class SingleMapGraph<N, E> implements Walkable<E>, Mutable<N, E> {
  ...
  @override
  N? nodeData<N2>(Object id) { ... }
}
```
> [!ERROR]
> **Issue:** `'SingleMapGraph.nodeData' ('N? Function<N2>(Object)') isn't a valid override of 'Queryable.nodeData' ('N? Function<N>(Object)').`
>
> **Implications:** Because `Queryable` declares `N? nodeData<N>(Object id)`, overriding it with a different type parameter name `N2` is illegal in Dart's strict overrides check. More importantly, attempting to decouple `N` from the class level prevents class instances from enforcing node data type constraints consistently.

### 3.3 Severe: Extension Type Representation Constraints (Line 323)
```dart
extension type AdjListView._(Map<Object, List<Object>> _adj)
    implements Traversable {
  ...
}
```
> [!ERROR]
> **Issue:** `'Traversable' is not a supertype of 'Map<Object, List<Object>>', the representation type.`
>
> **Implications:** In Dart 3.2+, an `extension type` can only implement a standard interface (like `Traversable`) if its underlying representation type is a subtype of that interface. Since a raw Map is not a `Traversable`, this is a compile-time error.

### 3.4 Severe: Generic Bounds & Assignment Mismatches (Lines 350, 361, 369)
// Algorithm signature
PathResult? dijkstra<W extends WeightedWalkable>(W graph, Object from, Object to)

// Usage
final full = SimpleGraph<String, int>.directed();
dijkstra(full, 'A', 'B');
```
> [!ERROR]
> **Issue:** `The argument type 'SimpleGraph<String, int>' can't be assigned to the parameter type 'WeightedWalkable<dynamic>'.`
>
> **Implications:** Since the proposal does not declare `WeightedWalkable` with both generic parameters, `WeightedWalkable` defaults its generic arguments to `<dynamic>`. Passing a strongly typed `SimpleGraph<String, int>` (which implements `WeightedWalkable<int>`) causes a compile-time assignment failure because generic parameters in Dart are invariant/covariant depending on their usage, and `dynamic` bounds are not compatible with strict generic parameters.

---

## 4. Implementation Guidelines for Upcoming Phases

To ensure that the upcoming development phases maintain the perfect, zero-warning type safety of the current `lib/` codebase, developers must adhere to the following rules:

### Rule 1: Always Accept Generic Interfaces in Algorithms
Algorithms must never take concrete implementations like `SimpleGraph`. They must accept the combined role interfaces (e.g. `Walkable<N, E>`, `WeightedWalkable<N, E>`, `Bidirectional<N, E>`) and propagate both `N` and `E` generics:

```dart
// CORRECT 
Path? dijkstra<N, E>(
  WeightedWalkable<N, E> graph, 
  Object from, 
  Object to,
) {
  final N? startData = graph.nodeData(from);
  ...
}
```

### Rule 2: Robust Weight Extraction
When executing shortest path algorithms, use a safe, flexible weight extractor:
```dart
double getWeight<N, E>(
  Queryable<N, E> graph, 
  Object from, 
  Object to, 
  double Function(E? data)? weightFn,
) {
  if (weightFn != null) {
    return weightFn(graph.edgeData(from, to));
  }
  return graph.edgeWeight(from, to);
}
```
This accommodates both unweighted graphs, standard numeric edge graphs, and custom data-to-weight mapping functions.
