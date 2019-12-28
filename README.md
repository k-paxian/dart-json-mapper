[![Build Status][ci-badge]][ci-badge-url]
[![pub package](https://img.shields.io/pub/v/dart_json_mapper.svg)](https://pub.dartlang.org/packages/dart_json_mapper)
[![Build Status][pedantic-badge]][pedantic-url]

This package allows programmers to annotate Dart classes in order to
  Serialize / Deserialize them to / from JSON.
  
## Why?

* Compatible with **all** Dart platforms, including [Flutter](https://pub.dartlang.org/flutter/packages) and [Web](https://pub.dartlang.org/web/packages) platforms
* No need to extend your classes from **any** mixins/base/abstract classes to keep code leaner
* Clean and simple setup, transparent and straight-forward usage with **no heavy maintenance**
* **No extra boilerplate**, 100% generated code, which you'll *never* see.
* **Custom converters** per each class field, full control over the process
* **NO** dependency on `dart:mirrors`, one of the reasons is described [here][1].
* Because Serialization/Deserialization is **NOT** a responsibility of your Model classes.

Dart classes reflection mechanism is based on [reflectable][3] library. 
This means "extended types information" is auto-generated out of existing Dart program 
guided by the annotated classes only, as the result types information is accessible at runtime, at a reduced cost.

Typical `Flutter.io project integration` sample can be found [here][4]

* [Basic setup](#basic-setup)
* [Configuration use cases](#format-date--number-types)
    * [DateTime / num types formatting](#format-date--number-types)
    * [Immutable classes](#example-with-immutable-class)
    * [Iterable types](#iterable-types)
    * [Enum types](#enum-types)
    * [Extended classes](#inherited-classes-derived-from-abstract--base-class)
    * [Nesting](#nesting-configuration)
    * [Schemes](#schemes)
    * [Custom types](#custom-types)
* [Annotations](#annotations)
* [Complementary adapters](#complementary-adapter-libraries)

## Basic setup

Please add the following dependencies to your `pubspec.yaml`:

```
dependencies:
  dart_json_mapper: any
dev_dependencies:
  build_runner: any
```

Say, you have a dart program *main.dart* having some classes intended to be traveling to JSON and back.
- First thing you should do is to put `@jsonSerializable` annotation on each of those classes
- Next step is to auto generate *main.reflectable.dart* file. And afterwards import that file into *main.dart*

**lib/main.dart**
```dart
import 'package:dart_json_mapper/dart_json_mapper.dart';

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
}
```

```json
{ 
  "a": 456,
  "d": "yes"
}
```

Go ahead and create a `build.yaml` file in your project root directory. Then add the
following content:

```
targets:
  $default:
    builders:
      reflectable:
        generate_for:
          - lib/main.dart
        options:
          formatted: true
```

Now run the code generation step with the root of your package as the current
directory:

```shell
> pub run build_runner build
```

**You'll need to re-run code generation each time you are making changes to `lib/main.dart`**
So for development time, use `watch` like this

```shell
> pub run build_runner watch
```

Each time you modify your project code, all *.reflectable.dart files will be updated as well.
- Next step is to add "*.reflectable.dart" to your .gitignore
- And this is it, you are all set and ready to go. Happy coding!

## Format DateTime / num types

In order to format `DateTime` or `num` instance as a JSON string, it is possible to
provide [intl][2] based formatting patterns.

**DateTime**
```dart
@JsonProperty(converterParams: {'format': 'MM-dd-yyyy H:m:s'})
DateTime lastPromotionDate = DateTime(2008, 05, 13, 22, 33, 44);

@JsonProperty(converterParams: {'format': 'MM/dd/yyyy'})
DateTime hireDate = DateTime(2003, 02, 28);
```

```json
{
"lastPromotionDate": "05-13-2008 22:33:44",
"hireDate": "02/28/2003"
}
```

**num**
```dart
@JsonProperty(converterParams: {'format': '##.##'})
num salary = 1200000.246;
```

```json
{
"salary": "1200000.25"
}
```

As well, it is possible to utilize `converterParams` map to provide custom
parameters to your [custom converters](#custom-based-types-handling).

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

## Iterable types

Since Dart language has no possibility to create typed iterables dynamically, it's a bit of a challenge
to create exact typed lists/sets/etc via reflection approach. Those types has to be declared explicitly.

For example List() will produce `List<dynamic>` type which can't be directly set to the concrete
target field `List<Car>` for instance. So obvious workaround will be to cast 
`List<dynamic> => List<Car>`, which can be performed as `List<dynamic>().cast<Car>()`.

In order to do so, we'll use Value Decorator Function inspired by Decorator pattern.

```dart
final iterableCarDecorator = (value) => value.cast<Car>();
final String json = '[{"modelName": "Audi", "color": "Color.Green"}]';

JsonMapper.registerValueDecorator<List<Car>>(iterableCarDecorator);
List<Car> myCarsList = JsonMapper.deserialize(json);
...
JsonMapper.registerValueDecorator<Set<Car>>(iterableCarDecorator);
Set<Car> myCarsSet = JsonMapper.deserialize(json);
```

Basic iterable based generics using Dart built-in types like `List<num>, List<Sring>, List<bool>, 
List<DateTime>, Set<num>, Set<Sring>, Set<bool>, Set<DateTime>, etc.` supported out of the box. 

For custom iterable types like `List<Car> / Set<Car>` you have to register value decorator function 
as showed in a code snippet above before using deserialization. This function will have explicit 
cast to concrete iterable type.

## Enum types

Enum construction in Dart has a specific meaning, and has to be treated accordingly.

Enum declarations should not be annotated with `@jsonSerializable`, since they are not a classes 
technically, but a special built in types.

```dart
enum Color { Red, Blue, Green, Brown, Yellow, Black, White }
...
@JsonProperty(enumValues: Color.values)
Color color;
```

Each enum based class field has to be annotated as showed in a snippet above. 
Enum`.values` refers to a list of all possible enum values, it's a handy built in capability of all
enum based types. Without providing all values it's not possible to traverse it's values properly.

## Inherited classes derived from abstract / base class

Please use complementary `@Json(typeNameProperty: 'typeName')` annotation for subclasses
derived from abstract or base class. This way _dart-json-mapper_
will dump the concrete object type to the JSON output during serialization process.
This ensures, that _dart-json-mapper_ will be able to reconstruct the object with
the proper type during deserialization process.

``` dart
@jsonSerializable
@Json(typeNameProperty: 'typeName')
abstract class Business {
  String name;
}

@jsonSerializable
class Hotel extends Business {
  int stars;

  Hotel(this.stars);
}

@jsonSerializable
class Startup extends Business {
  int userCount;

  Startup(this.userCount);
}

@jsonSerializable
class Stakeholder {
  String fullName;
  List<Business> businesses;

  Stakeholder(this.fullName, this.businesses);
}

// given
final jack = Stakeholder("Jack", [Startup(10), Hotel(4)]);

// when
JsonMapper.registerValueDecorator<List<Business>>((value) => value.cast<Business>());
final String json = JsonMapper.serialize(jack);
final Stakeholder target = JsonMapper.deserialize(json);

// then
expect(target.businesses[0], TypeMatcher<Startup>());
expect(target.businesses[1], TypeMatcher<Hotel>());
```

## Nesting configuration

In case if you need to operate on particular portions of huge JSON object and 
you don't have a true desire to reconstruct the same deep nested JSON objects 
hierarchy with corresponding Dart classes. This section is for you!

Say, you have a json similar to this one
```json
{
  "root": {
    "foo": {
      "bar": {
        "baz": {
          "items": [
            "a",
            "b",
            "c"
          ]
        }
      }
    }
  }
}          
```

And with code similar to this one

``` dart
@jsonSerializable
@Json(name: 'root/foo/bar')
class RootObject {
  @JsonProperty(name: 'baz/items')
  List<String> items;

  RootObject({this.items});
}

// when
final RootObject instance = JsonMapper.deserialize(json);
// then
expect(instance.items.length, 3);
expect(instance.items, ['a', 'b', 'c']);
```  
you'll have it done nice and quick.

`@Json(name: 'root/foo/bar')` provides a *root nesting* for the entire annotated class,
this means all class fields will be nested under this 'root/foo/bar' path in Json.

`@JsonProperty(name: 'baz/items')` provides a field nesting relative to the class *root nesting* 

## Schemes

Scheme - is a set of annotations associated with common scheme id.
This enables the possibility to map a **single** Dart class to **many** different JSON structures.

This approach usually useful for distinguishing [DEV, PROD, TEST, ...] environments, w/o producing separate 
Dart classes for each environment.  

``` dart
enum Scheme { A, B }

@jsonSerializable
@Json(name: 'default')
@Json(name: '_', scheme: Scheme.B)
@Json(name: 'root', scheme: Scheme.A)
class Object {
  @JsonProperty(name: 'title_test', scheme: Scheme.B)
  String title;

  Object(this.title);
}

// given
final instance = Object('Scheme A');
// when
final json = JsonMapper.serialize(instance, SerializationOptions(indent: '', scheme: Scheme.A));
// then
expect(json, '''{"root":{"title":"Scheme A"}}''');

// given
final instance = Object('Scheme B');
// when
final json = JsonMapper.serialize(instance, SerializationOptions(indent: '', scheme: Scheme.B));
// then
expect(json, '''{"_":{"title_test":"Scheme B"}}''');

// given
final instance = Object('No Scheme');
// when
final json = JsonMapper.serialize(instance, SerializationOptions(indent: ''));
// then
expect(json, '''{"default":{"title":"No Scheme"}}''');
```

## Custom types

For the very custom types, specific ones, or doesn't currently supported by this library, you can 
provide your own custom Converter class per each custom runtimeType.

```dart
/// Abstract class for custom converters implementations
abstract class ICustomConverter<T> {
  dynamic toJSON(T object, [JsonProperty jsonProperty]);
  T fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]);
}
```

All you need to get going with this, is to implement this abstract class
 
```dart
class CustomStringConverter implements ICustomConverter<String> {
  const CustomStringConverter() : super();

  @override
  String fromJSON(dynamic jsonValue, [JsonProperty jsonProperty]) {
    return jsonValue;
  }

  @override
  dynamic toJSON(String object, [JsonProperty jsonProperty]) {
    return '_${object}_';
  }
}
```

And register it afterwards, if you want to have it applied for **all** occurrences of specified type 

```dart
JsonMapper.registerConverter<String>(CustomStringConverter());
```

OR use it individually on selected class fields, via `@JsonProperty` annotation 

```dart
@JsonProperty(converter: CustomStringConverter())
String title;
```

## Complementary adapter libraries

For seamless integration with popular use cases, feel free to pick an 
existing adapter, or create one for your use case. 

| Name        | Bages | Use case |
| ----------- |:-----------------------:|:-----------|  
|[dart-json-mapper-mobx][5]| [![pub package](https://img.shields.io/pub/v/dart_json_mapper_mobx.svg)](https://pub.dartlang.org/packages/dart_json_mapper_mobx) | [MobX][7] |
|[dart-json-mapper-fixnum][6]| [![pub package](https://img.shields.io/pub/v/dart_json_mapper_fixnum.svg)](https://pub.dartlang.org/packages/dart_json_mapper_fixnum) | [Fixnum][8] |


[1]: https://github.com/flutter/flutter/issues/1150
[2]: https://pub.dartlang.org/packages/intl
[3]: https://pub.dartlang.org/packages/reflectable
[4]: https://github.com/k-paxian/samples/tree/master/jsonexample
[5]: adapters/mobx
[6]: adapters/fixnum
[7]: https://mobx.pub
[8]: https://github.com/dart-lang/fixnum

[ci-badge]: https://github.com/k-paxian/dart-json-mapper/workflows/Unit%20Tests/badge.svg
[ci-badge-url]: https://github.com/k-paxian/dart-json-mapper/actions?query=workflow%3A%22Unit+Tests%22

[pedantic-badge]: https://dart-lang.github.io/linter/lints/style-pedantic.svg
[pedantic-url]: https://github.com/dart-lang/pedantic
