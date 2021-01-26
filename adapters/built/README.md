[![pub package](https://img.shields.io/pub/v/dart_json_mapper_built.svg)](https://pub.dartlang.org/packages/dart_json_mapper_built)

This is a [dart-json-mapper][1] complementary package provides support for https://pub.dev/packages/built_collection types in order to serialize / deserialize them from / to JSON.
 
## Basic setup

Beforehand please consult with basic setup section from [dart-json-mapper][1] package. 

Please add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  dart_json_mapper:
  dart_json_mapper_built:
dev_dependencies:
  build_runner:
```

Usage example
**lib/main.dart**
```dart
import 'package:built_collection/built_collection.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart' show JsonMapper, jsonSerializable;
import 'package:dart_json_mapper_built/dart_json_mapper_built.dart' show builtAdapter;

import 'main.mapper.g.dart' show initializeJsonMapper;

@jsonSerializable
class ImmutableClass {
  final BuiltList<int> list;

  const ImmutableClass(this.list);
}

void main() {
  initializeJsonMapper(adapters: [builtAdapter]);

  print(JsonMapper.serialize(
     ImmutableClass(BuiltList.of([1, 2, 3]))
  ));
}
```
output:
```json
{
  "list": [1,2,3]
}
```

[1]: https://github.com/k-paxian/dart-json-mapper