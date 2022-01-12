import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
// ignore: implementation_imports
import 'package:reflectable/src/builder_implementation.dart'
    show BuilderImplementation;

import 'reflectable_source_wrapper.dart';

class DartJsonMapperBuilder implements Builder {
  BuilderOptions builderOptions;
  Map<String, ReflectableSourceWrapper?> wrappersMap = {};

  DartJsonMapperBuilder(this.builderOptions);

  String get _extension =>
      builderOptions.config['extension'] ?? '.mapper.g.dart';

  bool get _formatted => builderOptions.config['formatted'] ?? false;

  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': [_extension]
      };

  ReflectableSourceWrapper getWrapperForLibrary(LibraryElement inputLibrary,
      Pubspec mapperPubspec, Pubspec inputPubspec) {
    var result = wrappersMap[inputLibrary.identifier];
    if (result == null) {
      result = ReflectableSourceWrapper(
          inputLibrary, builderOptions.config, mapperPubspec, inputPubspec);
      wrappersMap.putIfAbsent(inputLibrary.identifier, () => result);
    }
    return result;
  }

  Future<Pubspec> getPubspec(String package, BuildStep buildStep) async {
    final assetId = AssetId(package, 'pubspec.yaml');
    final content = await buildStep.readAsString(assetId);
    return Pubspec.parse(content, sourceUrl: assetId.uri);
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    final outputId = inputId.changeExtension(_extension);
    final inputLibrary = await buildStep.inputLibrary;
    final incrementalBuild = wrappersMap[inputLibrary.identifier] != null;
    final wrapper = getWrapperForLibrary(
        inputLibrary,
        await getPubspec('dart_json_mapper', buildStep),
        await getPubspec(buildStep.inputId.package, buildStep));
    if (incrementalBuild && wrapper.hasNoIncrementalChanges(inputLibrary)) {
      await buildStep.writeAsString(outputId, wrapper.lastOutput!);
      return;
    }
    final resolver = buildStep.resolver;
    final visibleLibraries = await resolver.libraries.toList();
    final builderImplementation = BuilderImplementation();
    final generatedSource = await builderImplementation.buildMirrorLibrary(
        resolver,
        inputId,
        outputId,
        inputLibrary,
        visibleLibraries,
        _formatted, []);
    final wrappedSource = wrapper.wrap(generatedSource)!;
    await buildStep.writeAsString(outputId, wrappedSource);
  }
}
