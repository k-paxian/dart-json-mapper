## Starlink test

For the sake of a simplest use case we will examine JSON output from this public endpoint:
https://api.spacexdata.com/v4/starlink

One record JSON sample:

```json
[
  {
    "spaceTrack": {
      "CCSDS_OMM_VERS": "2.0",
      "COMMENT": "GENERATED VIA SPACE-TRACK.ORG API",
      "CREATION_DATE": "2020-06-21 10:06:09",
      "ORIGINATOR": "18 SPCS",
      "OBJECT_NAME": "STARLINK-30",
      "OBJECT_ID": "2019-029K",
      "CENTER_NAME": "EARTH",
      "REF_FRAME": "TEME",
      "TIME_SYSTEM": "UTC",
      "MEAN_ELEMENT_THEORY": "SGP4",
      "EPOCH": "2020-06-21 08:00:01.999872",
      "MEAN_MOTION": 15.43874115,
      "ECCENTRICITY": 0.000125,
      "INCLINATION": 52.995,
      "RA_OF_ASC_NODE": 188.7153,
      "ARG_OF_PERICENTER": 102.274,
      "MEAN_ANOMALY": 177.4855,
      "EPHEMERIS_TYPE": 0,
      "CLASSIFICATION_TYPE": "U",
      "NORAD_CAT_ID": 44244,
      "ELEMENT_SET_NO": 999,
      "REV_AT_EPOCH": 5970,
      "BSTAR": -0.00032,
      "MEAN_MOTION_DOT": -0.00015044,
      "MEAN_MOTION_DDOT": 0,
      "SEMIMAJOR_AXIS": 6812.825,
      "PERIOD": 93.271,
      "APOAPSIS": 435.541,
      "PERIAPSIS": 433.838,
      "OBJECT_TYPE": "PAYLOAD",
      "RCS_SIZE": "LARGE",
      "COUNTRY_CODE": "US",
      "LAUNCH_DATE": "2019-05-24",
      "SITE": "AFETR",
      "DECAY_DATE": null,
      "DECAYED": 0,
      "FILE": 2770040,
      "GP_ID": 156071228,
      "TLE_LINE0": "0 STARLINK-30",
      "TLE_LINE1": "1 44244U 19029K   20173.33335648 -.00015044  00000-0 -31780-3 0  9995",
      "TLE_LINE2": "2 44244  52.9950 188.7153 0001250 102.2740 177.4855 15.43874115 59704"
    },
    "version": "v0.9",
    "launch": "5eb87d30ffd86e000604b378",
    "id": "5eed770f096e59000698560d"
  },
  ...
]
```

# built_value

Model code
```dart
abstract class SpaceTrack implements Built<SpaceTrack, SpaceTrackBuilder> {
  SpaceTrack._();

  factory SpaceTrack([updates(SpaceTrackBuilder b)]) = _$SpaceTrack;

  @BuiltValueField(wireName: 'CCSDS_OMM_VERS')
  String get cCSDSOMMVERS;

  @BuiltValueField(wireName: 'COMMENT')
  String get cOMMENT;

  @BuiltValueField(wireName: 'CREATION_DATE')
  String get cREATIONDATE;

  @BuiltValueField(wireName: 'ORIGINATOR')
  String get oRIGINATOR;

  @BuiltValueField(wireName: 'OBJECT_NAME')
  String get oBJECTNAME;

  @BuiltValueField(wireName: 'OBJECT_ID')
  String get oBJECTID;

  @BuiltValueField(wireName: 'CENTER_NAME')
  String get cENTERNAME;

  @BuiltValueField(wireName: 'REF_FRAME')
  String get rEFFRAME;

  @BuiltValueField(wireName: 'TIME_SYSTEM')
  String get tIMESYSTEM;

  @BuiltValueField(wireName: 'MEAN_ELEMENT_THEORY')
  String get mEANELEMENTTHEORY;

  @BuiltValueField(wireName: 'EPOCH')
  String get ePOCH;

  @BuiltValueField(wireName: 'MEAN_MOTION')
  num get mEANMOTION;

  @BuiltValueField(wireName: 'ECCENTRICITY')
  num get eCCENTRICITY;

  @BuiltValueField(wireName: 'INCLINATION')
  num get iNCLINATION;

  @BuiltValueField(wireName: 'RA_OF_ASC_NODE')
  num get rAOFASCNODE;

  @BuiltValueField(wireName: 'ARG_OF_PERICENTER')
  num get aRGOFPERICENTER;

  @BuiltValueField(wireName: 'MEAN_ANOMALY')
  num get mEANANOMALY;

  @BuiltValueField(wireName: 'EPHEMERIS_TYPE')
  num get ePHEMERISTYPE;

  @BuiltValueField(wireName: 'CLASSIFICATION_TYPE')
  String get cLASSIFICATIONTYPE;

  @BuiltValueField(wireName: 'NORAD_CAT_ID')
  num get nORADCATID;

  @BuiltValueField(wireName: 'ELEMENT_SET_NO')
  num get eLEMENTSETNO;

  @BuiltValueField(wireName: 'REV_AT_EPOCH')
  num get rEVATEPOCH;

  @BuiltValueField(wireName: 'BSTAR')
  num get bSTAR;

  @BuiltValueField(wireName: 'MEAN_MOTION_DOT')
  num get mEANMOTIONDOT;

  @BuiltValueField(wireName: 'MEAN_MOTION_DDOT')
  num get mEANMOTIONDDOT;

  @BuiltValueField(wireName: 'SEMIMAJOR_AXIS')
  num get sEMIMAJORAXIS;

  @BuiltValueField(wireName: 'PERIOD')
  num get pERIOD;

  @BuiltValueField(wireName: 'APOAPSIS')
  num get aPOAPSIS;

  @BuiltValueField(wireName: 'PERIAPSIS')
  num get pERIAPSIS;

  @BuiltValueField(wireName: 'OBJECT_TYPE')
  String get oBJECTTYPE;

  @BuiltValueField(wireName: 'RCS_SIZE')
  String get rCSSIZE;

  @BuiltValueField(wireName: 'COUNTRY_CODE')
  String get cOUNTRYCODE;

  @BuiltValueField(wireName: 'LAUNCH_DATE')
  String get lAUNCHDATE;

  @BuiltValueField(wireName: 'SITE')
  String get sITE;

  @BuiltValueField(wireName: 'DECAY_DATE')
  @nullable
  String get dECAYDATE;

  @BuiltValueField(wireName: 'DECAYED')
  num get dECAYED;

  @BuiltValueField(wireName: 'FILE')
  num get fILE;

  @BuiltValueField(wireName: 'GP_ID')
  num get gPID;

  @BuiltValueField(wireName: 'TLE_LINE0')
  String get tLELINE0;

  @BuiltValueField(wireName: 'TLE_LINE1')
  String get tLELINE1;

  @BuiltValueField(wireName: 'TLE_LINE2')
  String get tLELINE2;

  String toJson() {
    return json.encode(serializers.serializeWith(SpaceTrack.serializer, this));
  }

  static SpaceTrack fromJson(String jsonString) {
    return serializers.deserializeWith(
        SpaceTrack.serializer, json.decode(jsonString));
  }

  static Serializer<SpaceTrack> get serializer => _$spaceTrackSerializer;
}

abstract class Record implements Built<Record, RecordBuilder> {
  Record._();

  factory Record([updates(RecordBuilder b)]) = _$Record;

  @BuiltValueField(wireName: 'spaceTrack')
  SpaceTrack get spaceTrack;

  @BuiltValueField(wireName: 'version')
  String get version;

  @BuiltValueField(wireName: 'launch')
  String get launch;

  @BuiltValueField(wireName: 'id')
  String get id;

  String toJson() {
    return json.encode(serializers.serializeWith(Record.serializer, this));
  }

  static Record fromJson(String jsonString) {
    return serializers.deserializeWith(
        Record.serializer, json.decode(jsonString));
  }

  static Serializer<Record> get serializer => _$recordSerializer;
}
```

Deserialization of 537 records executed in **191ms**, at **0.36** ms per record

Serialization of 537 records executed in **53ms**, at **0.099** ms per record

# json_serializable

Model code
```dart
part of perf_test.test;

@JsonSerializable()
class SpaceTrack {
  @JsonKey(name: 'CCSDS_OMM_VERS')
  String ccsdsOmmVers;

  @JsonKey(name: 'COMMENT')
  String comment;

  @JsonKey(name: 'ORIGINATOR')
  String originator;

  @JsonKey(name: 'OBJECT_NAME')
  String objectName;

  @JsonKey(name: 'OBJECT_ID')
  String objectId;

  @JsonKey(name: 'OBJECT_TYPE')
  String objectType;

  @JsonKey(name: 'CENTER_NAME')
  String centerName;

  @JsonKey(name: 'REF_FRAME')
  String refFrame;

  @JsonKey(name: 'TIME_SYSTEM')
  String timeSystem;

  @JsonKey(name: 'MEAN_ELEMENT_THEORY')
  String meanElementTheory;

  @JsonKey(name: 'CLASSIFICATION_TYPE')
  String classificationType;

  @JsonKey(name: 'RCS_SIZE')
  String rcsSize;

  @JsonKey(name: 'COUNTRY_CODE')
  String countryCode;

  @JsonKey(name: 'SITE')
  String site;

  @JsonKey(name: 'TLE_LINE0')
  String tleLine0;

  @JsonKey(name: 'TLE_LINE1')
  String tleLine1;

  @JsonKey(name: 'TLE_LINE2')
  String tleLine2;

  @JsonKey(name: 'MEAN_MOTION')
  num meanMotion;

  @JsonKey(name: 'ECCENTRICITY')
  num eccentricity;

  @JsonKey(name: 'RA_OF_ASC_NODE')
  num raOfAscNode;

  @JsonKey(name: 'ARG_OF_PERICENTER')
  num argOfPericenter;

  @JsonKey(name: 'MEAN_ANOMALY')
  num meanAnomaly;

  @JsonKey(name: 'EPHEMERIS_TYPE')
  num ephemerisType;

  @JsonKey(name: 'NORAD_CAT_ID')
  num noradCatId;

  @JsonKey(name: 'ELEMENT_SET_NO')
  num elementSetNo;

  @JsonKey(name: 'REV_AT_EPOCH')
  num revAtEpoch;

  @JsonKey(name: 'BSTAR')
  num bstar;

  @JsonKey(name: 'MEAN_MOTION_DOT')
  num meanMotionDot;

  @JsonKey(name: 'MEAN_MOTION_DDOT')
  num meanMotionDdot;

  @JsonKey(name: 'SEMIMAJOR_AXIS')
  num semimajorAxis;

  @JsonKey(name: 'PERIOD')
  num period;

  @JsonKey(name: 'APOAPSIS')
  num apoapsis;

  @JsonKey(name: 'PERIAPSIS')
  num periapsis;

  @JsonKey(name: 'DECAYED')
  num decayed;

  @JsonKey(name: 'FILE')
  num file;

  @JsonKey(name: 'GP_ID')
  num gpId;

  @JsonKey(
      name: 'DECAY_DATE',
      fromJson: _dateTimeFromStringDefault,
      toJson: _dateTimeToStringDefault)
  DateTime decayDate;

  @JsonKey(
      name: 'CREATION_DATE',
      fromJson: _dateTimeFromStringDefault,
      toJson: _dateTimeToStringDefault)
  DateTime creationDate;

  @JsonKey(
      name: 'EPOCH',
      fromJson: _dateTimeFromStringDefault,
      toJson: _dateTimeToStringDefault)
  DateTime epoch;

  @JsonKey(
      name: 'LAUNCH_DATE',
      fromJson: _dateTimeFromString,
      toJson: _dateTimeToString)
  DateTime launchDate;

  SpaceTrack();

  static DateTime _dateTimeFromString(String value) =>
      DateFormat('yyyy-MM-dd').parse(value);

  static String _dateTimeToString(DateTime dateTime) =>
      DateFormat('yyyy-MM-dd').format(dateTime);

  static DateTime _dateTimeFromStringDefault(dynamic value) =>
      value is String ? DateTime.parse(value) : value;

  static String _dateTimeToStringDefault(DateTime dateTime) =>
      dateTime.toString();

  factory SpaceTrack.fromJson(Map<String, dynamic> json) =>
      _$SpaceTrackFromJson(json);

  Map<String, dynamic> toJson() => _$SpaceTrackToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Record {
  SpaceTrack spaceTrack;
  String version;
  String id;
  String launch;

  Record();

  factory Record.fromJson(Map<String, dynamic> json) => _$RecordFromJson(json);

  Map<String, dynamic> toJson() => _$RecordToJson(this);
}
```

Deserialization of 537 records executed in **200ms**, at **0.37** ms per record

Serialization of 537 records executed in **145ms**, at **0.27** ms per record

# dart_json_mapper

Model code
```dart
@jsonSerializable
@Json(caseStyle: CaseStyle.SnakeAllCaps)
class SpaceTrack {
  String ccsdsOmmVers;
  String comment;
  String originator;
  String objectName;
  String objectId;
  String objectType;
  String centerName;
  String refFrame;
  String timeSystem;
  String meanElementTheory;
  String classificationType;
  String rcsSize;
  String countryCode;
  String site;
  String tleLine0;
  String tleLine1;
  String tleLine2;

  num meanMotion;
  num eccentricity;
  num raOfAscNode;
  num argOfPericenter;
  num meanAnomaly;
  num ephemerisType;
  num noradCatId;
  num elementSetNo;
  num revAtEpoch;
  num bstar;
  num meanMotionDot;
  num meanMotionDdot;
  num semimajorAxis;
  num period;
  num apoapsis;
  num periapsis;
  num decayed;
  num file;
  num gpId;

  DateTime decayDate;
  DateTime creationDate;
  DateTime epoch;

  @JsonProperty(converterParams: {'format': 'yyyy-MM-dd'})
  DateTime launchDate;
}

@jsonSerializable
class Record {
  SpaceTrack spaceTrack;
  String version;
  String id;
  String launch;
}
```

Deserialization of 537 records executed in **6235ms**, at **12** ms per record

Serialization of 537 records executed in **3378ms**, at **6.3** ms per record

## Instead of conclusion, everything has it's price tag.

If your top most priority is **performance** at any cost and you are OK to
write / read / maintain lot more boilerplate code then your natural choice would be `json_serializable` or `built_value`

If your top most priority is to enjoy **clean, concise, readable, uncluttered code**, and you are OK
to pay for all those benefits by performance degradation your natural choice would be `dart_json_mapper`