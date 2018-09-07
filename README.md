# dart-json-mapper

[![Build Status][travis-badge]][travis-badge-url]
[![pub package](https://img.shields.io/pub/v/dart_json_mapper.svg)](https://pub.dartlang.org/packages/dart_json_mapper)

This package allows programmers to annotate Dart classes in order to
  Serialize / Deserialize them to / from JSON.
  
## Why?

* Compatible with **all** Dart platforms, including **Flutter** and **Web** platforms
* No need to extend your classes from **any** mixins/base/abstract classes to keep code leaner
* Clean and simple setup, transparent and straightforward usage with **no heavy maintenance**
* **No extra boilerplate** involved, 100% generated only
* **Custom converters** support per each class field
  
## Basic setup

Library has **NO** dependency on `dart:mirrors`, one of the reasons is described [here][1].

Dart classes reflection mechanism is based on [reflectable][3] library. This means "extended types information" is auto-generated out of existing Dart program guided by the annotated classes only, as the result types information is accesible at runtime, at a reduced cost.

Say, you have a dart program *main.dart* having some classes intended to be traveling to JSON and back.
- First thing you should do is to put `@jsonSerializable` annotation on each of those classes
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

  MyData(this.a, this.b, this.c);
}

main() {
  initializeReflectable(); // Imported from main.reflectable.dart
  
  print(JsonMapper.serialize(MyData(456, true, "yes")));
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

## Example with immutable class

```dart
enum Color { Red, Blue, Green, Brown, Yellow, Black, White }

@jsonSerializable
class Car {
    @JsonProperty(name: 'modelName')
    String model;
    
    @JsonProperty(enumValues: Color.values)
    Color color;
    
    @JsonProperty(ignore: true)
    Car replacement;
    
    Car(this.model, this.color);
}

@jsonSerializable
class Immutable {
    final int id;
    final String name;
    final Car car;
    
    const Immutable(this.id, this.name, this.car);
}

print(
  JsonMapper.serialize(
    Immutable(1, 'Bob', Car('Audi', Color.Green))
  )
);
``` 
Output:
```json
{
 "id": 1,
 "name": "Bob",
 "car": {
  "modelName": "Audi",
  "color": "Color.Green"
 }
}
```

## List based types handling

Since Dart language has no possibility to create typed lists dynamically, it's a bit of a challenge
to create exact typed lists via reflection approach. List types has to be declared explicitly.

For example List() will produce `List<dynamic>` type which can't be directly set to the concrete
target field `List<Car>` for instance. So obvious workaround will be to cast 
`List<dynamic> => List<Car>`, which can be performed as `List<dynamic>().cast<Car>()`.

In order to do so, we'll use Value Decorator Function inspired by Decorator pattern.

```dart
JsonMapper.registerValueDecorator(List<Car>().runtimeType, (value) => value.cast<Car>());

List<Car> myCarsList = JsonMapper.deserialize('[{"modelName": "Audi", "color": "Color.Green"}]');
```

Basic list based types like `List<num>, List<Sring>, List<bool>, List<DateTime>`, etc. 
supported out of the box. For custom List types like `List<Car>` you have to register value decorator
function as showed in a code snippet above before using deserialization. 
This function will have explicit cast to concrete List type.

## Enum based types handling

Enum construction in Dart has a specific meaning, and has to be treated accordingly.

Enum declarations should not be annotated with `@jsonSerializable`, since they are not a classes 
technically, but a special built in types.

```dart
@JsonProperty(enumValues: Color.values)
Color color;
```

Each enum based class field has to be annotated as showed in a snippet above. 
Enum`.values` refers to a list of all possible enum values, it's a handy built in capability of all
enum based types. Without providing all values it's not possible to traverse it's values properly.
 
## Feature requests and bug reports

Please file feature requests and bugs using the
[github issue tracker for this repository][2].



[1]: https://github.com/flutter/flutter/issues/1150
[2]: https://github.com/k-paxian/dart-json-mapper/issues
[3]: https://pub.dartlang.org/packages/reflectable

[travis-badge]: https://travis-ci.org/k-paxian/dart-json-mapper.svg?branch=master
[travis-badge-url]: https://travis-ci.org/k-paxian/dart-json-mapper