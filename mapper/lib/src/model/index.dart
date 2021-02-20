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

class DeserializationOptions {
  /// The most popular ways to combine words into a single string
  /// Based on assumption: That all Dart class fields initially
  /// given as CaseStyle.Camel
  final CaseStyle caseStyle;

  /// Scheme to be used
  final dynamic scheme;

  /// Declares necessity for all annotated classes and all their subclasses
  /// to dump their own type name to the custom named json property.
  final String typeNameProperty;

  /// Process annotated class members only
  final bool processAnnotatedMembersOnly;

  /// Template Instance
  /// - for Deserialization output it could be a typed Iterable<T>, or Map<K, V>, or else
  /// - for Serialization output it could be an instance of Map<String, dynamic>
  final dynamic template;

  /// Declares the type to deserialize to
  final Type type;

  const DeserializationOptions(
      {this.scheme,
      this.caseStyle,
      this.typeNameProperty,
      this.template,
      this.type,
      this.processAnnotatedMembersOnly});

  @override
  String toString() => '$scheme$caseStyle'
      '$typeNameProperty$template'
      '$processAnnotatedMembersOnly';
}

const defaultSerializationOptions = SerializationOptions(indent: ' ');

class SerializationOptions extends DeserializationOptions {
  /// Indentation
  final String indent;

  /// Null class members
  /// will be excluded from serialization process
  final bool ignoreNullMembers;

  /// Class members having Unknown types
  /// will be excluded from serialization process
  /// Java Jackson's "@JsonIgnoreProperties(ignoreUnknown = true)"
  final bool ignoreUnknownTypes;

  const SerializationOptions(
      {scheme,
      caseStyle,
      typeNameProperty,
      template,
      processAnnotatedMembersOnly,
      this.indent,
      this.ignoreNullMembers,
      this.ignoreUnknownTypes})
      : super(
            scheme: scheme,
            template: template,
            caseStyle: caseStyle,
            typeNameProperty: typeNameProperty,
            processAnnotatedMembersOnly: processAnnotatedMembersOnly);
}

class DeserializationContext {
  final DeserializationOptions options;
  final JsonProperty jsonPropertyMeta;
  final Json classMeta;
  final TypeInfo typeInfo;
  final Iterable<JsonMap> parentJsonMaps;

  const DeserializationContext(
      {this.options,
      this.jsonPropertyMeta,
      this.classMeta,
      this.typeInfo,
      this.parentJsonMaps});

  @override
  int get hashCode => '$options$jsonPropertyMeta$classMeta'.hashCode;

  @override
  bool operator ==(Object other) {
    final otherContext = (other as DeserializationContext);

    return otherContext.options == options &&
        otherContext.jsonPropertyMeta == jsonPropertyMeta &&
        otherContext.classMeta == classMeta;
  }
}

class SerializationContext extends DeserializationContext {
  final int level;

  const SerializationContext(
      {this.level = 0,
      SerializationOptions options,
      jsonPropertyMeta,
      classMeta,
      typeInfo})
      : super(
            options: options,
            jsonPropertyMeta: jsonPropertyMeta,
            classMeta: classMeta,
            typeInfo: typeInfo);

  SerializationOptions get serializationOptions => options;
}

class ProcessedObjectDescriptor {
  dynamic object;
  Map<int, int> usages = {}; // level : usagesCounter

  ProcessedObjectDescriptor(this.object);

  int get levelsCount {
    return usages.keys.length;
  }

  void logUsage(int level) {
    if (usages.containsKey(level)) {
      usages[level]++;
    } else {
      usages[level] = 1;
    }
  }

  @override
  String toString() {
    return '$object / $usages';
  }
}
