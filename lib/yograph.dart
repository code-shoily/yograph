/// Yograph — graph algorithms and data structures for Dart.
library;

// Core model interfaces
export 'src/model/graph_kind.dart';
export 'src/model/traversable.dart';
export 'src/model/queryable.dart';
export 'src/model/reversible.dart';
export 'src/model/mutable.dart';
export 'src/model/roles.dart';
export 'src/model/weight_algebra.dart';

// Result types
export 'src/path.dart';

// Traversal
export 'src/traversal/order.dart';
export 'src/traversal/walk_control.dart';
export 'src/traversal/walk_metadata.dart';
export 'src/traversal/traversal.dart';

// DAG utilities
export 'src/dag/dag.dart';

// Data structures
export 'src/disjoint_set.dart';

// Pathfinding
export 'src/pathfinding/pathfinding.dart';

// MST
export 'src/mst/mst_edge.dart';
export 'src/mst/mst_result.dart';
export 'src/mst/mst.dart';

// Matching
export 'src/matching/matching.dart';

// Centrality
export 'src/centrality/brandes.dart';
export 'src/centrality/centrality.dart';

// Property
export 'src/property/health.dart';
export 'src/property/structure.dart';
export 'src/property/bipartite.dart';
export 'src/property/clique.dart';
export 'src/property/cyclicity.dart';
export 'src/property/eulerian.dart';

// Network Flows
export 'src/flow/max_flow_result.dart';
export 'src/flow/min_cut_result.dart';
export 'src/flow/max_flow.dart';
export 'src/flow/min_cut.dart';

// Connectivity
export 'src/connectivity/connectivity.dart';

// Transformations
export 'src/transform/transform.dart';

// Community Detection
export 'src/community/community_result.dart';
export 'src/community/community_dendrogram.dart';
export 'src/community/community_metrics.dart';
export 'src/community/community.dart';
export 'src/community/label_propagation.dart';
export 'src/community/louvain.dart';
export 'src/community/leiden.dart';
export 'src/community/walktrap.dart';

// Implementations
export 'src/simple_graph.dart';

// Builders
export 'src/builder/labeled_builder.dart';
export 'src/builder/grid_graph.dart';
export 'src/builder/grid_builder.dart';

// Rendering
export 'src/render/ascii.dart';
export 'src/render/dot.dart';
export 'src/render/mermaid.dart';
export 'src/render/svg.dart';

// Generators
export 'src/generator/classic.dart';
export 'src/generator/random.dart';
export 'src/generator/maze.dart';

// I/O
export 'src/io/graph_io.dart';
