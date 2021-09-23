import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' show posix;

import 'change_analyzer.dart';
import 'library_visitor.dart';

class ReflectableSourceWrapper {
  static const reflectableInitMethodName = '_initializeReflectable';
  final collectionImport =
      '''import 'dart:collection' show HashSet, UnmodifiableListView;''';
  final mapperImport =
      '''import 'package:dart_json_mapper/dart_json_mapper.dart' show JsonMapper, JsonMapperAdapter, typeOf;''';
  final reflectableInitMethod = '''initializeReflectable() {
  r.data = _data;
  r.memberSymbolMap = _memberSymbolMap;
}''';
  final reflectableInitMethodPatch =
      '''$reflectableInitMethodName(JsonMapperAdapter adapter) {
  if (adapter.reflectableData == null) {
    return;
  }
  r.data = adapter.reflectableData!;
  r.memberSymbolMap = adapter.memberSymbolMap;
}''';
  final initMethod =
      '''Future<JsonMapper> initializeJsonMapperAsync({Iterable<JsonMapperAdapter> adapters = const []}) => Future(() => initializeJsonMapper(adapters: adapters));

JsonMapper initializeJsonMapper({Iterable<JsonMapperAdapter> adapters = const []}) {''';

  LibraryVisitor? _libraryVisitor;

  LibraryElement inputLibrary;
  Map<String, dynamic> options;
  String? lastOutput;

  late String _inputLibraryPath;
  String? _inputLibraryPackageName;
  final _elementImportPrefix = <Element, String?>{};
  final _importPrefix = <String?, String>{};

  ReflectableSourceWrapper(this.inputLibrary, this.options) {
    _inputLibraryPackageName = getLibraryPackageName(inputLibrary);
    _libraryVisitor = LibraryVisitor(_inputLibraryPackageName);
    inputLibrary.visitChildren(_libraryVisitor!);
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
    return _libraryName.replaceFirst('_', '');
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
    return _libraryVisitor!.visitedPublicAnnotatedClassElements.values
        .map((e) => _renderValueDecoratorsForClassElement(e))
        .join(',\n');
  }

  String _renderEnumValues() {
    return _libraryVisitor!.visitedPublicAnnotatedClassElements.values
        .where((element) => element.isEnum)
        .map((e) => _renderEnumValuesForClassElement(e))
        .join(',\n');
  }

  String _renderLibraryAdapterDefinition() {
    return ''' 
final $_libraryAdapterId = JsonMapperAdapter(
  title: '$_libraryName',
  url: '${inputLibrary.identifier}',
  reflectableData: _data,
  memberSymbolMap: _memberSymbolMap,
  valueDecorators: {
${_renderValueDecorators()}
},
  enumValues: {
${_renderEnumValues()}
});\n''';
  }

  String _renderLibraryAdapterRegistration(String input) {
    final hasReflectableOutput = input.indexOf(reflectableInitMethod) > 0;
    return '''
  final allAdapters = [...adapters, $_libraryAdapterId];
  final reflectableAdapters =
      allAdapters.where((adapter) => adapter.reflectableData != null);
  final otherAdapters =
      allAdapters.where((adapter) => adapter.reflectableData == null);  
  for (var adapter in [...reflectableAdapters, ...otherAdapters]) {
    ${hasReflectableOutput ? '$reflectableInitMethodName(adapter);' : ''}
    JsonMapper().useAdapter(adapter);
  }
  return JsonMapper();
}''';
  }

  void _renderElementImport(
      ClassElement element, Map<String?, List<String>> importsMap) {
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
// This file has been generated by the dart_json_mapper package.
// https://github.com/k-paxian/dart-json-mapper
''';
  }

  Map<String?, List<String>> _buildImportsMap() {
    final _importsMap = <String?, List<String>>{};
    for (var element
        in _libraryVisitor!.visitedPublicAnnotatedClassElements.values) {
      _renderElementImport(element, _importsMap);
    }
    return _importsMap;
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
    return importsList.join('\n') + '\n';
  }

  String _removeObjectCasts(String input) {
    return input.replaceAll('<Object>', '');
  }

  String _patchInitMethod(String input) {
    final patch = '\n' +
        _renderLibraryAdapterDefinition() +
        '\n' +
        initMethod +
        '\n' +
        _renderLibraryAdapterRegistration(input);
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
        _patchInitMethod(_removeObjectCasts(reflectableGeneratedSource));
    return lastOutput;
  }
}
