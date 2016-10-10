// Copyright (c) 2016, kseo. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:bit_vector/bit_vector.dart';
import 'package:test/test.dart';

Random generator = new Random();

void main() {
  group('BitVector', () {
    int failCount = 0;
    test('test set/get/clear/toggle', () {
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
          if (testVector.get(x) != history.contains(x)) {
            failCount++;
          }
        }

        // Clear the bits
        for (final setBit in history) {
          testVector.clear(setBit);
        }

        // Verify they were cleared
        for (int x = 0; x < highestPossibleSetBit; x++) {
          if (testVector.get(x))
            failCount++;
        }
        if (testVector.length != 0)
          failCount++;

        // Flip them on
        for (final setBit in history) {
          testVector.toggle(setBit);
        }

        // Verify they were flipped
        for (int x = 0; x < highestPossibleSetBit; x++) {
          if (testVector.get(x) != history.contains(x)) {
            failCount++;
          }
        }

        // Flip them off
        for (final setBit in history) {
          testVector.toggle(setBit);
        }

        // Verify they were flipped
        for (int x = 0; x < highestPossibleSetBit; x++) {
          if (testVector.get(x))
            failCount++;
        }
        if (testVector.length != 0)
          failCount++;
      }
      expect(failCount, 0);
    });
  });
}

