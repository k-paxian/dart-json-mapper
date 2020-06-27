// GENERATED CODE - DO NOT MODIFY BY HAND

part of perf_test.test;

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers = (new Serializers().toBuilder()
      ..add(Record.serializer)
      ..add(SpaceTrack.serializer))
    .build();
Serializer<SpaceTrack> _$spaceTrackSerializer = new _$SpaceTrackSerializer();
Serializer<Record> _$recordSerializer = new _$RecordSerializer();

class _$SpaceTrackSerializer implements StructuredSerializer<SpaceTrack> {
  @override
  final Iterable<Type> types = const [SpaceTrack, _$SpaceTrack];
  @override
  final String wireName = 'SpaceTrack';

  @override
  Iterable<Object> serialize(Serializers serializers, SpaceTrack object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'CCSDS_OMM_VERS',
      serializers.serialize(object.cCSDSOMMVERS,
          specifiedType: const FullType(String)),
      'COMMENT',
      serializers.serialize(object.cOMMENT,
          specifiedType: const FullType(String)),
      'CREATION_DATE',
      serializers.serialize(object.cREATIONDATE,
          specifiedType: const FullType(String)),
      'ORIGINATOR',
      serializers.serialize(object.oRIGINATOR,
          specifiedType: const FullType(String)),
      'OBJECT_NAME',
      serializers.serialize(object.oBJECTNAME,
          specifiedType: const FullType(String)),
      'OBJECT_ID',
      serializers.serialize(object.oBJECTID,
          specifiedType: const FullType(String)),
      'CENTER_NAME',
      serializers.serialize(object.cENTERNAME,
          specifiedType: const FullType(String)),
      'REF_FRAME',
      serializers.serialize(object.rEFFRAME,
          specifiedType: const FullType(String)),
      'TIME_SYSTEM',
      serializers.serialize(object.tIMESYSTEM,
          specifiedType: const FullType(String)),
      'MEAN_ELEMENT_THEORY',
      serializers.serialize(object.mEANELEMENTTHEORY,
          specifiedType: const FullType(String)),
      'EPOCH',
      serializers.serialize(object.ePOCH,
          specifiedType: const FullType(String)),
      'MEAN_MOTION',
      serializers.serialize(object.mEANMOTION,
          specifiedType: const FullType(num)),
      'ECCENTRICITY',
      serializers.serialize(object.eCCENTRICITY,
          specifiedType: const FullType(num)),
      'INCLINATION',
      serializers.serialize(object.iNCLINATION,
          specifiedType: const FullType(num)),
      'RA_OF_ASC_NODE',
      serializers.serialize(object.rAOFASCNODE,
          specifiedType: const FullType(num)),
      'ARG_OF_PERICENTER',
      serializers.serialize(object.aRGOFPERICENTER,
          specifiedType: const FullType(num)),
      'MEAN_ANOMALY',
      serializers.serialize(object.mEANANOMALY,
          specifiedType: const FullType(num)),
      'EPHEMERIS_TYPE',
      serializers.serialize(object.ePHEMERISTYPE,
          specifiedType: const FullType(num)),
      'CLASSIFICATION_TYPE',
      serializers.serialize(object.cLASSIFICATIONTYPE,
          specifiedType: const FullType(String)),
      'NORAD_CAT_ID',
      serializers.serialize(object.nORADCATID,
          specifiedType: const FullType(num)),
      'ELEMENT_SET_NO',
      serializers.serialize(object.eLEMENTSETNO,
          specifiedType: const FullType(num)),
      'REV_AT_EPOCH',
      serializers.serialize(object.rEVATEPOCH,
          specifiedType: const FullType(num)),
      'BSTAR',
      serializers.serialize(object.bSTAR, specifiedType: const FullType(num)),
      'MEAN_MOTION_DOT',
      serializers.serialize(object.mEANMOTIONDOT,
          specifiedType: const FullType(num)),
      'MEAN_MOTION_DDOT',
      serializers.serialize(object.mEANMOTIONDDOT,
          specifiedType: const FullType(num)),
      'SEMIMAJOR_AXIS',
      serializers.serialize(object.sEMIMAJORAXIS,
          specifiedType: const FullType(num)),
      'PERIOD',
      serializers.serialize(object.pERIOD, specifiedType: const FullType(num)),
      'APOAPSIS',
      serializers.serialize(object.aPOAPSIS,
          specifiedType: const FullType(num)),
      'PERIAPSIS',
      serializers.serialize(object.pERIAPSIS,
          specifiedType: const FullType(num)),
      'OBJECT_TYPE',
      serializers.serialize(object.oBJECTTYPE,
          specifiedType: const FullType(String)),
      'RCS_SIZE',
      serializers.serialize(object.rCSSIZE,
          specifiedType: const FullType(String)),
      'COUNTRY_CODE',
      serializers.serialize(object.cOUNTRYCODE,
          specifiedType: const FullType(String)),
      'LAUNCH_DATE',
      serializers.serialize(object.lAUNCHDATE,
          specifiedType: const FullType(String)),
      'SITE',
      serializers.serialize(object.sITE, specifiedType: const FullType(String)),
      'DECAYED',
      serializers.serialize(object.dECAYED, specifiedType: const FullType(num)),
      'FILE',
      serializers.serialize(object.fILE, specifiedType: const FullType(num)),
      'GP_ID',
      serializers.serialize(object.gPID, specifiedType: const FullType(num)),
      'TLE_LINE0',
      serializers.serialize(object.tLELINE0,
          specifiedType: const FullType(String)),
      'TLE_LINE1',
      serializers.serialize(object.tLELINE1,
          specifiedType: const FullType(String)),
      'TLE_LINE2',
      serializers.serialize(object.tLELINE2,
          specifiedType: const FullType(String)),
    ];
    if (object.dECAYDATE != null) {
      result
        ..add('DECAY_DATE')
        ..add(serializers.serialize(object.dECAYDATE,
            specifiedType: const FullType(String)));
    }
    return result;
  }

  @override
  SpaceTrack deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new SpaceTrackBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'CCSDS_OMM_VERS':
          result.cCSDSOMMVERS = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'COMMENT':
          result.cOMMENT = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'CREATION_DATE':
          result.cREATIONDATE = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'ORIGINATOR':
          result.oRIGINATOR = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'OBJECT_NAME':
          result.oBJECTNAME = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'OBJECT_ID':
          result.oBJECTID = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'CENTER_NAME':
          result.cENTERNAME = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'REF_FRAME':
          result.rEFFRAME = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'TIME_SYSTEM':
          result.tIMESYSTEM = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'MEAN_ELEMENT_THEORY':
          result.mEANELEMENTTHEORY = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'EPOCH':
          result.ePOCH = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'MEAN_MOTION':
          result.mEANMOTION = serializers.deserialize(value,
              specifiedType: const FullType(num)) as num;
          break;
        case 'ECCENTRICITY':
          result.eCCENTRICITY = serializers.deserialize(value,
              specifiedType: const FullType(num)) as num;
          break;
        case 'INCLINATION':
          result.iNCLINATION = serializers.deserialize(value,
              specifiedType: const FullType(num)) as num;
          break;
        case 'RA_OF_ASC_NODE':
          result.rAOFASCNODE = serializers.deserialize(value,
              specifiedType: const FullType(num)) as num;
          break;
        case 'ARG_OF_PERICENTER':
          result.aRGOFPERICENTER = serializers.deserialize(value,
              specifiedType: const FullType(num)) as num;
          break;
        case 'MEAN_ANOMALY':
          result.mEANANOMALY = serializers.deserialize(value,
              specifiedType: const FullType(num)) as num;
          break;
        case 'EPHEMERIS_TYPE':
          result.ePHEMERISTYPE = serializers.deserialize(value,
              specifiedType: const FullType(num)) as num;
          break;
        case 'CLASSIFICATION_TYPE':
          result.cLASSIFICATIONTYPE = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'NORAD_CAT_ID':
          result.nORADCATID = serializers.deserialize(value,
              specifiedType: const FullType(num)) as num;
          break;
        case 'ELEMENT_SET_NO':
          result.eLEMENTSETNO = serializers.deserialize(value,
              specifiedType: const FullType(num)) as num;
          break;
        case 'REV_AT_EPOCH':
          result.rEVATEPOCH = serializers.deserialize(value,
              specifiedType: const FullType(num)) as num;
          break;
        case 'BSTAR':
          result.bSTAR = serializers.deserialize(value,
              specifiedType: const FullType(num)) as num;
          break;
        case 'MEAN_MOTION_DOT':
          result.mEANMOTIONDOT = serializers.deserialize(value,
              specifiedType: const FullType(num)) as num;
          break;
        case 'MEAN_MOTION_DDOT':
          result.mEANMOTIONDDOT = serializers.deserialize(value,
              specifiedType: const FullType(num)) as num;
          break;
        case 'SEMIMAJOR_AXIS':
          result.sEMIMAJORAXIS = serializers.deserialize(value,
              specifiedType: const FullType(num)) as num;
          break;
        case 'PERIOD':
          result.pERIOD = serializers.deserialize(value,
              specifiedType: const FullType(num)) as num;
          break;
        case 'APOAPSIS':
          result.aPOAPSIS = serializers.deserialize(value,
              specifiedType: const FullType(num)) as num;
          break;
        case 'PERIAPSIS':
          result.pERIAPSIS = serializers.deserialize(value,
              specifiedType: const FullType(num)) as num;
          break;
        case 'OBJECT_TYPE':
          result.oBJECTTYPE = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'RCS_SIZE':
          result.rCSSIZE = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'COUNTRY_CODE':
          result.cOUNTRYCODE = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'LAUNCH_DATE':
          result.lAUNCHDATE = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'SITE':
          result.sITE = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'DECAY_DATE':
          result.dECAYDATE = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'DECAYED':
          result.dECAYED = serializers.deserialize(value,
              specifiedType: const FullType(num)) as num;
          break;
        case 'FILE':
          result.fILE = serializers.deserialize(value,
              specifiedType: const FullType(num)) as num;
          break;
        case 'GP_ID':
          result.gPID = serializers.deserialize(value,
              specifiedType: const FullType(num)) as num;
          break;
        case 'TLE_LINE0':
          result.tLELINE0 = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'TLE_LINE1':
          result.tLELINE1 = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'TLE_LINE2':
          result.tLELINE2 = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$RecordSerializer implements StructuredSerializer<Record> {
  @override
  final Iterable<Type> types = const [Record, _$Record];
  @override
  final String wireName = 'Record';

  @override
  Iterable<Object> serialize(Serializers serializers, Record object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'spaceTrack',
      serializers.serialize(object.spaceTrack,
          specifiedType: const FullType(SpaceTrack)),
      'version',
      serializers.serialize(object.version,
          specifiedType: const FullType(String)),
      'launch',
      serializers.serialize(object.launch,
          specifiedType: const FullType(String)),
      'id',
      serializers.serialize(object.id, specifiedType: const FullType(String)),
    ];

    return result;
  }

  @override
  Record deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new RecordBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'spaceTrack':
          result.spaceTrack.replace(serializers.deserialize(value,
              specifiedType: const FullType(SpaceTrack)) as SpaceTrack);
          break;
        case 'version':
          result.version = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'launch':
          result.launch = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'id':
          result.id = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
      }
    }

    return result.build();
  }
}

class _$SpaceTrack extends SpaceTrack {
  @override
  final String cCSDSOMMVERS;
  @override
  final String cOMMENT;
  @override
  final String cREATIONDATE;
  @override
  final String oRIGINATOR;
  @override
  final String oBJECTNAME;
  @override
  final String oBJECTID;
  @override
  final String cENTERNAME;
  @override
  final String rEFFRAME;
  @override
  final String tIMESYSTEM;
  @override
  final String mEANELEMENTTHEORY;
  @override
  final String ePOCH;
  @override
  final num mEANMOTION;
  @override
  final num eCCENTRICITY;
  @override
  final num iNCLINATION;
  @override
  final num rAOFASCNODE;
  @override
  final num aRGOFPERICENTER;
  @override
  final num mEANANOMALY;
  @override
  final num ePHEMERISTYPE;
  @override
  final String cLASSIFICATIONTYPE;
  @override
  final num nORADCATID;
  @override
  final num eLEMENTSETNO;
  @override
  final num rEVATEPOCH;
  @override
  final num bSTAR;
  @override
  final num mEANMOTIONDOT;
  @override
  final num mEANMOTIONDDOT;
  @override
  final num sEMIMAJORAXIS;
  @override
  final num pERIOD;
  @override
  final num aPOAPSIS;
  @override
  final num pERIAPSIS;
  @override
  final String oBJECTTYPE;
  @override
  final String rCSSIZE;
  @override
  final String cOUNTRYCODE;
  @override
  final String lAUNCHDATE;
  @override
  final String sITE;
  @override
  final String dECAYDATE;
  @override
  final num dECAYED;
  @override
  final num fILE;
  @override
  final num gPID;
  @override
  final String tLELINE0;
  @override
  final String tLELINE1;
  @override
  final String tLELINE2;

  factory _$SpaceTrack([void Function(SpaceTrackBuilder) updates]) =>
      (new SpaceTrackBuilder()..update(updates)).build();

  _$SpaceTrack._(
      {this.cCSDSOMMVERS,
      this.cOMMENT,
      this.cREATIONDATE,
      this.oRIGINATOR,
      this.oBJECTNAME,
      this.oBJECTID,
      this.cENTERNAME,
      this.rEFFRAME,
      this.tIMESYSTEM,
      this.mEANELEMENTTHEORY,
      this.ePOCH,
      this.mEANMOTION,
      this.eCCENTRICITY,
      this.iNCLINATION,
      this.rAOFASCNODE,
      this.aRGOFPERICENTER,
      this.mEANANOMALY,
      this.ePHEMERISTYPE,
      this.cLASSIFICATIONTYPE,
      this.nORADCATID,
      this.eLEMENTSETNO,
      this.rEVATEPOCH,
      this.bSTAR,
      this.mEANMOTIONDOT,
      this.mEANMOTIONDDOT,
      this.sEMIMAJORAXIS,
      this.pERIOD,
      this.aPOAPSIS,
      this.pERIAPSIS,
      this.oBJECTTYPE,
      this.rCSSIZE,
      this.cOUNTRYCODE,
      this.lAUNCHDATE,
      this.sITE,
      this.dECAYDATE,
      this.dECAYED,
      this.fILE,
      this.gPID,
      this.tLELINE0,
      this.tLELINE1,
      this.tLELINE2})
      : super._() {
    if (cCSDSOMMVERS == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'cCSDSOMMVERS');
    }
    if (cOMMENT == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'cOMMENT');
    }
    if (cREATIONDATE == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'cREATIONDATE');
    }
    if (oRIGINATOR == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'oRIGINATOR');
    }
    if (oBJECTNAME == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'oBJECTNAME');
    }
    if (oBJECTID == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'oBJECTID');
    }
    if (cENTERNAME == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'cENTERNAME');
    }
    if (rEFFRAME == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'rEFFRAME');
    }
    if (tIMESYSTEM == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'tIMESYSTEM');
    }
    if (mEANELEMENTTHEORY == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'mEANELEMENTTHEORY');
    }
    if (ePOCH == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'ePOCH');
    }
    if (mEANMOTION == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'mEANMOTION');
    }
    if (eCCENTRICITY == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'eCCENTRICITY');
    }
    if (iNCLINATION == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'iNCLINATION');
    }
    if (rAOFASCNODE == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'rAOFASCNODE');
    }
    if (aRGOFPERICENTER == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'aRGOFPERICENTER');
    }
    if (mEANANOMALY == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'mEANANOMALY');
    }
    if (ePHEMERISTYPE == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'ePHEMERISTYPE');
    }
    if (cLASSIFICATIONTYPE == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'cLASSIFICATIONTYPE');
    }
    if (nORADCATID == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'nORADCATID');
    }
    if (eLEMENTSETNO == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'eLEMENTSETNO');
    }
    if (rEVATEPOCH == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'rEVATEPOCH');
    }
    if (bSTAR == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'bSTAR');
    }
    if (mEANMOTIONDOT == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'mEANMOTIONDOT');
    }
    if (mEANMOTIONDDOT == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'mEANMOTIONDDOT');
    }
    if (sEMIMAJORAXIS == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'sEMIMAJORAXIS');
    }
    if (pERIOD == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'pERIOD');
    }
    if (aPOAPSIS == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'aPOAPSIS');
    }
    if (pERIAPSIS == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'pERIAPSIS');
    }
    if (oBJECTTYPE == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'oBJECTTYPE');
    }
    if (rCSSIZE == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'rCSSIZE');
    }
    if (cOUNTRYCODE == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'cOUNTRYCODE');
    }
    if (lAUNCHDATE == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'lAUNCHDATE');
    }
    if (sITE == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'sITE');
    }
    if (dECAYED == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'dECAYED');
    }
    if (fILE == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'fILE');
    }
    if (gPID == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'gPID');
    }
    if (tLELINE0 == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'tLELINE0');
    }
    if (tLELINE1 == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'tLELINE1');
    }
    if (tLELINE2 == null) {
      throw new BuiltValueNullFieldError('SpaceTrack', 'tLELINE2');
    }
  }

  @override
  SpaceTrack rebuild(void Function(SpaceTrackBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SpaceTrackBuilder toBuilder() => new SpaceTrackBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SpaceTrack &&
        cCSDSOMMVERS == other.cCSDSOMMVERS &&
        cOMMENT == other.cOMMENT &&
        cREATIONDATE == other.cREATIONDATE &&
        oRIGINATOR == other.oRIGINATOR &&
        oBJECTNAME == other.oBJECTNAME &&
        oBJECTID == other.oBJECTID &&
        cENTERNAME == other.cENTERNAME &&
        rEFFRAME == other.rEFFRAME &&
        tIMESYSTEM == other.tIMESYSTEM &&
        mEANELEMENTTHEORY == other.mEANELEMENTTHEORY &&
        ePOCH == other.ePOCH &&
        mEANMOTION == other.mEANMOTION &&
        eCCENTRICITY == other.eCCENTRICITY &&
        iNCLINATION == other.iNCLINATION &&
        rAOFASCNODE == other.rAOFASCNODE &&
        aRGOFPERICENTER == other.aRGOFPERICENTER &&
        mEANANOMALY == other.mEANANOMALY &&
        ePHEMERISTYPE == other.ePHEMERISTYPE &&
        cLASSIFICATIONTYPE == other.cLASSIFICATIONTYPE &&
        nORADCATID == other.nORADCATID &&
        eLEMENTSETNO == other.eLEMENTSETNO &&
        rEVATEPOCH == other.rEVATEPOCH &&
        bSTAR == other.bSTAR &&
        mEANMOTIONDOT == other.mEANMOTIONDOT &&
        mEANMOTIONDDOT == other.mEANMOTIONDDOT &&
        sEMIMAJORAXIS == other.sEMIMAJORAXIS &&
        pERIOD == other.pERIOD &&
        aPOAPSIS == other.aPOAPSIS &&
        pERIAPSIS == other.pERIAPSIS &&
        oBJECTTYPE == other.oBJECTTYPE &&
        rCSSIZE == other.rCSSIZE &&
        cOUNTRYCODE == other.cOUNTRYCODE &&
        lAUNCHDATE == other.lAUNCHDATE &&
        sITE == other.sITE &&
        dECAYDATE == other.dECAYDATE &&
        dECAYED == other.dECAYED &&
        fILE == other.fILE &&
        gPID == other.gPID &&
        tLELINE0 == other.tLELINE0 &&
        tLELINE1 == other.tLELINE1 &&
        tLELINE2 == other.tLELINE2;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc(
            $jc(
                $jc(
                    $jc(
                        $jc(
                            $jc(
                                $jc(
                                    $jc(
                                        $jc(
                                            $jc(
                                                $jc(
                                                    $jc(
                                                        $jc(
                                                            $jc(
                                                                $jc(
                                                                    $jc(
                                                                        $jc(
                                                                            $jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc($jc(0, cCSDSOMMVERS.hashCode), cOMMENT.hashCode), cREATIONDATE.hashCode), oRIGINATOR.hashCode), oBJECTNAME.hashCode), oBJECTID.hashCode), cENTERNAME.hashCode), rEFFRAME.hashCode), tIMESYSTEM.hashCode), mEANELEMENTTHEORY.hashCode), ePOCH.hashCode), mEANMOTION.hashCode), eCCENTRICITY.hashCode), iNCLINATION.hashCode), rAOFASCNODE.hashCode), aRGOFPERICENTER.hashCode), mEANANOMALY.hashCode), ePHEMERISTYPE.hashCode), cLASSIFICATIONTYPE.hashCode), nORADCATID.hashCode), eLEMENTSETNO.hashCode), rEVATEPOCH.hashCode),
                                                                                bSTAR.hashCode),
                                                                            mEANMOTIONDOT.hashCode),
                                                                        mEANMOTIONDDOT.hashCode),
                                                                    sEMIMAJORAXIS.hashCode),
                                                                pERIOD.hashCode),
                                                            aPOAPSIS.hashCode),
                                                        pERIAPSIS.hashCode),
                                                    oBJECTTYPE.hashCode),
                                                rCSSIZE.hashCode),
                                            cOUNTRYCODE.hashCode),
                                        lAUNCHDATE.hashCode),
                                    sITE.hashCode),
                                dECAYDATE.hashCode),
                            dECAYED.hashCode),
                        fILE.hashCode),
                    gPID.hashCode),
                tLELINE0.hashCode),
            tLELINE1.hashCode),
        tLELINE2.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('SpaceTrack')
          ..add('cCSDSOMMVERS', cCSDSOMMVERS)
          ..add('cOMMENT', cOMMENT)
          ..add('cREATIONDATE', cREATIONDATE)
          ..add('oRIGINATOR', oRIGINATOR)
          ..add('oBJECTNAME', oBJECTNAME)
          ..add('oBJECTID', oBJECTID)
          ..add('cENTERNAME', cENTERNAME)
          ..add('rEFFRAME', rEFFRAME)
          ..add('tIMESYSTEM', tIMESYSTEM)
          ..add('mEANELEMENTTHEORY', mEANELEMENTTHEORY)
          ..add('ePOCH', ePOCH)
          ..add('mEANMOTION', mEANMOTION)
          ..add('eCCENTRICITY', eCCENTRICITY)
          ..add('iNCLINATION', iNCLINATION)
          ..add('rAOFASCNODE', rAOFASCNODE)
          ..add('aRGOFPERICENTER', aRGOFPERICENTER)
          ..add('mEANANOMALY', mEANANOMALY)
          ..add('ePHEMERISTYPE', ePHEMERISTYPE)
          ..add('cLASSIFICATIONTYPE', cLASSIFICATIONTYPE)
          ..add('nORADCATID', nORADCATID)
          ..add('eLEMENTSETNO', eLEMENTSETNO)
          ..add('rEVATEPOCH', rEVATEPOCH)
          ..add('bSTAR', bSTAR)
          ..add('mEANMOTIONDOT', mEANMOTIONDOT)
          ..add('mEANMOTIONDDOT', mEANMOTIONDDOT)
          ..add('sEMIMAJORAXIS', sEMIMAJORAXIS)
          ..add('pERIOD', pERIOD)
          ..add('aPOAPSIS', aPOAPSIS)
          ..add('pERIAPSIS', pERIAPSIS)
          ..add('oBJECTTYPE', oBJECTTYPE)
          ..add('rCSSIZE', rCSSIZE)
          ..add('cOUNTRYCODE', cOUNTRYCODE)
          ..add('lAUNCHDATE', lAUNCHDATE)
          ..add('sITE', sITE)
          ..add('dECAYDATE', dECAYDATE)
          ..add('dECAYED', dECAYED)
          ..add('fILE', fILE)
          ..add('gPID', gPID)
          ..add('tLELINE0', tLELINE0)
          ..add('tLELINE1', tLELINE1)
          ..add('tLELINE2', tLELINE2))
        .toString();
  }
}

class SpaceTrackBuilder implements Builder<SpaceTrack, SpaceTrackBuilder> {
  _$SpaceTrack _$v;

  String _cCSDSOMMVERS;
  String get cCSDSOMMVERS => _$this._cCSDSOMMVERS;
  set cCSDSOMMVERS(String cCSDSOMMVERS) => _$this._cCSDSOMMVERS = cCSDSOMMVERS;

  String _cOMMENT;
  String get cOMMENT => _$this._cOMMENT;
  set cOMMENT(String cOMMENT) => _$this._cOMMENT = cOMMENT;

  String _cREATIONDATE;
  String get cREATIONDATE => _$this._cREATIONDATE;
  set cREATIONDATE(String cREATIONDATE) => _$this._cREATIONDATE = cREATIONDATE;

  String _oRIGINATOR;
  String get oRIGINATOR => _$this._oRIGINATOR;
  set oRIGINATOR(String oRIGINATOR) => _$this._oRIGINATOR = oRIGINATOR;

  String _oBJECTNAME;
  String get oBJECTNAME => _$this._oBJECTNAME;
  set oBJECTNAME(String oBJECTNAME) => _$this._oBJECTNAME = oBJECTNAME;

  String _oBJECTID;
  String get oBJECTID => _$this._oBJECTID;
  set oBJECTID(String oBJECTID) => _$this._oBJECTID = oBJECTID;

  String _cENTERNAME;
  String get cENTERNAME => _$this._cENTERNAME;
  set cENTERNAME(String cENTERNAME) => _$this._cENTERNAME = cENTERNAME;

  String _rEFFRAME;
  String get rEFFRAME => _$this._rEFFRAME;
  set rEFFRAME(String rEFFRAME) => _$this._rEFFRAME = rEFFRAME;

  String _tIMESYSTEM;
  String get tIMESYSTEM => _$this._tIMESYSTEM;
  set tIMESYSTEM(String tIMESYSTEM) => _$this._tIMESYSTEM = tIMESYSTEM;

  String _mEANELEMENTTHEORY;
  String get mEANELEMENTTHEORY => _$this._mEANELEMENTTHEORY;
  set mEANELEMENTTHEORY(String mEANELEMENTTHEORY) =>
      _$this._mEANELEMENTTHEORY = mEANELEMENTTHEORY;

  String _ePOCH;
  String get ePOCH => _$this._ePOCH;
  set ePOCH(String ePOCH) => _$this._ePOCH = ePOCH;

  num _mEANMOTION;
  num get mEANMOTION => _$this._mEANMOTION;
  set mEANMOTION(num mEANMOTION) => _$this._mEANMOTION = mEANMOTION;

  num _eCCENTRICITY;
  num get eCCENTRICITY => _$this._eCCENTRICITY;
  set eCCENTRICITY(num eCCENTRICITY) => _$this._eCCENTRICITY = eCCENTRICITY;

  num _iNCLINATION;
  num get iNCLINATION => _$this._iNCLINATION;
  set iNCLINATION(num iNCLINATION) => _$this._iNCLINATION = iNCLINATION;

  num _rAOFASCNODE;
  num get rAOFASCNODE => _$this._rAOFASCNODE;
  set rAOFASCNODE(num rAOFASCNODE) => _$this._rAOFASCNODE = rAOFASCNODE;

  num _aRGOFPERICENTER;
  num get aRGOFPERICENTER => _$this._aRGOFPERICENTER;
  set aRGOFPERICENTER(num aRGOFPERICENTER) =>
      _$this._aRGOFPERICENTER = aRGOFPERICENTER;

  num _mEANANOMALY;
  num get mEANANOMALY => _$this._mEANANOMALY;
  set mEANANOMALY(num mEANANOMALY) => _$this._mEANANOMALY = mEANANOMALY;

  num _ePHEMERISTYPE;
  num get ePHEMERISTYPE => _$this._ePHEMERISTYPE;
  set ePHEMERISTYPE(num ePHEMERISTYPE) => _$this._ePHEMERISTYPE = ePHEMERISTYPE;

  String _cLASSIFICATIONTYPE;
  String get cLASSIFICATIONTYPE => _$this._cLASSIFICATIONTYPE;
  set cLASSIFICATIONTYPE(String cLASSIFICATIONTYPE) =>
      _$this._cLASSIFICATIONTYPE = cLASSIFICATIONTYPE;

  num _nORADCATID;
  num get nORADCATID => _$this._nORADCATID;
  set nORADCATID(num nORADCATID) => _$this._nORADCATID = nORADCATID;

  num _eLEMENTSETNO;
  num get eLEMENTSETNO => _$this._eLEMENTSETNO;
  set eLEMENTSETNO(num eLEMENTSETNO) => _$this._eLEMENTSETNO = eLEMENTSETNO;

  num _rEVATEPOCH;
  num get rEVATEPOCH => _$this._rEVATEPOCH;
  set rEVATEPOCH(num rEVATEPOCH) => _$this._rEVATEPOCH = rEVATEPOCH;

  num _bSTAR;
  num get bSTAR => _$this._bSTAR;
  set bSTAR(num bSTAR) => _$this._bSTAR = bSTAR;

  num _mEANMOTIONDOT;
  num get mEANMOTIONDOT => _$this._mEANMOTIONDOT;
  set mEANMOTIONDOT(num mEANMOTIONDOT) => _$this._mEANMOTIONDOT = mEANMOTIONDOT;

  num _mEANMOTIONDDOT;
  num get mEANMOTIONDDOT => _$this._mEANMOTIONDDOT;
  set mEANMOTIONDDOT(num mEANMOTIONDDOT) =>
      _$this._mEANMOTIONDDOT = mEANMOTIONDDOT;

  num _sEMIMAJORAXIS;
  num get sEMIMAJORAXIS => _$this._sEMIMAJORAXIS;
  set sEMIMAJORAXIS(num sEMIMAJORAXIS) => _$this._sEMIMAJORAXIS = sEMIMAJORAXIS;

  num _pERIOD;
  num get pERIOD => _$this._pERIOD;
  set pERIOD(num pERIOD) => _$this._pERIOD = pERIOD;

  num _aPOAPSIS;
  num get aPOAPSIS => _$this._aPOAPSIS;
  set aPOAPSIS(num aPOAPSIS) => _$this._aPOAPSIS = aPOAPSIS;

  num _pERIAPSIS;
  num get pERIAPSIS => _$this._pERIAPSIS;
  set pERIAPSIS(num pERIAPSIS) => _$this._pERIAPSIS = pERIAPSIS;

  String _oBJECTTYPE;
  String get oBJECTTYPE => _$this._oBJECTTYPE;
  set oBJECTTYPE(String oBJECTTYPE) => _$this._oBJECTTYPE = oBJECTTYPE;

  String _rCSSIZE;
  String get rCSSIZE => _$this._rCSSIZE;
  set rCSSIZE(String rCSSIZE) => _$this._rCSSIZE = rCSSIZE;

  String _cOUNTRYCODE;
  String get cOUNTRYCODE => _$this._cOUNTRYCODE;
  set cOUNTRYCODE(String cOUNTRYCODE) => _$this._cOUNTRYCODE = cOUNTRYCODE;

  String _lAUNCHDATE;
  String get lAUNCHDATE => _$this._lAUNCHDATE;
  set lAUNCHDATE(String lAUNCHDATE) => _$this._lAUNCHDATE = lAUNCHDATE;

  String _sITE;
  String get sITE => _$this._sITE;
  set sITE(String sITE) => _$this._sITE = sITE;

  String _dECAYDATE;
  String get dECAYDATE => _$this._dECAYDATE;
  set dECAYDATE(String dECAYDATE) => _$this._dECAYDATE = dECAYDATE;

  num _dECAYED;
  num get dECAYED => _$this._dECAYED;
  set dECAYED(num dECAYED) => _$this._dECAYED = dECAYED;

  num _fILE;
  num get fILE => _$this._fILE;
  set fILE(num fILE) => _$this._fILE = fILE;

  num _gPID;
  num get gPID => _$this._gPID;
  set gPID(num gPID) => _$this._gPID = gPID;

  String _tLELINE0;
  String get tLELINE0 => _$this._tLELINE0;
  set tLELINE0(String tLELINE0) => _$this._tLELINE0 = tLELINE0;

  String _tLELINE1;
  String get tLELINE1 => _$this._tLELINE1;
  set tLELINE1(String tLELINE1) => _$this._tLELINE1 = tLELINE1;

  String _tLELINE2;
  String get tLELINE2 => _$this._tLELINE2;
  set tLELINE2(String tLELINE2) => _$this._tLELINE2 = tLELINE2;

  SpaceTrackBuilder();

  SpaceTrackBuilder get _$this {
    if (_$v != null) {
      _cCSDSOMMVERS = _$v.cCSDSOMMVERS;
      _cOMMENT = _$v.cOMMENT;
      _cREATIONDATE = _$v.cREATIONDATE;
      _oRIGINATOR = _$v.oRIGINATOR;
      _oBJECTNAME = _$v.oBJECTNAME;
      _oBJECTID = _$v.oBJECTID;
      _cENTERNAME = _$v.cENTERNAME;
      _rEFFRAME = _$v.rEFFRAME;
      _tIMESYSTEM = _$v.tIMESYSTEM;
      _mEANELEMENTTHEORY = _$v.mEANELEMENTTHEORY;
      _ePOCH = _$v.ePOCH;
      _mEANMOTION = _$v.mEANMOTION;
      _eCCENTRICITY = _$v.eCCENTRICITY;
      _iNCLINATION = _$v.iNCLINATION;
      _rAOFASCNODE = _$v.rAOFASCNODE;
      _aRGOFPERICENTER = _$v.aRGOFPERICENTER;
      _mEANANOMALY = _$v.mEANANOMALY;
      _ePHEMERISTYPE = _$v.ePHEMERISTYPE;
      _cLASSIFICATIONTYPE = _$v.cLASSIFICATIONTYPE;
      _nORADCATID = _$v.nORADCATID;
      _eLEMENTSETNO = _$v.eLEMENTSETNO;
      _rEVATEPOCH = _$v.rEVATEPOCH;
      _bSTAR = _$v.bSTAR;
      _mEANMOTIONDOT = _$v.mEANMOTIONDOT;
      _mEANMOTIONDDOT = _$v.mEANMOTIONDDOT;
      _sEMIMAJORAXIS = _$v.sEMIMAJORAXIS;
      _pERIOD = _$v.pERIOD;
      _aPOAPSIS = _$v.aPOAPSIS;
      _pERIAPSIS = _$v.pERIAPSIS;
      _oBJECTTYPE = _$v.oBJECTTYPE;
      _rCSSIZE = _$v.rCSSIZE;
      _cOUNTRYCODE = _$v.cOUNTRYCODE;
      _lAUNCHDATE = _$v.lAUNCHDATE;
      _sITE = _$v.sITE;
      _dECAYDATE = _$v.dECAYDATE;
      _dECAYED = _$v.dECAYED;
      _fILE = _$v.fILE;
      _gPID = _$v.gPID;
      _tLELINE0 = _$v.tLELINE0;
      _tLELINE1 = _$v.tLELINE1;
      _tLELINE2 = _$v.tLELINE2;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SpaceTrack other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$SpaceTrack;
  }

  @override
  void update(void Function(SpaceTrackBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$SpaceTrack build() {
    final _$result = _$v ??
        new _$SpaceTrack._(
            cCSDSOMMVERS: cCSDSOMMVERS,
            cOMMENT: cOMMENT,
            cREATIONDATE: cREATIONDATE,
            oRIGINATOR: oRIGINATOR,
            oBJECTNAME: oBJECTNAME,
            oBJECTID: oBJECTID,
            cENTERNAME: cENTERNAME,
            rEFFRAME: rEFFRAME,
            tIMESYSTEM: tIMESYSTEM,
            mEANELEMENTTHEORY: mEANELEMENTTHEORY,
            ePOCH: ePOCH,
            mEANMOTION: mEANMOTION,
            eCCENTRICITY: eCCENTRICITY,
            iNCLINATION: iNCLINATION,
            rAOFASCNODE: rAOFASCNODE,
            aRGOFPERICENTER: aRGOFPERICENTER,
            mEANANOMALY: mEANANOMALY,
            ePHEMERISTYPE: ePHEMERISTYPE,
            cLASSIFICATIONTYPE: cLASSIFICATIONTYPE,
            nORADCATID: nORADCATID,
            eLEMENTSETNO: eLEMENTSETNO,
            rEVATEPOCH: rEVATEPOCH,
            bSTAR: bSTAR,
            mEANMOTIONDOT: mEANMOTIONDOT,
            mEANMOTIONDDOT: mEANMOTIONDDOT,
            sEMIMAJORAXIS: sEMIMAJORAXIS,
            pERIOD: pERIOD,
            aPOAPSIS: aPOAPSIS,
            pERIAPSIS: pERIAPSIS,
            oBJECTTYPE: oBJECTTYPE,
            rCSSIZE: rCSSIZE,
            cOUNTRYCODE: cOUNTRYCODE,
            lAUNCHDATE: lAUNCHDATE,
            sITE: sITE,
            dECAYDATE: dECAYDATE,
            dECAYED: dECAYED,
            fILE: fILE,
            gPID: gPID,
            tLELINE0: tLELINE0,
            tLELINE1: tLELINE1,
            tLELINE2: tLELINE2);
    replace(_$result);
    return _$result;
  }
}

class _$Record extends Record {
  @override
  final SpaceTrack spaceTrack;
  @override
  final String version;
  @override
  final String launch;
  @override
  final String id;

  factory _$Record([void Function(RecordBuilder) updates]) =>
      (new RecordBuilder()..update(updates)).build();

  _$Record._({this.spaceTrack, this.version, this.launch, this.id})
      : super._() {
    if (spaceTrack == null) {
      throw new BuiltValueNullFieldError('Record', 'spaceTrack');
    }
    if (version == null) {
      throw new BuiltValueNullFieldError('Record', 'version');
    }
    if (launch == null) {
      throw new BuiltValueNullFieldError('Record', 'launch');
    }
    if (id == null) {
      throw new BuiltValueNullFieldError('Record', 'id');
    }
  }

  @override
  Record rebuild(void Function(RecordBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RecordBuilder toBuilder() => new RecordBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Record &&
        spaceTrack == other.spaceTrack &&
        version == other.version &&
        launch == other.launch &&
        id == other.id;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, spaceTrack.hashCode), version.hashCode),
            launch.hashCode),
        id.hashCode));
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper('Record')
          ..add('spaceTrack', spaceTrack)
          ..add('version', version)
          ..add('launch', launch)
          ..add('id', id))
        .toString();
  }
}

class RecordBuilder implements Builder<Record, RecordBuilder> {
  _$Record _$v;

  SpaceTrackBuilder _spaceTrack;
  SpaceTrackBuilder get spaceTrack =>
      _$this._spaceTrack ??= new SpaceTrackBuilder();
  set spaceTrack(SpaceTrackBuilder spaceTrack) =>
      _$this._spaceTrack = spaceTrack;

  String _version;
  String get version => _$this._version;
  set version(String version) => _$this._version = version;

  String _launch;
  String get launch => _$this._launch;
  set launch(String launch) => _$this._launch = launch;

  String _id;
  String get id => _$this._id;
  set id(String id) => _$this._id = id;

  RecordBuilder();

  RecordBuilder get _$this {
    if (_$v != null) {
      _spaceTrack = _$v.spaceTrack?.toBuilder();
      _version = _$v.version;
      _launch = _$v.launch;
      _id = _$v.id;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Record other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Record;
  }

  @override
  void update(void Function(RecordBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Record build() {
    _$Record _$result;
    try {
      _$result = _$v ??
          new _$Record._(
              spaceTrack: spaceTrack.build(),
              version: version,
              launch: launch,
              id: id);
    } catch (_) {
      String _$failedField;
      try {
        _$failedField = 'spaceTrack';
        spaceTrack.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
            'Record', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
