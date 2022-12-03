import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' show posix;
import 'package:pubspec_parse/pubspec_parse.dart';

import '../identifier_casing.dart';
import 'change_analyzer.dart';
import 'library_visitor.dart';

class ReflectableSourceWrapper {
  static const reflectableInitMethodName = '_initializeReflectable';
  static const emptyReflectableOutput =
      '// No output from reflectable, \'package:reflectable/reflectable.dart\' not used.';
  final collectionImport =
      '''import 'dart:collection' show HashSet, UnmodifiableListView;''';
  final mapperImport =
      '''import 'package:dart_json_mapper/dart_json_mapper.dart' show JsonMapper, JsonMapperAdapter, SerializationOptions, DeserializationOptions, typeOf;''';
  final reflectableInitMethod = '''initializeReflectable() {
  r.data = _data;
  r.memberSymbolMap = _memberSymbolMap;
}''';
  final reflectableInitMethodPatch =
      '''$reflectableInitMethodName(JsonMapperAdapter adapter) {
  if (!adapter.isGenerated) {
    return;
  }
  r.data = adapter.reflectableData!;
  r.memberSymbolMap = adapter.memberSymbolMap;
}''';
  static const initSignature =
      '''{Iterable<JsonMapperAdapter> adapters = const [], SerializationOptions? serializationOptions, DeserializationOptions? deserializationOptions}''';
  static const initParams =
      '''adapters: adapters, serializationOptions: serializationOptions, deserializationOptions: deserializationOptions''';
  final initMethod =
      '''Future<JsonMapper> initializeJsonMapperAsync($initSignature) => Future(() => initializeJsonMapper($initParams));

JsonMapper initializeJsonMapper($initSignature) {''';

  LibraryVisitor? _libraryVisitor;

  LibraryElement inputLibrary;
  Map<String, dynamic> options;
  Pubspec mapperPubspec;
  Pubspec inputPubspec;
  String? lastOutput;

  late String _inputLibraryPath;
  String? _inputLibraryPackageName;
  final _elementImportPrefix = <Element, String?>{};
  final _importPrefix = <String?, String>{};

  ReflectableSourceWrapper(
      this.inputLibrary, this.options, this.mapperPubspec, this.inputPubspec) {
    _inputLibraryPackageName = getLibraryPackageName(inputLibrary);
    _libraryVisitor = LibraryVisitor(_inputLibraryPackageName);
    inputLibrary.visitChildren(_libraryVisitor!);
    _inputLibraryPath = inputLibrary.identifier
        .substring(0, inputLibrary.identifier.lastIndexOf('/') + 1);
  }

  String getLibraryPackageName(LibraryElement library) =>
      'package:${library.source.uri.toString().split(':').last.split('/').first}';

  Iterable<String> get allowedIterables {
    return (options['iterables'] as String).split(',').map((x) => x.trim());
  }

  bool get isCollectionImportNeeded {
    return allowedIterables.contains('HashSet') ||
        allowedIterables.contains('UnmodifiableListView');
  }

  String get _libraryAdapterId {
    return transformIdentifierCaseStyle(_libraryName, CaseStyle.camel, null);
  }

  String get _libraryName {
    return ('${inputLibrary.identifier.split('/').last.replaceAll('.dart', '').replaceAll('.', ' ').replaceAll('_', ' ')} generated adapter')
        .split(' ')
        .map((e) => capitalize(e))
        .join(' ')
        .trim();
  }

  String _getElementFullName(Element element) {
    final prefix = _elementImportPrefix[element];
    return '''$prefix.${element.name}''';
  }

  String _renderValueDecoratorsForClassElement(InterfaceElement element) {
    return [
      ...[
        'List',
        'Set'
      ].where((x) => allowedIterables.contains(x)).map((iterable) =>
          '''    typeOf<$iterable<${_getElementFullName(element)}>>(): (value) => value.cast<${_getElementFullName(element)}>()'''),
      ...[
        'HashSet'
      ].where((x) => allowedIterables.contains(x)).map((iterable) =>
          '''    typeOf<$iterable<${_getElementFullName(element)}>>(): (value) => $iterable<${_getElementFullName(element)}>.of(value.cast<${_getElementFullName(element)}>())'''),
      ...[
        'UnmodifiableListView'
      ].where((x) => allowedIterables.contains(x)).map((iterable) =>
          '''    typeOf<$iterable<${_getElementFullName(element)}>>(): (value) => $iterable<${_getElementFullName(element)}>(value.cast<${_getElementFullName(element)}>())''')
    ].join(',\n');
  }

  String _renderEnumValuesForClassElement(EnumElement element) {
    return '    ${_getElementFullName(element)}: ${_getElementFullName(element)}.values';
  }

  String _renderValueDecorators() {
    return _libraryVisitor!.visitedPublicAnnotatedElements
        .map((e) => _renderValueDecoratorsForClassElement(e))
        .join(',\n');
  }

  String _renderEnumValues() {
    return _libraryVisitor!.visitedPublicAnnotatedEnumElements.values
        .map((e) => _renderEnumValuesForClassElement(e))
        .join(',\n');
  }

  bool _hasReflectableOutput(String input) =>
      input.contains(reflectableInitMethod);

  String _renderLibraryAdapterDefinition(String input) {
    final hasReflectableOutput = _hasReflectableOutput(input);
    return '''
final $_libraryAdapterId = JsonMapperAdapter(
  title: '${inputPubspec.name}',
  url: '${inputLibrary.identifier}',${inputPubspec.homepage != null ? '\n  refUrl: \'${inputPubspec.homepage}\',' : ''}
  reflectableData: ${hasReflectableOutput ? '_data' : 'null'},
  memberSymbolMap: ${hasReflectableOutput ? '_memberSymbolMap' : 'null'},
  valueDecorators: {
${_renderValueDecorators()}
},
  enumValues: {
${_renderEnumValues()}
});\n''';
  }

  String _renderLibraryAdapterRegistration(String input) {
    final hasReflectableOutput = _hasReflectableOutput(input);
    return '''
  JsonMapper.globalSerializationOptions = serializationOptions ?? JsonMapper.globalSerializationOptions;
  JsonMapper.globalDeserializationOptions = deserializationOptions ?? JsonMapper.globalDeserializationOptions;    
  JsonMapper.enumerateAdapters([...adapters, $_libraryAdapterId], (JsonMapperAdapter adapter) {
    ${hasReflectableOutput ? '$reflectableInitMethodName(adapter);' : ''}
    JsonMapper().useAdapter(adapter);
  });
  return JsonMapper();
}''';
  }

  void _renderElementImport(
      InterfaceElement element, Map<String?, List<String>> importsMap) {
    final elementPath = element.library.identifier;
    String? importString;
    if (elementPath.startsWith(_inputLibraryPath)) {
      // local import
      importString = elementPath.split(_inputLibraryPath).last;
    } else if (elementPath.startsWith(_inputLibraryPackageName!)) {
      // local package import
      importString = elementPath;
    } else {
      // local relative path
      importString = posix.relative(elementPath, from: _inputLibraryPath);
    }
    final prefix = '''x${importsMap.length}''';
    final key = importString;
    if (importsMap.containsKey(key)) {
      importsMap[key]!.add(element.name);
      _elementImportPrefix.putIfAbsent(element, () => _importPrefix[key]);
    }
    importsMap.putIfAbsent(key, () => [element.name]);
    _elementImportPrefix.putIfAbsent(element, () => prefix);
    _importPrefix.putIfAbsent(key, () => prefix);
  }

  String _renderHeader() {
    return '''
// This file has been generated by the ${mapperPubspec.name} v${mapperPubspec.version}
// ${mapperPubspec.homepage}
// @dart = 2.12
''';
  }

  Map<String?, List<String>> _buildImportsMap() {
    final importsMap = <String?, List<String>>{};
    for (var element in _libraryVisitor!.visitedPublicAnnotatedElements) {
      _renderElementImport(element, importsMap);
    }
    return importsMap;
  }

  String _renderImports() {
    final importsMap = _buildImportsMap();
    final importsList = {
      isCollectionImportNeeded ? collectionImport : null,
      mapperImport,
      ...importsMap.keys.map((key) =>
          '''import '$key' as ${_importPrefix[key]} show ${importsMap[key]!.join(', ')};''')
    }.where((x) => x != null).toList();
    importsList.sort();
    return '${importsList.join('\n')}\n';
  }

  String _removeObjectCasts(String input) {
    return input.replaceAll('<Object>', '');
  }

  String _removeEmptyReflectableOutput(String input) {
    return input.replaceAll(emptyReflectableOutput, '');
  }

  String _removeLanguageOverrides(String input) {
    return input.replaceAll(RegExp(r'// @dart = \d\.\d+'), '');
  }

  String _patchInitMethod(String input) {
    final patch =
        '\n${_renderLibraryAdapterDefinition(input)}\n$initMethod\n${_renderLibraryAdapterRegistration(input)}';
    return input.replaceFirst(
            reflectableInitMethod, reflectableInitMethodPatch) +
        patch;
  }

  bool hasNoIncrementalChanges(LibraryElement library) {
    final incrementalLibraryVisitor = LibraryVisitor(_inputLibraryPackageName);
    library.visitChildren(incrementalLibraryVisitor);
    final hasChanges =
        ChangeAnalyzer(incrementalLibraryVisitor, _libraryVisitor).hasChanges;
    if (hasChanges) {
      _libraryVisitor = incrementalLibraryVisitor;
      inputLibrary = library;
    }
    return !hasChanges;
  }

  String? wrap(String reflectableGeneratedSource) {
    lastOutput = _renderHeader() +
        _renderImports() +
        _patchInitMethod(_removeLanguageOverrides(_removeEmptyReflectableOutput(
            _removeObjectCasts(reflectableGeneratedSource))));
    return lastOutput;
  }
}
