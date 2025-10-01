import 'package:collection/collection.dart';

import '../../identifier_casing.dart';
import '../../globals.dart';
import '../../json_map.dart';
import '../annotations.dart';
import '../type_info.dart';
import 'options.dart';
import 'conversion_direction.dart';

/// Describes a set of data / state to be re-used down the road of recursive
/// process of Deserialization / Serialization
class DeserializationContext {
  final DeserializationOptions options;
  final JsonProperty? jsonPropertyMeta;
  final Json? classMeta;
  final TypeInfo? typeInfo;
  final Iterable<JsonMap>? parentJsonMaps;
  final Iterable<Object>? parentObjectInstances;

  const DeserializationContext(this.options,
      {this.jsonPropertyMeta,
      this.parentObjectInstances,
      this.classMeta,
      this.typeInfo,
      this.parentJsonMaps});

  CaseStyle? getParentCaseStyle() {
    if (parentJsonMaps != null && parentJsonMaps!.isNotEmpty) {
      final parentJsonMap = parentJsonMaps!
          .firstWhereOrNull((element) => element.jsonMeta != null);
      return parentJsonMap != null && parentJsonMap.jsonMeta != null
          ? parentJsonMap.jsonMeta!.caseStyle
          : null;
    }
    return null;
  }

  CaseStyle? get caseStyle => (classMeta != null && classMeta!.caseStyle != null
      ? classMeta!.caseStyle
      : getParentCaseStyle() ?? options.caseStyle ?? defaultCaseStyle);

  CaseStyle? get targetCaseStyle =>
      direction == ConversionDirection.fromJson ? defaultCaseStyle : caseStyle;

  CaseStyle? get sourceCaseStyle =>
      direction == ConversionDirection.fromJson ? caseStyle : defaultCaseStyle;

  String transformIdentifier(String name) => direction ==
          ConversionDirection.fromJson
      ? transformIdentifierCaseStyle(name, sourceCaseStyle, targetCaseStyle)
      : transformIdentifierCaseStyle(name, targetCaseStyle, sourceCaseStyle);

  ConversionDirection get direction => ConversionDirection.fromJson;

  DeserializationContext reBuild(
          {JsonProperty? jsonPropertyMeta,
          Json? classMeta,
          TypeInfo? typeInfo,
          Iterable<JsonMap>? parentJsonMaps,
          Iterable<Object>? parentObjectInstances}) =>
      DeserializationContext(options,
          jsonPropertyMeta: jsonPropertyMeta ?? this.jsonPropertyMeta,
          classMeta: classMeta ?? this.classMeta,
          typeInfo: typeInfo ?? this.typeInfo,
          parentJsonMaps: parentJsonMaps ?? this.parentJsonMaps,
          parentObjectInstances:
              parentObjectInstances ?? this.parentObjectInstances);

  @override
  int get hashCode =>
      options.hashCode ^ jsonPropertyMeta.hashCode ^ classMeta.hashCode;

  @override
  bool operator ==(Object other) {
    final otherContext = (other as DeserializationContext);

    return otherContext.options == options &&
        otherContext.jsonPropertyMeta == jsonPropertyMeta &&
        otherContext.typeInfo == typeInfo &&
        otherContext.classMeta == classMeta;
  }
}

/// Describes a set of data / state to be re-used down the road of recursive
/// process of Serialization
class SerializationContext extends DeserializationContext {
  /// Recursion nesting level, 0 = top object, 1 = object's property, and so on
  final int level;

  const SerializationContext(SerializationOptions super.options,
      {this.level = 0,
      super.jsonPropertyMeta,
      super.classMeta,
      super.typeInfo,
      super.parentJsonMaps,
      parentObjectInstance})
      : super(
            parentObjectInstances: parentObjectInstance);

  SerializationOptions get serializationOptions =>
      options as SerializationOptions;

  @override
  DeserializationContext reBuild(
          {int? level,
          JsonProperty? jsonPropertyMeta,
          Json? classMeta,
          TypeInfo? typeInfo,
          Iterable<JsonMap>? parentJsonMaps,
          Iterable<Object>? parentObjectInstances}) =>
      SerializationContext(serializationOptions,
          level: level ?? this.level,
          jsonPropertyMeta: jsonPropertyMeta ?? this.jsonPropertyMeta,
          classMeta: classMeta ?? this.classMeta,
          typeInfo: typeInfo ?? this.typeInfo,
          parentJsonMaps: parentJsonMaps ?? this.parentJsonMaps,
          parentObjectInstance:
              parentObjectInstances ?? this.parentObjectInstances);

  @override
  ConversionDirection get direction => ConversionDirection.toJson;
}