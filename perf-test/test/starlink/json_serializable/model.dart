part of 'json_serializable_test.dart';

@JsonSerializable()
class SpaceTrack {
  @JsonKey(name: 'CCSDS_OMM_VERS')
  String? ccsdsOmmVers;

  @JsonKey(name: 'COMMENT')
  String? comment;

  @JsonKey(name: 'ORIGINATOR')
  String? originator;

  @JsonKey(name: 'OBJECT_NAME')
  String? objectName;

  @JsonKey(name: 'OBJECT_ID')
  String? objectId;

  @JsonKey(name: 'OBJECT_TYPE')
  String? objectType;

  @JsonKey(name: 'CENTER_NAME')
  String? centerName;

  @JsonKey(name: 'REF_FRAME')
  String? refFrame;

  @JsonKey(name: 'TIME_SYSTEM')
  String? timeSystem;

  @JsonKey(name: 'MEAN_ELEMENT_THEORY')
  String? meanElementTheory;

  @JsonKey(name: 'CLASSIFICATION_TYPE')
  String? classificationType;

  @JsonKey(name: 'RCS_SIZE')
  String? rcsSize;

  @JsonKey(name: 'COUNTRY_CODE')
  String? countryCode;

  @JsonKey(name: 'SITE')
  String? site;

  @JsonKey(name: 'TLE_LINE0')
  String? tleLine0;

  @JsonKey(name: 'TLE_LINE1')
  String? tleLine1;

  @JsonKey(name: 'TLE_LINE2')
  String? tleLine2;

  @JsonKey(name: 'MEAN_MOTION')
  num? meanMotion;

  @JsonKey(name: 'ECCENTRICITY')
  num? eccentricity;

  @JsonKey(name: 'RA_OF_ASC_NODE')
  num? raOfAscNode;

  @JsonKey(name: 'ARG_OF_PERICENTER')
  num? argOfPericenter;

  @JsonKey(name: 'MEAN_ANOMALY')
  num? meanAnomaly;

  @JsonKey(name: 'EPHEMERIS_TYPE')
  num? ephemerisType;

  @JsonKey(name: 'NORAD_CAT_ID')
  num? noradCatId;

  @JsonKey(name: 'ELEMENT_SET_NO')
  num? elementSetNo;

  @JsonKey(name: 'REV_AT_EPOCH')
  num? revAtEpoch;

  @JsonKey(name: 'BSTAR')
  num? bstar;

  @JsonKey(name: 'MEAN_MOTION_DOT')
  num? meanMotionDot;

  @JsonKey(name: 'MEAN_MOTION_DDOT')
  num? meanMotionDdot;

  @JsonKey(name: 'SEMIMAJOR_AXIS')
  num? semimajorAxis;

  @JsonKey(name: 'PERIOD')
  num? period;

  @JsonKey(name: 'APOAPSIS')
  num? apoapsis;

  @JsonKey(name: 'PERIAPSIS')
  num? periapsis;

  @JsonKey(name: 'DECAYED')
  num? decayed;

  @JsonKey(name: 'FILE')
  num? file;

  @JsonKey(name: 'GP_ID')
  num? gpId;

  @JsonKey(
      name: 'DECAY_DATE',
      fromJson: _dateTimeFromStringDefault,
      toJson: _dateTimeToStringDefault)
  DateTime? decayDate;

  @JsonKey(
      name: 'CREATION_DATE',
      fromJson: _dateTimeFromStringDefault,
      toJson: _dateTimeToStringDefault)
  DateTime? creationDate;

  @JsonKey(
      name: 'EPOCH',
      fromJson: _dateTimeFromStringDefault,
      toJson: _dateTimeToStringDefault)
  DateTime? epoch;

  @JsonKey(
      name: 'LAUNCH_DATE',
      fromJson: _dateTimeFromString,
      toJson: _dateTimeToString)
  DateTime? launchDate;

  SpaceTrack();

  static DateTime? _dateTimeFromString(String value) =>
      DateFormat('yyyy-MM-dd').parse(value);

  static String? _dateTimeToString(DateTime? dateTime) =>
      DateFormat('yyyy-MM-dd').format(dateTime!);

  static DateTime? _dateTimeFromStringDefault(dynamic value) =>
      value is String ? DateTime.tryParse(value) : value;

  static String _dateTimeToStringDefault(DateTime? dateTime) =>
      dateTime.toString();

  factory SpaceTrack.fromJson(Map<String, dynamic> json) =>
      _$SpaceTrackFromJson(json);

  Map<String, dynamic> toJson() => _$SpaceTrackToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Record {
  SpaceTrack? spaceTrack;
  String? version;
  String? id;
  String? launch;

  Record();

  factory Record.fromJson(Map<String, dynamic> json) => _$RecordFromJson(json);

  Map<String, dynamic> toJson() => _$RecordToJson(this);
}
