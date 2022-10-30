part of perf_test.test;

@MappableClass(
    caseStyle: CaseStyle(
        head: TextTransform.upperCase,
        tail: TextTransform.upperCase,
        separator: '_'))
class SpaceTrack with SpaceTrackMappable {
  final String ccsdsOmmVers;
  final String comment;
  final String originator;
  final String objectName;
  final String objectId;
  final String objectType;
  final String centerName;
  final String refFrame;
  final String timeSystem;
  final String meanElementTheory;
  final String classificationType;
  final String rcsSize;
  final String countryCode;
  final String site;
  final String tleLine0;
  final String tleLine1;
  final String tleLine2;
  final num meanMotion;
  final num eccentricity;
  final num raOfAscNode;
  final num argOfPericenter;
  final num meanAnomaly;
  final num ephemerisType;
  final num noradCatId;
  final num elementSetNo;
  final num revAtEpoch;
  final num bstar;
  final num meanMotionDot;
  final num meanMotionDdot;
  final num semimajorAxis;
  final num period;
  final num apoapsis;
  final num periapsis;
  final num decayed;
  final num file;
  final num gpId;
  final DateTime? decayDate;
  final DateTime creationDate;
  final DateTime epoch;
  final DateTime launchDate;

  SpaceTrack(
      this.comment,
      this.decayDate,
      this.centerName,
      this.argOfPericenter,
      this.apoapsis,
      this.bstar,
      this.ccsdsOmmVers,
      this.classificationType,
      this.creationDate,
      this.countryCode,
      this.decayed,
      this.eccentricity,
      this.elementSetNo,
      this.ephemerisType,
      this.epoch,
      this.file,
      this.gpId,
      this.launchDate,
      this.meanAnomaly,
      this.meanElementTheory,
      this.meanMotion,
      this.meanMotionDdot,
      this.meanMotionDot,
      this.noradCatId,
      this.objectId,
      this.objectName,
      this.objectType,
      this.originator,
      this.periapsis,
      this.period,
      this.raOfAscNode,
      this.rcsSize,
      this.refFrame,
      this.revAtEpoch,
      this.semimajorAxis,
      this.site,
      this.timeSystem,
      this.tleLine0,
      this.tleLine1,
      this.tleLine2);
}

@MappableClass()
class Record with RecordMappable {
  final SpaceTrack spaceTrack;
  final String version;
  final String id;
  final String launch;

  Record(this.id, this.version, this.launch, this.spaceTrack);
}
