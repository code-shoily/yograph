/// Disjoint Set Union (Union-Find) data structure.
///
/// Maintains a partition of elements into disjoint (non-overlapping) sets.
/// Provides near-constant time operations to add elements, find which set
/// an element belongs to, and merge two sets together.
///
/// Uses **path compression** and **union by rank** for O(α(n)) amortized
/// per operation, where α is the inverse Ackermann function (effectively
/// ≤ 4 for all practical inputs).
///
/// ```dart
/// final dsu = DisjointSet<int>()
///   ..add(1)
///   ..add(2)
///   ..add(3)
///   ..union(1, 2)
///   ..union(2, 3);
///
/// print(dsu.connected(1, 3)); // true
/// print(dsu.connected(1, 4)); // false
/// ```
class DisjointSet<E> {
  final Map<E, E> _parents;
  final Map<E, int> _ranks;

  DisjointSet() : _parents = {}, _ranks = {};

  /// Adds [element] as a new singleton set.
  ///
  /// If [element] already exists, the structure is unchanged.
  void add(E element) {
    if (_parents.containsKey(element)) return;
    _parents[element] = element;
    _ranks[element] = 0;
  }

  /// Finds the representative (root) of the set containing [element].
  ///
  /// Uses path compression to flatten the tree. If [element] doesn't exist,
  /// it is automatically added first.
  E find(E element) {
    if (!_parents.containsKey(element)) {
      add(element);
      return element;
    }

    final parent = _parents[element];
    if (parent == null || parent == element) return element;

    // Path compression
    final root = find(parent);
    _parents[element] = root;
    return root;
  }

  /// Merges the sets containing [x] and [y].
  ///
  /// Uses union by rank to keep trees balanced. If already in the same set,
  /// nothing happens.
  void union(E x, E y) {
    final rootX = find(x);
    final rootY = find(y);
    if (rootX == rootY) return;

    final rankX = _ranks[rootX] ?? 0;
    final rankY = _ranks[rootY] ?? 0;

    if (rankX < rankY) {
      _parents[rootX] = rootY;
    } else if (rankX > rankY) {
      _parents[rootY] = rootX;
    } else {
      _parents[rootY] = rootX;
      _ranks[rootX] = rankX + 1;
    }
  }

  /// Returns `true` if [x] and [y] are in the same set.
  bool connected(E x, E y) {
    if (!_parents.containsKey(x) || !_parents.containsKey(y)) return false;
    return find(x) == find(y);
  }

  /// Builds a disjoint set from a list of pairs to union.
  ///
  /// ```dart
  /// final dsu = DisjointSet.fromPairs([(1, 2), (3, 4), (2, 3)]);
  /// print(dsu.connected(1, 4)); // true
  /// ```
  factory DisjointSet.fromPairs(Iterable<(E, E)> pairs) {
    final dsu = DisjointSet<E>();
    for (final (x, y) in pairs) {
      dsu.union(x, y);
    }
    return dsu;
  }

  /// Total number of elements in the structure.
  int get size => _parents.length;

  /// Number of disjoint sets.
  int get setCount {
    final roots = <E>{};
    for (final element in _parents.keys) {
      roots.add(_findRootReadonly(element));
    }
    return roots.length;
  }

  /// Returns all disjoint sets as a list of lists.
  ///
  /// Each inner list contains all members of one set.
  List<List<E>> toLists() {
    final groups = <E, List<E>>{};
    for (final element in _parents.keys) {
      final root = _findRootReadonly(element);
      groups.putIfAbsent(root, () => []).add(element);
    }
    return groups.values.toList();
  }

  E _findRootReadonly(E element) {
    var current = element;
    while (true) {
      final parent = _parents[current];
      if (parent == null || parent == current) return current;
      current = parent;
    }
  }
}
