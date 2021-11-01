import 'package:dart_json_mapper/dart_json_mapper.dart'
    show jsonSerializable, Json, CaseStyle, JsonProperty;

@jsonSerializable
@Json(caseStyle: CaseStyle.snakeAllCaps)
class SpaceTrack {
  String? ccsdsOmmVers,
      comment,
      originator,
      objectName,
      objectId,
      objectType,
      centerName,
      refFrame,
      timeSystem,
      meanElementTheory,
      classificationType,
      rcsSize,
      countryCode,
      site,
      tleLine0,
      tleLine1,
      tleLine2;

  num? meanMotion,
      eccentricity,
      raOfAscNode,
      argOfPericenter,
      meanAnomaly,
      ephemerisType,
      noradCatId,
      elementSetNo,
      revAtEpoch,
      bstar,
      meanMotionDot,
      meanMotionDdot,
      semimajorAxis,
      period,
      apoapsis,
      periapsis,
      decayed,
      file,
      gpId;

  DateTime? decayDate, creationDate, epoch;

  @JsonProperty(converterParams: {'format': 'yyyy-MM-dd'})
  DateTime? launchDate;
}

@jsonSerializable
class Record {
  SpaceTrack? spaceTrack;
  String? version, id, launch;
}
