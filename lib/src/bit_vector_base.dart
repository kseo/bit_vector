// Copyright (c) 2016, Kwang Yul Seo. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' show max;
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

/// Shift fox indexing.
const int _addressBitsPerWord = 6;

const int _bitsPerWord = 1 << _addressBitsPerWord;

/// Mask for indexing.
const int _bitMask = _bitsPerWord - 1;

/// A vector of bits that grows as needed.
class BitVector {
  /// Bit area.
  Int64List _words;

  int _wordsInUse = 0;

  /// The "logical size" of this [BitVector]: the index of the highest set bit
  /// in the [BitVector] plus one. Returns zero if the [BitVector] contains no
  /// set bits.
  int get length {
    if (_wordsInUse == 0) return 0;

    return _bitsPerWord * (_wordsInUse - 1) +
        (_bitsPerWord -
            new Int64(_words[_wordsInUse - 1]).numberOfLeadingZeros());
  }

  /// Creates a bit set whose initial length is [length].
  BitVector([int length = _bitsPerWord]) {
    if (length < 0)
      throw new ArgumentError.value(length, 'length', 'length < 0');

    _initWord(length);
  }

  void _initWord(int length) {
    _words = new Int64List(_wordIndex(length - 1) + 1);
  }

  /// Tests if the bit at the specified index is set.
  bool get(int bitIndex) {
    if (bitIndex < 0)
      throw new ArgumentError.value(bitIndex, 'bitIndex', 'bitIndex < 0');

    int wordIndex = _wordIndex(bitIndex);
    return (wordIndex < _wordsInUse) &&
        ((_words[wordIndex] & (1 << (bitIndex & _bitMask)) != 0));
  }

  /// Sets the bit at the specified index to true.
  void set(int bitIndex) {
    if (bitIndex < 0)
      throw new ArgumentError.value(bitIndex, 'bitIndex', 'bitIndex < 0');

    final wordIndex = _wordIndex(bitIndex);
    _expandTo(wordIndex);

    _words[wordIndex] |= (1 << (bitIndex & _bitMask));
  }

  /// Toggles the bit at the specified index.
  void toggle(int bitIndex) {
    if (bitIndex < 0)
      throw new ArgumentError.value(bitIndex, 'bitIndex', 'bitIndex < 0');

    int wordIndex = _wordIndex(bitIndex);
    _expandTo(wordIndex);

    _words[_wordIndex(bitIndex)] ^= (1 << (bitIndex & _bitMask));

    _recalculateWordsInUse();
  }

  /// Clears the bit at the specified index.
  void clear(int bitIndex) {
    if (bitIndex < 0)
      throw new ArgumentError.value(bitIndex, 'bitIndex', 'bitIndex < 0');

    final wordIndex = _wordIndex(bitIndex);
    if (wordIndex > _wordsInUse) return;

    _words[wordIndex] &= ~(1 << (bitIndex & _bitMask));

    _recalculateWordsInUse();
  }

  /// Clears all bits in the vector.
  void clearAll() {
    while (_wordsInUse > 0) {
      _words[--_wordsInUse] = 0;
    }
  }

  /// Given a bit index, returns word index containing it.
  int _wordIndex(int bitIndex) => bitIndex >> _addressBitsPerWord;

  void _recalculateWordsInUse() {
    int i;
    for (i = _wordsInUse - 1; i >= 0; i--) {
      if (_words[i] != 0) {
        break;
      }
    }
    _wordsInUse = i + 1;
  }

  void _expandTo(int wordIndex) {
    int wordsRequired = wordIndex + 1;
    if (_wordsInUse < wordsRequired) {
      _ensureCapacity(wordsRequired);
      _wordsInUse = wordsRequired;
    }
  }

  void _ensureCapacity(int wordsRequired) {
    if (_words.length < wordsRequired) {
      // Allocate larger of doubled size or required size
      int request = max(2 * _words.length, wordsRequired);
      _words = new Int64List(request)..setRange(0, _words.length, _words);
    }
  }
}

