import '../name_casing.dart';
import '../utils.dart';
import 'annotations.dart';
import 'type_info.dart';

export '../name_casing.dart';
export 'adapters.dart';
export 'annotations.dart';
export 'converters.dart';
export 'enum.dart';
export 'type_info.dart';
export 'value_decorators.dart';

enum ConversionDirection { fromJson, toJson }

typedef InjectableValues = Map<String, dynamic>;

const defaultDeserializationOptions = DeserializationOptions();

/// Declares configuration parameters for Deserialization process
class DeserializationOptions {
  /// The most popular ways to combine words into a single string
  /// Based on assumption: That all Dart class fields initially
  /// given as [CaseStyle.camel]
  final CaseStyle? caseStyle;

  /// Scheme to be used
  final dynamic scheme;

  /// Process annotated class members only
  final bool? processAnnotatedMembersOnly;

  /// Template Instance
  /// - for Deserialization output it could be a typed Iterable<T>, or Map<K, V>, or else
  /// - for Serialization output it could be an instance of Map<String, dynamic>
  final dynamic template;

  /// A Map<String, dynamic> of injectable values to be used for direct injection
  final InjectableValues? injectableValues;

  /// Declares a fallback target type to deserialize to, when it's not possible to detect
  /// it from target type inference OR [template]
  final Type? type;

  const DeserializationOptions(
      {this.scheme,
      this.caseStyle,
      this.template,
      this.injectableValues,
      this.type,
      this.processAnnotatedMembersOnly});
}

const defaultSerializationOptions = SerializationOptions(indent: ' ');

/// Declares configuration parameters for Serialization process
/// fully includes [DeserializationOptions]
class SerializationOptions extends DeserializationOptions {
  /// JSON Indentation, usually it's just a string of [space] characters
  final String? indent;

  /// Null class members
  /// will be excluded from serialization process
  final bool? ignoreNullMembers;

  /// Class members having [JsonProperty.defaultValue]
  /// will be excluded from serialization process
  final bool? ignoreDefaultMembers;

  /// Class members having Unknown types
  /// will be excluded from serialization process
  /// Java Jackson's "@JsonIgnoreProperties(ignoreUnknown = true)"
  final bool? ignoreUnknownTypes;

  const SerializationOptions(
      {scheme,
      caseStyle,
      template,
      processAnnotatedMembersOnly,
      this.indent,
      this.ignoreNullMembers,
      this.ignoreDefaultMembers,
      this.ignoreUnknownTypes})
      : super(
            scheme: scheme,
            template: template,
            caseStyle: caseStyle,
            processAnnotatedMembersOnly: processAnnotatedMembersOnly);
}

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

  CaseStyle get caseStyle =>
      (classMeta != null && classMeta!.caseStyle != null
          ? classMeta!.caseStyle
          : options.caseStyle) ??
      defaultCaseStyle;

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
  int get hashCode => '$options$jsonPropertyMeta$classMeta'.hashCode;

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

  const SerializationContext(SerializationOptions options,
      {this.level = 0,
      jsonPropertyMeta,
      classMeta,
      typeInfo,
      parentJsonMaps,
      parentObjectInstance})
      : super(options,
            jsonPropertyMeta: jsonPropertyMeta,
            classMeta: classMeta,
            typeInfo: typeInfo,
            parentJsonMaps: parentJsonMaps,
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

/// Describes resolved property name and value
class PropertyDescriptor {
  String name;
  dynamic value;
  bool raw; // value should be deserialized before use
  PropertyDescriptor(this.name, this.value, this.raw);
}

/// Describes an Object being processed through recursion to track cycling
/// use case. Used to prevent dead loops during recursive process
class ProcessedObjectDescriptor {
  dynamic object;
  Map<int, int> usages = {}; // level : usagesCounter

  ProcessedObjectDescriptor(this.object);

  int get levelsCount {
    return usages.keys.length;
  }

  void logUsage(int level) {
    if (usages.containsKey(level)) {
      usages.update(level, (value) => ++value);
    } else {
      usages[level] = 1;
    }
  }

  @override
  String toString() {
    return '$object / $usages';
  }
}
