// Copyright (c) 2016, Kwang Yul Seo. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:bit_vector/bit_vector.dart' as impl;
import 'package:enumerators/combinators.dart' as co;
import 'package:enumerators/enumerators.dart' as en;

import 'model.dart' as model;

abstract class BitVectorFactory {
  impl.BitVector empty();
}

class _ImplFactory implements BitVectorFactory {
  @override
  impl.BitVector empty() => new impl.BitVector();
}

class _ModelFactory implements BitVectorFactory {
  @override
  impl.BitVector empty() => new model.BitVector();
}

final implFactory = new _ImplFactory();
final modelFactory = new _ModelFactory();

abstract class _ConstructorCall {
  impl.BitVector execute(BitVectorFactory factory);
}

class _Empty extends _ConstructorCall {
  _Empty();

  String toString() => 'Empty()';

  @override
  impl.BitVector execute(BitVectorFactory factory) => factory.empty();
}

abstract class _Instruction {
  Result execute(impl.BitVector bv);
}

Result _execute(f()) {
  try {
    return new _Value(f());
  } catch (error) {
    return new _Issue(error);
  }
}

class _Set extends _Instruction {
  final int i;
  _Set(this.i);

  @override
  String toString() => 'Set($i)';

  @override
  Result execute(impl.BitVector bv) => _execute(() => bv.set(i));
}

class _Get extends _Instruction {
  final int i;
  _Get(this.i);

  @override
  String toString() => 'Get($i)';

  @override
  Result execute(impl.BitVector bv) => _execute(() => bv[i]);
}

class _Toggle extends _Instruction {
  final int i;
  _Toggle(this.i);

  @override
  String toString() => 'Toggle($i)';

  @override
  Result execute(impl.BitVector bv) => _execute(() => bv.toggle(i));
}

class _Clear extends _Instruction {
  final int i;
  _Clear(this.i);

  @override
  String toString() => 'Clear($i)';

  @override
  Result execute(impl.BitVector bv) => _execute(() => bv.clear(i));
}

class _ClearAll extends _Instruction {
  _ClearAll();

  @override
  String toString() => 'ClearAll()';

  @override
  Result execute(impl.BitVector bv) => _execute(() => bv.clearAll());
}

class Program {
  final _ConstructorCall constructorCall;
  final List<_Instruction> instructions;
  Program(this.constructorCall, this.instructions);

  @override
  String toString() => 'Program($constructorCall, $instructions)';

  List<Result> execute(BitVectorFactory factory) {
    final bv = constructorCall.execute(factory);
    List<Result> result = [];
    for (final instruction in instructions) {
      result.add(instruction.execute(bv));
    }
    return result;
  }
}

abstract class Result {
  bool same(Result result);
}

class _Value extends Result {
  final Object value;

  _Value(this.value);

  @override
  String toString() => 'Value($value)';

  @override
  bool same(Result result) => result is _Value && value == result.value;
}

class _Issue extends Result {
  final Error error;

  _Issue(this.error);

  String toString() => 'Issue($error)';

  bool same(Result result) =>
      result is _Issue && error.toString() == result.error.toString();
}

_empty() => new _Empty();

final constructorCalls = en.singleton(_empty());

_get(int i) => new _Get(i);
_set(int i) => new _Set(i);
_toggle(int i) => new _Toggle(i);
_clear(int i) => new _Clear(i);
_clearAll() => new _ClearAll();

final instructions = en.apply(_get, co.ints) +
    en.apply(_set, co.ints) +
    en.apply(_toggle, co.ints) +
    en.apply(_clear, co.ints) +
    en.singleton(_clearAll());

_program(_ConstructorCall constructorCall) =>
    (List<_Instruction> instructions) =>
        new Program(constructorCall, instructions);

final programs = en
    .singleton(_program)
    .apply(constructorCalls)
    .apply(co.listsOf(instructions));

bool sameTraces(List<Result> trace1, List<Result> trace2) {
  if (trace1.length != trace2.length) return false;
  for (var i = 0; i < trace1.length; i++) {
    if (!trace1[i].same(trace2[i])) return false;
  }
  return true;
}
