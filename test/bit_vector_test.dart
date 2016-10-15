// Copyright (c) 2016, kseo. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:bit_vector/bit_vector.dart';
import 'package:test/test.dart';

Random generator = new Random();

BitVector makeVector(Iterable<int> elements) {
  final BitVector b = new BitVector();
  for (int element in elements) {
    b.set(element);
  }
  return b;
}

void checkEquality(BitVector s, BitVector t) {
  expect(s, equals(t));
  expect(s.length, equals(t.length));
}

bool boolXor(bool x, bool y) => (x && !y) || (!x && y);

void main() {
  group('BitVector', () {
    test('test []/set/clear/toggle', () {
      int failCount = 0;
      for (int i = 0; i < 100; i++) {
        BitVector testVector = new BitVector();
        Set<int> history = new Set<int>();

        // Set a random number of bits in random places
        // up to a random maximum
        int nextBitToSet = 0;
        int numberOfSetBits = generator.nextInt(100) + 1;
        int highestPossibleSetBit = generator.nextInt(1000) + 1;
        for (int x = 0; x < numberOfSetBits; x++) {
          nextBitToSet = generator.nextInt(highestPossibleSetBit);
          history.add(nextBitToSet);
          testVector.set(nextBitToSet);
        }

        // Make sure each bit is set appropriately
        for (int x = 0; x < highestPossibleSetBit; x++) {
          if (testVector[x] != history.contains(x)) {
            failCount++;
          }
        }

        // Clear the bits
        for (final setBit in history) {
          testVector.clear(setBit);
        }

        // Verify they were cleared
        for (int x = 0; x < highestPossibleSetBit; x++) {
          if (testVector[x]) failCount++;
        }
        if (testVector.length != 0) failCount++;

        // Flip them on
        for (final setBit in history) {
          testVector.toggle(setBit);
        }

        // Verify they were flipped
        for (int x = 0; x < highestPossibleSetBit; x++) {
          if (testVector[x] != history.contains(x)) {
            failCount++;
          }
        }

        // Flip them off
        for (final setBit in history) {
          testVector.toggle(setBit);
        }

        // Verify they were flipped
        for (int x = 0; x < highestPossibleSetBit; x++) {
          if (testVector[x]) failCount++;
        }
        if (testVector.length != 0) failCount++;
      }
      expect(failCount, 0);
    });

    test('equality', () {
      int failCount = 0;

      for (var i = 0; i < 100; i++) {
        // Create BitSets of different sizes
        BitVector b1 = new BitVector(generator.nextInt(1000) + 1);
        BitVector b2 = new BitVector(generator.nextInt(1000) + 1);

        // Set some random bits
        int nextBitToSet = 0;
        for (var x = 0; x < 10; x++) {
          nextBitToSet += generator.nextInt(50) + 1;
          b1.set(nextBitToSet);
          b2.set(nextBitToSet);
        }

        // Verify their equality despite different storage sizes
        if (b1 != b2) {
          failCount++;
        }
        checkEquality(b1, b2);
      }

      expect(failCount, 0);
    });

    test('empty', () {
      int failCount = 0;

      BitVector b1 = new BitVector();
      if (b1.isNotEmpty) {
        failCount++;
      }

      int nextBitToSet = 0;
      int numberOfSetBits = generator.nextInt(100) + 1;
      int highestPossibleSetBit = generator.nextInt(1000) + 1;
      for (var x = 0; x < numberOfSetBits; x++) {
        nextBitToSet = generator.nextInt(highestPossibleSetBit);
        b1.set(nextBitToSet);
        if (b1.isEmpty) {
          failCount++;
        }
        b1.clear(nextBitToSet);
        if (b1.isNotEmpty) {
          failCount++;
        }
      }

      expect(failCount, 0);
    });

    test('length', () {
      int failCount = 0;

      // Test length after set
      for (int i = 0; i < 100; i++) {
        BitVector b1 = new BitVector(256);
        int highestSetBit = 0;

        for (var x = 0; x < 100; x++) {
          int nextBitToSet = generator.nextInt(255);
          if (nextBitToSet > highestSetBit) {
            highestSetBit = nextBitToSet;
          }
          b1.set(nextBitToSet);
          if (b1.length != highestSetBit + 1) {
            failCount++;
          }
        }
      }

      expect(failCount, 0);
    });

    test('cardinality', () {
      int failCount = 0;

      for (var i = 0; i < 100; i++) {
        BitVector b1 = new BitVector(256);

        // Set a random number of increasing bits
        int nextBitToSet = 0;
        int iterations = generator.nextInt(20) + 1;
        for (var x = 0; x < iterations; x++) {
          nextBitToSet += generator.nextInt(20) + 1;
          b1.set(nextBitToSet);
        }

        if (b1.cardinality != iterations) {
          failCount++;
        }
      }

      expect(failCount, 0);
    });

    test('andNot', () {
      int failCount = 0;

      for (var i = 0; i < 100; i++) {
        BitVector b1 = new BitVector(256);
        BitVector b2 = new BitVector(256);

        for (var x = 0; x < 10; x++) {
          b1.set(generator.nextInt(255));
        }

        for (var x = 0; x < 10; x++) {
          b2.set(generator.nextInt(255));
        }

        // andNot the sets together
        BitVector b3 = new BitVector.from(b1);
        b3.andNot(b2);

        // Examine each bit of b3 for errors
        for (var x = 0; x < 256; x++) {
          bool bit1 = b1[x];
          bool bit2 = b2[x];
          bool bit3 = b3[x];
          if (!(bit3 == (bit1 && (!bit2)))) {
            failCount++;
          }
        }
      }

      expect(failCount, 0);
    });

    test('and', () {
      int failCount = 0;

      for (var i = 0; i < 100; i++) {
        BitVector b1 = new BitVector(256);
        BitVector b2 = new BitVector(256);

        for (var x = 0; x < 10; x++) {
          b1.set(generator.nextInt(255));
        }

        for (var x = 0; x < 10; x++) {
          b2.set(generator.nextInt(255));
        }

        // And the sets together
        BitVector b3 = new BitVector.from(b1);
        b3.and(b2);

        // Examine each bit of b3 for errors
        for (var x = 0; x < 256; x++) {
          bool bit1 = b1[x];
          bool bit2 = b2[x];
          bool bit3 = b3[x];
          if (!(bit3 == (bit1 && bit2))) {
            failCount++;
          }
        }
      }

      // `and' that happens to clear the last word
      BitVector b4 = makeVector([2, 127]);
      b4.and(makeVector([2, 64]));
      if (!(b4 == makeVector([2]))) {
        failCount++;
      }

      expect(failCount, 0);
    });

    test('or', () {
      int failCount = 0;

      for (var i = 0; i < 100; i++) {
        BitVector b1 = new BitVector(256);
        BitVector b2 = new BitVector(256);
        List<int> history = new List<int>(20);

        // Set some random bits in first set and remember them
        int nextBitToSet = 0;
        for (var x = 0; x < 10; x++) {
          nextBitToSet = generator.nextInt(255);
          history[x] = nextBitToSet;
          b1.set(nextBitToSet);
        }

        // Set more random bits in second set and remember them
        for (int x = 10; x < 20; x++) {
          nextBitToSet = generator.nextInt(255);
          history[x] = nextBitToSet;
          b2.set(nextBitToSet);
        }

        // Or the sets together
        BitVector b3 = new BitVector.from(b1);
        b3.or(b2);

        // Verify the set bits of b3 from the history
        for (int x = 0; x < 20; x++) {
          if (!b3[history[x]]) {
            failCount++;
          }
        }

        // Examine each bit of b3 for errors
        for (var x = 0; x < 256; x++) {
          bool bit1 = b1[x];
          bool bit2 = b2[x];
          bool bit3 = b3[x];
          if (!(bit3 == (bit1 || bit2))) {
            failCount++;
          }
        }
      }

      expect(failCount, 0);
    });

    test('xor', () {
      int failCount = 0;

      for (var i = 0; i < 100; i++) {
        BitVector b1 = new BitVector(256);
        BitVector b2 = new BitVector(256);

        int nextBitToSet = 0;
        for (var x = 0; x < 10; x++) {
          nextBitToSet = generator.nextInt(255);
          b1.set(nextBitToSet);
        }

        for (int x = 0; x < 10; x++) {
          nextBitToSet = generator.nextInt(255);
          b2.set(nextBitToSet);
        }

        // Xor the sets together
        BitVector b3 = new BitVector.from(b1);
        b3.xor(b2);

        // Examine each bit of b3 for errors
        for (var x = 0; x < 256; x++) {
          bool bit1 = b1[x];
          bool bit2 = b2[x];
          bool bit3 = b3[x];
          if (!(bit3 == (boolXor(bit1, bit2)))) {
            failCount++;
          }
        }
      }

      expect(failCount, 0);
    });
  });
}

