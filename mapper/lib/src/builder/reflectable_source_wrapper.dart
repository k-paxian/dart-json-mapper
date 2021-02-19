import 'package:analyzer/dart/element/element.dart';

import 'change_analyzer.dart';
import 'library_visitor.dart';

class ReflectableSourceWrapper {
  final COLLECTION_IMPORT =
      '''import 'dart:collection' show HashSet, UnmodifiableListView;''';
  final MAPPER_IMPORT =
      '''import 'package:dart_json_mapper/dart_json_mapper.dart' show JsonMapper, JsonMapperAdapter, typeOf;''';
  final REFLECTABLE_INIT_METHOD = 'initializeReflectable';
  final REFLECTABLE_INIT_METHOD_PATCH = '_initializeReflectable';
  final INIT_METHOD =
      '''Future<JsonMapper> initializeJsonMapperAsync({Iterable<JsonMapperAdapter> adapters = const []}) => Future(() => initializeJsonMapper(adapters: adapters));

JsonMapper initializeJsonMapper({Iterable<JsonMapperAdapter> adapters = const []}) {''';

  LibraryVisitor _libraryVisitor;

  LibraryElement inputLibrary;
  Map<String, dynamic> options;
  String lastOutput;

  String _inputLibraryPath;
  String _inputLibraryPackageName;
  final _elementImportPrefix = <Element, String>{};
  final _importPrefix = <String, String>{};

  ReflectableSourceWrapper(this.inputLibrary, this.options) {
    _inputLibraryPackageName = getLibraryPackageName(inputLibrary);
    _libraryVisitor = LibraryVisitor(_inputLibraryPackageName);
    inputLibrary.visitChildren(_libraryVisitor);
    _inputLibraryPath = inputLibrary.identifier
        .substring(0, inputLibrary.identifier.lastIndexOf('/') + 1);
  }

  String getLibraryPackageName(LibraryElement library) =>
      'package:' +
      library.source.uri.toString().split(':').last.split('/').first;

  Iterable<String> get allowedIterables {
    return (options['iterables'] as String).split(',').map((x) => x.trim());
  }

  bool get isCollectionImportNeeded {
    return allowedIterables.contains('HashSet') ||
        allowedIterables.contains('UnmodifiableListView');
  }

  String get _libraryAdapterId {
    return '$_libraryName';
  }

  String get _libraryName {
    return inputLibrary.identifier
            .split('/')
            .last
            .replaceAll('.dart', '')
            .replaceAll('.', '_') +
        'Adapter';
  }

  String _getElementFullName(Element element) {
    final prefix = _elementImportPrefix[element];
    return '''$prefix.${element.name}''';
  }

  String _renderValueDecoratorsForClassElement(ClassElement element) {
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

  String _renderEnumValuesForClassElement(ClassElement element) {
    return '    ${_getElementFullName(element)}: ${_getElementFullName(element)}.values';
  }

  String _renderValueDecorators() {
    return _libraryVisitor.visitedPublicAnnotatedClassElements.values
        .map((e) => _renderValueDecoratorsForClassElement(e))
        .join(',\n');
  }

  String _renderEnumValues() {
    return _libraryVisitor.visitedPublicAnnotatedClassElements.values
        .where((element) => element.isEnum)
        .map((e) => _renderEnumValuesForClassElement(e))
        .join(',\n');
  }

  String _renderLibraryAdapterDefinition() {
    return ''' 
final $_libraryAdapterId = JsonMapperAdapter(
  title: '$_libraryName',
  url: '${inputLibrary.identifier}',
  valueDecorators: {
${_renderValueDecorators()}
},
  enumValues: {
${_renderEnumValues()}
});\n''';
  }

  String _renderLibraryAdapterRegistration(String input) {
    final hasReflectableOutput = input.indexOf(REFLECTABLE_INIT_METHOD) > 0;
    return '''
  ${hasReflectableOutput ? '$REFLECTABLE_INIT_METHOD_PATCH();' : ''}
  [...adapters, $_libraryAdapterId].forEach((x) => JsonMapper().useAdapter(x));
  return JsonMapper();
}''';
  }

  void _renderElementImport(
      ClassElement element, Map<String, List<String>> importsMap) {
    var importString;
    if (element.library != null &&
        element.library.identifier.startsWith(_inputLibraryPath)) {
      // local import
      importString = element.library.identifier.split(_inputLibraryPath).last;
    }
    if (element.library != null &&
        element.library.identifier.startsWith(_inputLibraryPackageName)) {
      // local package import
      importString = element.library.identifier;
    }
    final prefix = '''x${importsMap.length}''';
    final key = importString;
    if (importsMap.containsKey(key)) {
      importsMap[key].add(element.name);
      _elementImportPrefix.putIfAbsent(element, () => _importPrefix[key]);
    }
    importsMap.putIfAbsent(key, () => [element.name]);
    _elementImportPrefix.putIfAbsent(element, () => prefix);
    _importPrefix.putIfAbsent(key, () => prefix);
  }

  String _renderHeader() {
    return '''
// This file has been generated by the dart_json_mapper package.
// https://github.com/k-paxian/dart-json-mapper
''';
  }

  Map<String, List<String>> _buildImportsMap() {
    final _importsMap = <String, List<String>>{};
    _libraryVisitor.visitedPublicAnnotatedClassElements.values
        .forEach((e) => _renderElementImport(e, _importsMap));
    return _importsMap;
  }

  String _renderImports() {
    final importsMap = _buildImportsMap();
    final importsList = {
      isCollectionImportNeeded ? COLLECTION_IMPORT : null,
      MAPPER_IMPORT,
      ...importsMap.keys.map((key) =>
          '''import '${key}' as ${_importPrefix[key]} show ${importsMap[key].join(', ')};''')
    }.where((x) => x != null).toList();
    importsList.sort();
    return importsList.join('\n') + '\n\n';
  }

  String _removeObjectCasts(String input) {
    return input.replaceAll('<Object>', '');
  }

  String _patchInitMethod(String input) {
    final PATCH = '\n' +
        _renderLibraryAdapterDefinition() +
        '\n' +
        INIT_METHOD +
        '\n' +
        _renderLibraryAdapterRegistration(input);
    return input.replaceFirst(
            REFLECTABLE_INIT_METHOD, REFLECTABLE_INIT_METHOD_PATCH) +
        PATCH;
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

  String wrap(String reflectableGeneratedSource) {
    lastOutput = _renderHeader() +
        _renderImports() +
        _patchInitMethod(_removeObjectCasts(reflectableGeneratedSource));
    return lastOutput;
  }
}
