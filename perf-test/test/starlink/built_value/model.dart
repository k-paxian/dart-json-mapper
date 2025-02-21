part of 'built_value_test.dart';

abstract class SpaceTrack implements Built<SpaceTrack, SpaceTrackBuilder> {
  SpaceTrack._();

  // ignore: use_function_type_syntax_for_parameters
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
  String? get dECAYDATE;

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

  static SpaceTrack? fromJson(String jsonString) {
    return serializers.deserializeWith(
        SpaceTrack.serializer, json.decode(jsonString));
  }

  static Serializer<SpaceTrack> get serializer => _$spaceTrackSerializer;
}

abstract class Record implements Built<Record, RecordBuilder> {
  Record._();

  // ignore: use_function_type_syntax_for_parameters
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

  static Record? fromJson(String jsonString) {
    return serializers.deserializeWith(
        Record.serializer, json.decode(jsonString));
  }

  static Serializer<Record> get serializer => _$recordSerializer;
}
