import '../utils.dart';
import 'annotations.dart';
import 'name_casing.dart';
import 'type_info.dart';

export 'adapters.dart';
export 'annotations.dart';
export 'converters.dart';
export 'enum.dart';
export 'name_casing.dart';
export 'type_info.dart';
export 'value_decorators.dart';

enum ConversionDirection { fromJson, toJson }

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

  /// Declares a fallback target type to deserialize to, when it's not possible to detect
  /// it from type inference OR [template]
  final Type? type;

  const DeserializationOptions(
      {this.scheme,
      this.caseStyle,
      this.template,
      this.type,
      this.processAnnotatedMembersOnly});

  @override
  String toString() => '$scheme$caseStyle'
      '$template'
      '$processAnnotatedMembersOnly';
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
      this.ignoreUnknownTypes})
      : super(
            scheme: scheme,
            template: template,
            caseStyle: caseStyle,
            processAnnotatedMembersOnly: processAnnotatedMembersOnly);
}

/// Describes a set of data / state to be re-used down the road of recursive
/// process of Deserialization/Serialization
class DeserializationContext {
  final DeserializationOptions options;
  final JsonProperty? jsonPropertyMeta;
  final Json? classMeta;
  final TypeInfo? typeInfo;
  final Iterable<JsonMap>? parentJsonMaps;

  const DeserializationContext(this.options,
      {this.jsonPropertyMeta,
      this.classMeta,
      this.typeInfo,
      this.parentJsonMaps});

  ConversionDirection get direction => ConversionDirection.fromJson;

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
      {this.level = 0, jsonPropertyMeta, classMeta, typeInfo})
      : super(options,
            jsonPropertyMeta: jsonPropertyMeta,
            classMeta: classMeta,
            typeInfo: typeInfo);

  SerializationOptions get serializationOptions =>
      options as SerializationOptions;

  @override
  ConversionDirection get direction => ConversionDirection.toJson;
}

/// Describes resolved property name and value
class PropertyDescriptor {
  String? name;
  dynamic value;
  PropertyDescriptor(this.name, this.value);
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
