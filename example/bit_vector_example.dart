// Copyright (c) 2016, kseo. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:bit_vector/bit_vector.dart';

void main() {
  BitVector v = new BitVector();
  v.set(68);
  print(v[68]); // true
  v.toggle(68);
  print(v[68]); // false
}

