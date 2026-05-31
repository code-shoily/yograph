import 'traversable.dart';
import 'queryable.dart';
import 'reversible.dart';

// ---------------------------------------------------------------------------
// Combined "role" interfaces
// ---------------------------------------------------------------------------
// Dart does not support intersection types in generic bounds (e.g.
// `T extends A & B`), so we define small combined interfaces that group
// the capabilities algorithms actually need.
//
// Concrete graph classes implement the full set of capabilities they support;
// algorithm signatures use these role interfaces as parameter types.
// ---------------------------------------------------------------------------

/// Anything that can be walked (BFS/DFS/traversal).
///
/// Requires the ability to enumerate nodes and query successors + edge data.
abstract interface class Walkable<N, E>
    implements Traversable, Queryable<N, E> {}

/// Anything that supports shortest-path calculations.
///
/// Same capabilities as [Walkable] — the distinction is semantic:
/// implementations promise that [edgeWeight] returns meaningful values.
abstract interface class WeightedWalkable<N, E>
    implements Traversable, Queryable<N, E> {}

/// Anything with both out-edges and in-edges indexed.
///
/// Required by algorithms that need transpose, predecessor traversal, or
/// in-degree information: betweenness centrality, Kosaraju SCC, k-core, etc.
abstract interface class Bidirectional<N, E>
    implements Traversable, Reversible<E>, Queryable<N, E> {}
