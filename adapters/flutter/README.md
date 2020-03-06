[![pub package](https://img.shields.io/pub/v/dart_json_mapper_flutter.svg)](https://pub.dartlang.org/packages/dart_json_mapper_flutter)

This is a [dart-json-mapper][1] complementary package provides support for https://github.com/flutter/flutter types in order to serialize / deserialize them from / to JSON.
 
## Basic setup

Beforehand please consult with basic setup section from [dart-json-mapper][1] package. 

Please add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  dart_json_mapper:
  dart_json_mapper_flutter:
dev_dependencies:
  build_runner:
```

Usage example
**lib/main.dart**
```dart
import 'dart:ui' show Color;
import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:dart_json_mapper_flutter/dart_json_mapper_flutter.dart'
    show flutterAdapter;

import 'main.reflectable.dart' show initializeReflectable;

@jsonSerializable
class FlutterClass {
  Color color;

  FlutterClass(this.color);
}

void main() {
  initializeReflectable();
  JsonMapper().useAdapter(flutterAdapter);
  
  print(JsonMapper.serialize(
     FlutterClass(Color(0x3f4f5f))
  ));
}
```
output:
```json
{
  "color": "#3F4F5F"
}
```

[1]: https://github.com/k-paxian/dart-json-mapper