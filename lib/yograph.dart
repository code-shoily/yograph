/// Yograph — a comprehensive graph theory library for Dart.
///
/// Graphs use strictly `int` node IDs for algorithmic efficiency.
/// Use [LabeledBuilder] for ergonomic label-based construction.
library;

// Core model interfaces
export 'src/model/graph_kind.dart';
export 'src/model/traversable.dart';
export 'src/model/queryable.dart';
export 'src/model/reversible.dart';
export 'src/model/mutable.dart';
export 'src/model/roles.dart';

// Result types
export 'src/path.dart';

// Traversal
export 'src/traversal/order.dart';
export 'src/traversal/walk_control.dart';
export 'src/traversal/walk_metadata.dart';
export 'src/traversal/traversal.dart';

// Data structures
export 'src/disjoint_set.dart';

// Pathfinding
export 'src/pathfinding/pathfinding.dart';

// MST
export 'src/mst/mst_edge.dart';
export 'src/mst/mst_result.dart';
export 'src/mst/mst.dart';

// Implementations
export 'src/simple_graph.dart';

// Builders
export 'src/builder/labeled_builder.dart';
