# bit_vector

A pure Dart memory-efficient packed representation for bit arrays.

## Examples

```dart
import 'package:bit_vector/bit_vector.dart';

main() {
  BitVector v = new BitVector();
  v.set(68);
  print(v.get(68)); // true
  v.toggle(68);
  print(v.get(68)); // false
}
```
