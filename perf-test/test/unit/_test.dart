library json_mapper.test;

import 'package:starlink/starlink.dart' show starlinkGeneratedAdapter;
import 'package:unit_testing/model.dart' show compactOptions;
import 'package:unit_testing/unit_testing.dart'
    show unitTestingGeneratedAdapter;

import '_test.mapper.g.dart' show initializeJsonMapper;
import 'test.collections.dart';
import 'test.constructors.dart';
import 'test.converters.caching.dart';
import 'test.converters.dart';
import 'test.default.value.dart';
import 'test.enums.dart';
import 'test.errors.dart';
import 'test.flatten.dart';
import 'test.generics.dart';
import 'test.inheritance.dart';
import 'test.injection.dart';
import 'test.integration.dart';
import 'test.mixins.dart';
import 'test.name.casing.dart';
import 'test.name.path.dart';
import 'test.partial.deserialization.dart';
import 'test.required.dart';
import 'test.scheme.dart';
import 'test.special.cases.dart';
import 'test.tuple.dart';
import 'test.value.decorators.dart';
import './test.raw_json.dart' as raw_json;
import './test.cache_manager.dart';
import './test.adapter_manager.dart';
import './test_issue_234.dart';
import './test_issue_225.dart';

void main() {
  initializeJsonMapper(
      serializationOptions: compactOptions,
      adapters: [starlinkGeneratedAdapter, unitTestingGeneratedAdapter]).info();

  testCacheManager();
  testAdapterManager();
  testIssue225();
  testIssue234();
  testScheme();
  testDefaultValue();
  testRequired();
  testConvertersCaching();
  testMixinCases();
  testNameCasing();
  testErrorHandling();
  testConverters();
  testValueDecorators();
  testConstructors();
  testPartialDeserialization();
  testIntegration();
  testSpecialCases();
  testGenerics();
  testNamePath();
  testInheritance();
  testInjection();
  testCollections();
  testTupleCases();
  testEnums();
  testFlatten();
  raw_json.main();
}
