import 'dart:async';
import 'dart:io';
import 'package:build/build.dart';
import 'package:path/path.dart' as path;

/// Builder that generates a single main.reflectable.helper.dart file
/// containing JsonMapper configuration for all @jsonSerializable annotated classes and enums
class ReflectableHelperGenerator implements Builder {
  final BuilderOptions options;

  ReflectableHelperGenerator(this.options);

  @override
  final Map<String, List<String>> buildExtensions = {
    r'$lib$': ['main.reflectable.helper.dart']
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    // Get the package name from the input
    final packageName = buildStep.inputId.package;
    
    // Find all dart files in lib directory
    final libDir = Directory('lib');
    if (!libDir.existsSync()) {
      log.warning('lib directory not found');
      return;
    }

    final imports = <String>{};
    final modelClasses = <String>{};
    final enumClasses = <String>{};

    // Recursively scan lib directory
    await _scanDirectory(libDir, imports, modelClasses, enumClasses);

    // Generate the helper file content
    final helperContent = _generateHelperFile(imports, modelClasses, enumClasses);

    // Write the output file
    final outputId = AssetId(packageName, 'lib/main.reflectable.helper.dart');
    await buildStep.writeAsString(outputId, helperContent);
  }

  Future<void> _scanDirectory(
    Directory dir,
    Set<String> imports,
    Set<String> modelClasses,
    Set<String> enumClasses,
  ) async {
    final entries = dir.listSync(recursive: true);

    for (final entity in entries) {
      if (entity is File && entity.path.endsWith('.dart')) {
        // Skip generated files
        if (entity.path.endsWith('.g.dart') || 
            entity.path.endsWith('.mapper.g.dart') ||
            entity.path.contains('main.reflectable.helper.dart')) {
          continue;
        }

        final content = await entity.readAsString();

        // Find @jsonSerializable annotated classes
        // Pattern: @jsonSerializable followed by class declaration
        final classPattern = RegExp(
          r'@jsonSerializable\s+(?:abstract\s+)?class\s+(\w+)(?:<[^>]+>)?',
          multiLine: true,
        );
        final classMatches = classPattern.allMatches(content);

        // Find @jsonSerializable annotated enums
        final enumPattern = RegExp(
          r'@jsonSerializable\s+enum\s+(\w+)',
          multiLine: true,
        );
        final enumMatches = enumPattern.allMatches(content);

        if (classMatches.isNotEmpty || enumMatches.isNotEmpty) {
          // Calculate relative import path from lib/main.dart perspective
          final relativePath = path.relative(entity.path, from: 'lib');
          imports.add(relativePath);

          // Add class names
          for (final match in classMatches) {
            final className = match.group(1);
            if (className != null) {
              modelClasses.add(className);
            }
          }

          // Add enum names
          for (final match in enumMatches) {
            final enumName = match.group(1);
            if (enumName != null) {
              enumClasses.add(enumName);
            }
          }
        }
      }
    }
  }

  String _generateHelperFile(
    Set<String> imports,
    Set<String> modelClasses,
    Set<String> enumClasses,
  ) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('// AUTO-GENERATED FILE. DO NOT MODIFY.');
    buffer.writeln('// This file contains imports and JsonMapper configuration for all JSON-annotated classes');
    buffer.writeln();

    // Imports
    buffer.writeln("import 'main.reflectable.dart';");
    final sortedImports = imports.toList()..sort();
    for (final import in sortedImports) {
      buffer.writeln("import '$import';");
    }
    buffer.writeln("import 'package:dart_json_mapper/dart_json_mapper.dart';");
    buffer.writeln();

    // Configuration function
    buffer.writeln('void configureJsonMapper() {');
    buffer.writeln('  initializeReflectable();');
    buffer.writeln('  JsonMapper().useAdapter(JsonMapperAdapter(');

    // Value decorators
    if (modelClasses.isNotEmpty) {
      buffer.writeln('    valueDecorators: {');
      final sortedClasses = modelClasses.toList()..sort();
      for (final className in sortedClasses) {
        buffer.writeln(
          '      typeOf<List<$className>>(): (value) => value.cast<$className>(),',
        );
      }
      buffer.writeln('    },');
    }

    // Enum values
    if (enumClasses.isNotEmpty) {
      buffer.writeln('    enumValues: {');
      final sortedEnums = enumClasses.toList()..sort();
      for (final enumName in sortedEnums) {
        buffer.writeln('      $enumName: EnumDescriptor(');
        buffer.writeln('        values: $enumName.values,');
        buffer.writeln('        mapping: {...Map.fromEntries(');
        buffer.writeln('          List.generate($enumName.values.length,');
        buffer.writeln(
          '            (index) => MapEntry($enumName.values[index], $enumName.values[index].id)',
        );
        buffer.writeln('          )');
        buffer.writeln('        )},');
        buffer.writeln('      ),');
      }
      buffer.writeln('    },');
    }

    buffer.writeln('  ));');
    buffer.writeln('}');

    return buffer.toString();
  }
}

