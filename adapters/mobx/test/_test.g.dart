// GENERATED CODE - DO NOT MODIFY BY HAND

part of json_mapper_mobx.test;

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$Test on TestBase, Store {
  final _$valueAtom = Atom(name: 'TestBase.value');

  @override
  String get value {
    _$valueAtom.reportRead();
    return super.value;
  }

  @override
  set value(String value) {
    _$valueAtom.reportWrite(value, super.value, () {
      super.value = value;
    });
  }

  @override
  String toString() {
    return '''
value: ${value}
    ''';
  }
}
