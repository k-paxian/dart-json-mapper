import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner/build_runner.dart';
import 'package:reflectable/src/builder_implementation.dart';

class ReflectableBuilder implements Builder {
  BuilderOptions builderOptions;

  ReflectableBuilder(this.builderOptions);

  @override
  Future build(BuildStep buildStep) async {
    var resolver = buildStep.resolver;
    var inputId = buildStep.inputId;
    var outputId = inputId.changeExtension('.reflectable.dart');
    var inputLibrary = await buildStep.inputLibrary;
    List<LibraryElement> visibleLibraries = await resolver.libraries.toList();

    await buildStep.writeAsString(
        outputId,
        new BuilderImplementation().buildMirrorLibrary(resolver, inputId,
            outputId, inputLibrary, visibleLibraries, true, []));
  }

  Map<String, List<String>> get buildExtensions => const {
        '.dart': ['.reflectable.dart']
      };
}

BuilderApplication newBuilderApplication(List<String> arguments) {
  // TODO(eernst) feature: We should support some customization of
  // the settings, e.g., specifying options like `suppress_warnings`.
  BuilderOptions options = new BuilderOptions(
      <String, dynamic>{"entry_points": arguments, "formatted": true},
      isRoot: true);
  final builder = new ReflectableBuilder(options);

  return applyToRoot(builder, generateFor: new InputSet(include: arguments));
}
