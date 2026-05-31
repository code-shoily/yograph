/// Control flow for [foldWalk] and [bestFirstFold] traversals.
enum WalkControl {
  /// Continue exploring from this node's successors.
  continueWalk,

  /// Stop exploring from this node (but continue with other queued nodes).
  stopBranch,

  /// Halt the entire traversal immediately and return the accumulator.
  halt,
}
