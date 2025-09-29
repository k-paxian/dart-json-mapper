import 'dart:convert';
import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';

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