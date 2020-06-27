part of perf_test.test;

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
