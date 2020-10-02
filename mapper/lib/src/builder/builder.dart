import 'package:build/build.dart';
import 'package:reflectable/src/builder_implementation.dart';

import 'index.dart';

class DartJsonMapperBuilder implements Builder {
  BuilderOptions builderOptions;

  DartJsonMapperBuilder(this.builderOptions);

  String get _extension =>
      builderOptions.config['extension'] ?? '.mapper.g.dart';

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputLibrary = await buildStep.inputLibrary;
    final resolver = buildStep.resolver;
    final inputId = buildStep.inputId;
    final outputId = inputId.changeExtension(_extension);
    final visibleLibraries = await resolver.libraries.toList();
    final builderImplementation = BuilderImplementation();
    final generatedSource = await builderImplementation.buildMirrorLibrary(
        resolver, inputId, outputId, inputLibrary, visibleLibraries, true, []);
    final wrappedSource =
        ReflectableSourceWrapper(inputLibrary, builderOptions.config)
            .wrap(generatedSource);
    await buildStep.writeAsString(outputId, wrappedSource);
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': [_extension]
      };
}

DartJsonMapperBuilder dartJsonMapperBuilder(BuilderOptions options) {
  final config = Map<String, Object>.from(options.config);
  config.putIfAbsent('entry_points', () => ['**.dart']);
  return DartJsonMapperBuilder(options);
}
