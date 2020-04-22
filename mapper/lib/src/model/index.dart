import 'annotations.dart';
import 'name_casing.dart';

export 'adapters.dart';
export 'annotations.dart';
export 'converters.dart';
export 'name_casing.dart';
export 'type_info.dart';
export 'value_decorators.dart';

/// Virtual class
/// Used as a generic reference to all Enum based types
/// enum ABC {A, B, C}, etc.
abstract class Enum {}

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

  /// Process only annotated class members
  final bool processAnnotatedMembersOnly;

  /// Template Instance
  /// - for Deserialization output it could be a typed Iterable<T>, or Map<K, V>, or else
  /// - for Serialization output it could be an instance of Map<String, dynamic>
  final dynamic template;

  const DeserializationOptions(
      {this.scheme,
      this.caseStyle,
      this.typeNameProperty,
      this.template,
      this.processAnnotatedMembersOnly});
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

class SerializationContext {
  final SerializationOptions options;
  final JsonProperty parentMeta;
  final int level;

  const SerializationContext(this.options, [this.level = 0, this.parentMeta]);
}

class DeserializationContext {
  final DeserializationOptions options;
  final Type instanceType;
  final JsonProperty parentMeta;

  const DeserializationContext(this.options, this.instanceType,
      [this.parentMeta]);
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
