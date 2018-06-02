# dart-json-mapper

[![pub package](https://img.shields.io/pub/v/dart_json_mapper.svg)](https://pub.dartlang.org/packages/dart_json_mapper)

Serialize / Deserialize Dart Objects to / from JSON

This package allows programmers to annotate Dart classes in order to
  serialize / deserialize them from / to JSON.
  
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

  @JsonProperty(ignore: true)
  bool b;

  @JsonProperty(name: 'd')
  String c;

  // Important! Constructor must not have any required parameters.
  MyData([this.a, this.b, this.c]);
}

main() {
  initializeReflectable(); // Imported from main.reflectable.dart
  
  print(JsonMapper.serialize(new MyData(456, true, "yes")));
  // { 
  //  "a": 456,
  //  "d": "yes"
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

## Why is this library exists? 
`When there are so many alternatives out there`

It would be nice to have a Json serialization/deserialization library
* Compatible with both Flutter and Web platforms
* No need to extend target classes from *any* mixins/base/abstract classes to keep code cleaner
* Clean and simple setup, transparent and straightforward usage with no heavy maintanance involved
* No extra boilerplate code involved
* Custom converters support per each target class field

| Name        | `Web + Flutter` support | Concerns   |
| ----------- |:-----------------------:|:-----------|  
|[json_object_lite][100]| yes |  Target class has to be inherited from JsonObjectLite + boilerplate code |
|[jaguar_serializer][101]| yes | Tons of boilerplate, personal serializer generated per each target class, unnecessary abstraction - "model"|
|[nomirrorsmap][102]| yes |  Cumbersome usage|
|[dson_core][103]| no | |
|[dson][104]| yes | Requires target class to be inherited from mixin + too much different unobvious annotations, like @ignore, @cyclical, @uid, etc|
|[dartson][105]| no | |
|[json_god][106]| no | |
|[jaguar_json][107]| no | |
|[serializer_generator][108]| no | |
|[dynamo][109]| yes   |Produces JSON output with type information injected in it|
|[serialization][110]|yes   |Cumbersome configuration and setup, will require continuous maintenance|
|[serializable][111]| yes  |Requires target class to be inherited from mixin, no custom logic allowed|
|[json_annotation][112]|yes   |Depends on  [json_serializable][113] which is not compatible with Flutter|
|[json_serializable][113]| no  ||
|[json_mapper][114]| no ||


[100]: https://pub.dartlang.org/packages/json_object_lite
[101]: https://pub.dartlang.org/packages/jaguar_serializer
[102]: https://pub.dartlang.org/packages/nomirrorsmap
[103]: https://pub.dartlang.org/packages/dson_core
[104]: https://pub.dartlang.org/packages/dson
[105]: https://pub.dartlang.org/packages/dartson
[106]: https://pub.dartlang.org/packages/json_god
[107]: https://pub.dartlang.org/packages/jaguar_json
[108]: https://pub.dartlang.org/packages/serializer_generator
[109]: https://pub.dartlang.org/packages/dynamo
[110]: https://pub.dartlang.org/packages/serialization
[111]: https://pub.dartlang.org/packages/serializable
[112]: https://pub.dartlang.org/packages/json_annotation
[113]: https://pub.dartlang.org/packages/json_serializable
[114]: https://pub.dartlang.org/packages/json_mapper

## Feature requests and bug reports

Please file feature requests and bugs using the
[github issue tracker for this repository][2].



[1]: https://github.com/flutter/flutter/issues/1150
[2]: https://github.com/k-paxian/dart-json-mapper/issues
[3]: https://pub.dartlang.org/packages/reflectable
