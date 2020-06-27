library perf_test.test;

import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

part './index.dart';
part './model.dart';
part 'json_serializable_test.g.dart';

@JsonLiteral('../starlink.json')
Iterable get list => _$listJsonLiteral;

void main() {
  testStarlink(list);
}
