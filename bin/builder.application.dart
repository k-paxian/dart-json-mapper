import 'package:barback/src/transformer/barback_settings.dart';
import 'package:build_barback/build_barback.dart';
import 'package:build_config/build_config.dart';
import 'package:build_runner/build_runner.dart';
import 'package:reflectable/transformer.dart';

BuilderApplication newBuilderApplication(List<String> arguments) {
  // TODO(eernst) feature: We should support some customization of
  // the settings, e.g., specifying options like `suppress_warnings`.
  BarbackSettings settings = new BarbackSettings(
    <String, Object>{"entry_points": arguments, "formatted": true},
    BarbackMode.DEBUG,
  );
  final builder = new TransformerBuilder(
    new ReflectableTransformer.asPlugin(settings),
    const <String, List<String>>{
      '.dart': const ['.reflectable.dart']
    },
  );
  return applyToRoot(builder, generateFor: new InputSet(include: arguments));
}
