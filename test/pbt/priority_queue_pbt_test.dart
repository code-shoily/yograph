import 'package:glados/glados.dart';
import 'package:yograph/src/internal/priority_queue.dart';

void main() {
  Glados<List<int>>().test(
    'Heap ordering: Popping all elements returns a sorted list',
    (elements) {
      final pq = PriorityQueue<int>((a, b) => a.compareTo(b));
      for (final x in elements) {
        pq.push(x);
      }

      final popped = <int>[];
      while (pq.isNotEmpty) {
        popped.add(pq.pop()!);
      }

      final expected = List<int>.from(elements)..sort();
      expect(popped, equals(expected));
    },
  );

  Glados<List<int>>().test(
    'Peek-Pop agreement: peek returns the same as the next pop',
    (elements) {
      final pq = PriorityQueue<int>((a, b) => a.compareTo(b));
      for (final x in elements) {
        pq.push(x);
      }

      while (pq.isNotEmpty) {
        final peeked = pq.peek;
        final popped = pq.pop();
        expect(peeked, equals(popped));
      }
      expect(pq.peek, isNull);
      expect(pq.pop(), isNull);
    },
  );

  Glados<List<int>>().test(
    'Size invariant: Push and pop accurately track length',
    (elements) {
      final pq = PriorityQueue<int>((a, b) => a.compareTo(b));
      var currentLength = 0;
      expect(pq.length, currentLength);
      expect(pq.isEmpty, isTrue);

      for (final x in elements) {
        pq.push(x);
        currentLength++;
        expect(pq.length, currentLength);
        expect(pq.isNotEmpty, isTrue);
      }

      while (pq.isNotEmpty) {
        pq.pop();
        currentLength--;
        expect(pq.length, currentLength);
      }
      expect(pq.isEmpty, isTrue);
    },
  );

  Glados<List<int>>().test('Custom comparison: Supports max-heap ordering', (
    elements,
  ) {
    // Max-heap
    final pq = PriorityQueue<int>((a, b) => b.compareTo(a));
    for (final x in elements) {
      pq.push(x);
    }

    final popped = <int>[];
    while (pq.isNotEmpty) {
      popped.add(pq.pop()!);
    }

    final expected = List<int>.from(elements)..sort((a, b) => b.compareTo(a));
    expect(popped, equals(expected));
  });
}
