/// Generic binary-min-heap priority queue.
///
/// [T] is the element type. [compare] defines the ordering:
/// negative if a < b, zero if equal, positive if a > b.
class PriorityQueue<T> {
  final List<T> _heap = [];
  final int Function(T a, T b) _compare;

  PriorityQueue(this._compare);

  bool get isEmpty => _heap.isEmpty;
  bool get isNotEmpty => _heap.isNotEmpty;
  int get length => _heap.length;

  void push(T value) {
    _heap.add(value);
    _siftUp(_heap.length - 1);
  }

  T? pop() {
    if (_heap.isEmpty) return null;
    final result = _heap.first;
    final last = _heap.removeLast();
    if (_heap.isNotEmpty) {
      _heap[0] = last;
      _siftDown(0);
    }
    return result;
  }

  void _siftUp(int index) {
    final value = _heap[index];
    while (index > 0) {
      final parent = (index - 1) ~/ 2;
      if (_compare(value, _heap[parent]) >= 0) break;
      _heap[index] = _heap[parent];
      index = parent;
    }
    _heap[index] = value;
  }

  void _siftDown(int index) {
    final value = _heap[index];
    final halfLength = _heap.length ~/ 2;
    while (index < halfLength) {
      var child = index * 2 + 1;
      final right = child + 1;
      if (right < _heap.length &&
          _compare(_heap[right], _heap[child]) < 0) {
        child = right;
      }
      if (_compare(value, _heap[child]) <= 0) break;
      _heap[index] = _heap[child];
      index = child;
    }
    _heap[index] = value;
  }
}
