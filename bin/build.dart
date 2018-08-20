import 'dart:async';

import 'package:build_runner/build_runner.dart';

import 'builder.application.dart';

Future<BuildResult> reflectableBuild(List<String> arguments) async {
  if (arguments.length < 1) {
    // Globbing may produce an empty argument list, and it might be ok,
    // but we should give at least notify the caller.
    print("reflectable_builder: No arguments given, exiting.");
    return BuildResult(BuildStatus.success, []);
  } else {
    return await build([newBuilderApplication(arguments)],
        deleteFilesByDefault: true);
  }
}

main(List<String> arguments) async {
  await reflectableBuild(arguments);
}
