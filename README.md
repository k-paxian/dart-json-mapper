# dart-json-mapper

[![pub package](https://img.shields.io/pub/v/dart_json_mapper.svg)](https://pub.dartlang.org/packages/dart_json_mapper)

Serialize / Deserialize Dart Objects to / from JSON

This package allows programmers to annotate Dart classes in order to
  serialize / deserialize them from / to JSON string in one line of code.
  
## Basic setup

Library has **NO** dependency on `dart:mirrors`, one of the reasons is described [here][1].

Dart classes reflection mechanism is based on [reflectable][3] library. This means "extended types information" is auto-generated out of existing Dart program guided by the annotated classes only, as the result types information is accesible at runtime, at a reduced cost.

Say, you have a dart program *main.dart* having some classes intended to be traveling to JSON and back.
- First thing you should do is to put @jsonSerializable annotation on each of those classes
- Next step is to auto generate *main.reflectable.dart* file. And afterwards import that file into *main.dart*

**lib/main.dart**
```dart
import 'package:dart_json_mapper/annotations.dart';
import 'package:dart_json_mapper/json_mapper.dart';

import 'main.reflectable.dart'; // Import generated code.

@jsonSerializable // This annotation let instances of MyData traveling to/from JSON
class MyData {
  int a = 123;
  MyData([this.a]); // Important! Constructor must not have any required parameters.
}

main() {
  initializeReflectable(); // Imported from main.reflectable.dart
  
  print(JsonMapper.serialize(new MyData(456)));
  // { 
  //  "a": 456
  // }
}
```

Now run the code generation step with the root of your package as the current
directory:

```shell
> pub run dart_json_mapper:build lib/main.dart
```

where `lib/main.dart` should be replaced by the root library of the
program for which you wish to generate code. You can generate code for
several programs in one step; for instance, to generate code for a set of
test files in `test`, this would typically be
`pub run dart_json_mapper:build test/*_test.dart`.
**You'll need to re-run code generation each time you are making changes to `lib/main.dart`**
So for development time, use `watch` like this

```shell
> pub run dart_json_mapper:watch lib/main.dart
```

Each time you modify your project code, all *.reflectable.dart files will be updated as well.
- Next step is to add "*.reflectable.dart" to your .gitignore
- This is it, basic setup is done.


## Feature requests and bug reports

Please file feature requests and bugs using the
[github issue tracker for this repository][2].



[1]: https://github.com/flutter/flutter/issues/1150
[2]: https://github.com/k-paxian/dart-json-mapper/issues
[3]: https://pub.dartlang.org/packages/reflectable
