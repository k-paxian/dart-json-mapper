library json_mapper.test;

import 'package:reflectable/reflectable.dart';
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
import 'dart:convert';
import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';

import 'test.value.decorators.dart';
import './test.raw_json.dart' as raw_json;

@JsonSerializable()
@Json(caseStyle: CaseStyle.pascal, ignoreNullMembers: true)
class DTDeviceStatus {
  String? deviceIdent;
  List<DTGatewayConnection> gatewayConnections = [];
}

@JsonSerializable()
@Json(caseStyle: CaseStyle.pascal, ignoreNullMembers: true)
class DTGatewayConnection {
  String gwIdent = '';
  DTSignalStrength? signalStrength;
}

@JsonSerializable()
@Json(ignoreNullMembers: true)
class DTSignalStrength {
  @JsonProperty(name: 'Strength')
  String strength = 'NoSignal';

  @JsonProperty(name: 'RSSI')
  int? rssi;

  @JsonProperty(name: 'SpreadFactor')
  int? spreadFactor;
}

void testIssue234() {
  group('Issue 234 tests', () {
    test('Cannot map uppercase ints or doubles', () {
      // given
      final json =
          '''{"Devices": [{"DeviceIdent": "94949494", "GatewayConnections": [{"GwIdent": "39847384", "SignalStrength": {"Strength": "Strong", "RSSI": -74, "SNR": 0.0, "SpreadFactor": 5}}]}]}''';

      // when
      final jsonMap = jsonDecode(json);
      final devices =
          JsonMapper.deserialize<List<DTDeviceStatus>>(jsonMap['Devices']);

      // then
      expect(devices, isNotNull);
      expect(devices!.length, 1);
      final device = devices[0];
      expect(device.gatewayConnections.length, 1);
      final gatewayConnection = device.gatewayConnections[0];
      expect(gatewayConnection.signalStrength, isNotNull);
      expect(gatewayConnection.signalStrength!.strength, 'Strong');
      expect(gatewayConnection.signalStrength!.rssi, -74);
      expect(gatewayConnection.signalStrength!.spreadFactor, 5);
    });
  });
}

void main() {
  initializeJsonMapper(
      serializationOptions: compactOptions,
      adapters: [starlinkGeneratedAdapter, unitTestingGeneratedAdapter]).info();

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
