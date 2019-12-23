[![pub package](https://img.shields.io/pub/v/dart_json_mapper_fixnum.svg)](https://pub.dartlang.org/packages/dart_json_mapper_fixnum)

This is a [dart-json-mapper][1] complementary package provides support for https://pub.dev/packages/fixnum types in order to serialize / deserialize them from / to JSON.
 
## Basic setup

Beforehand please consult with basic setup section from [dart-json-mapper][1] package. 

Please add the following dependencies to your `pubspec.yaml`:

```
dependencies:
  dart_json_mapper: any
  dart_json_mapper_fixnum: any
dev_dependencies:
  build_runner: any
```

Usage example
**lib/main.dart**
```dart
import 'package:dart_json_mapper/annotations.dart';
import 'package:dart_json_mapper/json_mapper.dart';
import 'package:fixnum/fixnum.dart' show Int32;
import 'package:dart_json_mapper_fixnum/dart_json_mapper_fixnum.dart';

import 'main.reflectable.dart'; // Import generated code.

@jsonSerializable
class FixnumClass {
  Int32 integer32;

  FixnumClass(this.integer32);
}

main() {
  initializeReflectable(); // Imported from main.reflectable.dart
  initializeJsonMapperForFixnum(); // Imported from dart_json_mapper_fixnum
  
  print(JsonMapper.serialize(
     FixnumClass(Int32(1234567890))
  ));
}
```
output:
```json
{
  "integer32": "1234567890"
}
```

[1]: https://github.com/k-paxian/dart-json-mapper