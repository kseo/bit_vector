// Copyright (c) 2016, Kwang Yul Seo. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' show max, min;
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

  /// Creates a bit set whose initial length is [length].
  BitVector([int length = _bitsPerWord]) {
    if (length < 0)
      throw new ArgumentError.value(length, 'length', 'length < 0');

    _initWord(length);
  }

  /// Creates a new [BitVector] instance that is equal to [other].
  BitVector.from(BitVector other)
      : _words = new Int64List.fromList(other._words),
        _wordsInUse = other._wordsInUse;

  /// True if this [BitVector] contains no bits that are set to true.
  bool get isEmpty => _wordsInUse == 0;

  /// True if this [BitVector] contains any bit that is set to true.
  bool get isNotEmpty => !isEmpty;

  /// The "logical size" of this [BitVector]: the index of the highest set bit
  /// in the [BitVector] plus one. Returns zero if the [BitVector] contains no
  /// set bits.
  int get length {
    if (_wordsInUse == 0) return 0;

    return _bitsPerWord * (_wordsInUse - 1) +
        (_bitsPerWord -
            new Int64(_words[_wordsInUse - 1]).numberOfLeadingZeros());
  }

  /// The number of bits set to true in this [BitVector].
  int get cardinality {
    int sum = 0;
    for (var i = 0; i < _wordsInUse; i++) {
      sum += _bitCount(_words[i]);
    }
    return sum;
  }


  void _initWord(int length) {
    _words = new Int64List(_wordIndex(length - 1) + 1);
  }

  /// Tests if the bit at the specified index is set.
  bool operator [](int bitIndex) {
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

  /// Performs a logical `and`.
  void and(BitVector other) {
    if (identical(this, other)) return;

    while (_wordsInUse > other._wordsInUse) {
      _words[--_wordsInUse] = 0;
    }

    for (var i = 0; i < _wordsInUse; i++) {
      _words[i] &= other._words[i];
    }

    _recalculateWordsInUse();
  }

  /// Performs a logical `or`.
  void or(BitVector other) {
    if (identical(this, other)) return;

    int wordsInCommon = min(_wordsInUse, other._wordsInUse);

    if (_wordsInUse < other._wordsInUse) {
      _ensureCapacity(other._wordsInUse);
      _wordsInUse = other._wordsInUse;
    }

    for (var i = 0; i < wordsInCommon; i++) {
      _words[i] |= other._words[i];
    }

    // Copy any remaining words
    if (wordsInCommon < other._wordsInUse) {
      _words.setRange(
          wordsInCommon, other._wordsInUse, other._words, wordsInCommon);
    }

    // _recalculateWordsInUse() is not necessary
  }

  /// Performs a logical `xor`.
  void xor(BitVector other) {
    int wordsInCommon = min(_wordsInUse, other._wordsInUse);

    if (_wordsInUse < other._wordsInUse) {
      _ensureCapacity(other._wordsInUse);
      _wordsInUse = other._wordsInUse;
    }

    for (var i = 0; i < wordsInCommon; i++) {
      _words[i] ^= other._words[i];
    }

    // Copy any remaining words
    if (wordsInCommon < other._wordsInUse) {
      _words.setRange(
          wordsInCommon, other._wordsInUse, other._words, wordsInCommon);
    }

    _recalculateWordsInUse();
  }

  /// Clears all of the bits set in this [BitVector] whose corresponding bit is
  /// set in [other].
  void andNot(BitVector other) {
    for (var i = min(_wordsInUse, other._wordsInUse) - 1; i >= 0; i--) {
      _words[i] &= ~other._words[i];
    }

    _recalculateWordsInUse();
  }

  /// Given a bit index, returns word index containing it.
  int _wordIndex(int bitIndex) => bitIndex >> _addressBitsPerWord;

  @override
  int get hashCode {
    const mask = 0xFFFFFFFF;
    int h = 1234;
    for (int i = _wordsInUse; --i >= 0;) {
      h ^= (_words[i] * (i + 1)) & mask;
    }
    return (h >> 32) ^ h;
  }

  @override
  bool operator ==(other) {
    if (other is! BitVector) return false;
    if (identical(this, other)) return true;

    if (_wordsInUse != other._wordsInUse) {
      return false;
    }

    for (var i = 0; i < _wordsInUse; i++) {
      if (_words[i] != other._words[i]) {
        return false;
      }
    }

    return true;
  }

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

// Assumes i is <= 64-bit.
int _bitCount(int i) {
  i = i - ((i >> 1) & 0x5555555555555555);
  i = (i & 0x3333333333333333) + ((i >> 2) & 0x3333333333333333);
  i = (i + (i >> 4)) & 0x0f0f0f0f0f0f0f0f;
  i = i + (i >> 8);
  i = i + (i >> 16);
  i = i + (i >> 32);
  return i & 0x7f;
}
