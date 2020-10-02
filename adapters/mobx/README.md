[![pub package](https://img.shields.io/pub/v/dart_json_mapper_mobx.svg)](https://pub.dartlang.org/packages/dart_json_mapper_mobx)

This is a [dart-json-mapper][1] complementary package provides support for MobX.dart classes in order to serialize / deserialize them from / to JSON.
 
## Basic setup

Beforehand please consult with basic setup section from [dart-json-mapper][1] package. 

Please add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  dart_json_mapper:
  dart_json_mapper_mobx:
dev_dependencies:
  build_runner:
```

Usage example
**lib/main.dart**
```dart
import 'package:mobx/mobx.dart' show ObservableList;
import 'package:dart_json_mapper/dart_json_mapper.dart' show JsonMapper, jsonSerializable;
import 'package:dart_json_mapper_mobx/dart_json_mapper_mobx.dart' show mobXAdapter;

import 'main.mapper.g.dart' show initializeJsonMapper;

@jsonSerializable
class MyMobXClass {
  ObservableList<String> mailingList = ObservableList<String>();

  MyMobXClass(this.mailingList);
}

void main() {
  initializeJsonMapper(adapters: [mobXAdapter]);
  
  print(JsonMapper.serialize(
     MyMobXClass(ObservableList<String>.of(['aa@test.com', 'bb@test.com', 'cc@test.com']))
  ));
}
```
output:
```json
{
  "mailingList": ["aa@test.com","bb@test.com","cc@test.com"]
}
```

[1]: https://github.com/k-paxian/dart-json-mapper