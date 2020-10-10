import 'package:build/build.dart';

import './src/builder/index.dart';

DartJsonMapperBuilder dartJsonMapperBuilder(BuilderOptions options) {
  final config = Map<String, Object>.from(options.config);
  config.putIfAbsent('entry_points', () => ['**.dart']);
  return DartJsonMapperBuilder(options);
}
