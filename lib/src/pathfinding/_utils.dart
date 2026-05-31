/// Reconstructs a path by back-tracking through [predecessors].
List<int> reconstructPath(Map<int, int> predecessors, int target) {
  final path = <int>[target];
  var current = target;
  while (true) {
    final parent = predecessors[current];
    if (parent == null) break;
    path.add(parent);
    current = parent;
  }
  return path.reversed.toList();
}
