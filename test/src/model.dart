// Copyright (c) 2016, Kwang Yul Seo. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' show max;

import 'package:bit_vector/bit_vector.dart' as impl;

bool _isSet(bool b) => b;

class BitVector implements impl.BitVector {
  int _length;
  List<bool> _bits;

  BitVector([int length = 0])
      : _bits = new List.filled(length, false, growable: true),
        _length = length;

  @override
  bool get isEmpty => _length == 0;

  @override
  bool get isNotEmpty => _length != 0;

  @override
  int get cardinality => _bits.where(_isSet).length;

  @override
  int get length => _length;

  @override
  bool operator [](int bitIndex) {
    if (bitIndex < 0)
      throw new ArgumentError.value(bitIndex, 'bitIndex', 'bitIndex < 0');

    return (bitIndex < _length) && _bits[bitIndex];
  }

  @override
  void set(int bitIndex) {
    if (bitIndex < 0)
      throw new ArgumentError.value(bitIndex, 'bitIndex', 'bitIndex < 0');

    _expandTo(bitIndex);
    _bits[bitIndex] = true;
  }

  @override
  void toggle(int bitIndex) {
    if (bitIndex < 0)
      throw new ArgumentError.value(bitIndex, 'bitIndex', 'bitIndex < 0');

    _expandTo(bitIndex);
    _bits[bitIndex] = !_bits[bitIndex];
    _shrinkIfNecessary();
  }

  @override
  void clear(int bitIndex) {
    if (bitIndex < 0)
      throw new ArgumentError.value(bitIndex, 'bitIndex', 'bitIndex < 0');

    if (bitIndex >= _length) return;
    _bits[bitIndex] = false;
    _shrinkIfNecessary();
  }

  @override
  void clearAll() {
    while (_length > 0) {
      _bits[--_length] = false;
    }
  }

  @override
  void and(impl.BitVector other) => throw new UnimplementedError();

  @override
  void andNot(impl.BitVector other) => throw new UnimplementedError();

  @override
  void or(impl.BitVector other) => throw new UnimplementedError();

  @override
  void xor(impl.BitVector other) => throw new UnimplementedError();

  void _expandTo(int bitIndex) {
    int lengthRequired = bitIndex + 1;
    if (_length < lengthRequired) {
      _ensureCapacity(lengthRequired);
      _length = lengthRequired;
    }
  }

  void _ensureCapacity(int lengthRequired) {
    if (_bits.length < lengthRequired) {
      // Allocate larger of doubled size or required size
      int request = max(2 * _bits.length, lengthRequired);

      int oldLength = _bits.length;
      _bits.length = request;
      _bits.fillRange(oldLength, _bits.length, false);
    }
  }

  void _shrinkIfNecessary() {
    int i;
    for (i = _bits.length - 1; i >= 0; i--) {
      if (_bits[i]) break;
    }
    _length = i + 1;
  }
}
