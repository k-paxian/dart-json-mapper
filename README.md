[![Build Status][ci-badge]][ci-badge-url]
[![Financial Contributors on Open Collective](https://opencollective.com/dart-json-mapper/all/badge.svg?label=financial+contributors)](https://opencollective.com/dart-json-mapper) [![pub package](https://img.shields.io/pub/v/dart_json_mapper.svg)](https://pub.dartlang.org/packages/dart_json_mapper)
[![Build Status][pedantic-badge]][pedantic-url]

This package allows programmers to annotate Dart classes in order to
  Serialize / Deserialize them to / from JSON.
  
## Why?

* Compatible with **all** Dart platforms, including [Flutter](https://pub.dartlang.org/flutter/packages) and [Web](https://pub.dartlang.org/web/packages) platforms
* No need to extend your classes from **any** mixins/base/abstract classes to keep code leaner
* Clean and simple setup, transparent and straight-forward usage with **no heavy maintenance**
* Feature parity with highly popular [Java Jackson][12], and only **4** [annotations](#annotations) to remember, to cover all possible use cases.
* **No extra boilerplate**, 100% generated code, which you'll *never* see.
* **Complementary adapters** full control over the process when you strive for maximum flexibility.
* **NO** dependency on `dart:mirrors`, one of the reasons is described [here][1].
* Because Serialization/Deserialization is **NOT** a responsibility of your Model classes.

Dart classes reflection mechanism is based on [reflectable][3] library. 
This means "extended types information" is auto-generated out of existing Dart program 
guided by the annotated classes **only**, as the result types information is accessible at runtime, at a reduced cost.

Typical `flutter.dev project integration` sample can be found [here][4]

![](banner.svg)

* [Basic setup](#basic-setup)
* [Annotations](#annotations)
* [Known limitations](#known-limitations)
* [Documentation][docs]
* [Configuration use cases](#format-datetime--num-types)
    * [Extended classes](#inherited-classes-derived-from-abstract--base-class)
    * [Immutable classes](#example-with-immutable-class)
    * [Get or Set fields](#get-or-set-fields)
    * [Constructor parameters](#constructor-parameters)
    * [Unmapped properties](#unmapped-properties)
    * [DateTime / num types](#format-datetime--num-types)
    * [Iterable types](#iterable-types)
    * [Enum types](#enum-types)
    * [Name casing styles](#name-casing-styles-pascal-kebab-snake-snakeallcaps)
    * [Serialization template](#serialization-template)
    * [Deserialization template](#deserialization-template)
    * [Custom types](#custom-types)
    * [Nesting](#nesting-configuration)
    * [Schemes](#schemes)
* [Adapters](#complementary-adapter-libraries)
    * [How to use adapter?](#complementary-adapter-libraries)
    * [![pub package](https://img.shields.io/pub/v/dart_json_mapper_mobx.svg)](https://pub.dartlang.org/packages/dart_json_mapper_mobx) | [dart_json_mapper_mobx](adapters/mobx) | [MobX][7]
    * [![pub package](https://img.shields.io/pub/v/dart_json_mapper_fixnum.svg)](https://pub.dartlang.org/packages/dart_json_mapper_fixnum) | [dart_json_mapper_fixnum](adapters/fixnum) | [Fixnum][8]
    * [![pub package](https://img.shields.io/pub/v/dart_json_mapper_flutter.svg)](https://pub.dartlang.org/packages/dart_json_mapper_flutter) | [dart_json_mapper_flutter](adapters/flutter) | [Flutter][11]

## Basic setup

Please add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  dart_json_mapper:
dev_dependencies:
  build_runner:
```

Say, you have a dart program *main.dart* having some classes intended to be traveling to JSON and back.
- First thing you should do is to put `@jsonSerializable` annotation on each of those classes
- Next step is to auto generate *main.reflectable.dart* file. And afterwards import that file into *main.dart*

**lib/main.dart**
```dart
import 'package:dart_json_mapper/dart_json_mapper.dart' show JsonMapper, jsonSerializable, JsonProperty;

import 'main.reflectable.dart' show initializeReflectable;

@jsonSerializable // This annotation let instances of MyData travel to/from JSON
class MyData {
  int a = 123;

  @JsonProperty(ignore: true)
  bool b;

  @JsonProperty(name: 'd')
  String c;

  MyData(this.a, this.b, this.c);
}

main() {
  initializeReflectable();
  
  print(JsonMapper.serialize(MyData(456, true, "yes")));
}
```
output:
```json
{ 
  "a": 456,
  "d": "yes"
}
```

Go ahead and create a `build.yaml` file in your project root directory. Then add the
following content:

```yaml
targets:
  $default:
    builders:
      reflectable:
        generate_for:
          - lib/main.dart
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
output:
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
output:
```json
{
"salary": "1200000.25"
}
```

As well, it is possible to utilize `converterParams` map to provide custom
parameters to your [custom converters](#custom-types).

## Get or Set fields

When relying on Dart `getters / setters`, no need to annotate them.
But when you have custom `getter / setter` methods, you should provide annotations for them.

```dart
@jsonSerializable
class AllPrivateFields {
  String _name;
  String _lastName;

  set name(dynamic value) {
    _name = value;
  }

  String get name => _name;

  @JsonProperty(name: 'lastName')
  void setLastName(dynamic value) {
    _lastName = value;
  }

  @JsonProperty(name: 'lastName')
  String getLastName() => _lastName;
}

// given
final json = '''{"name":"Bob","lastName":"Marley"}''';

// when
final instance = JsonMapper.deserialize<AllPrivateFields>(json);

// then
expect(instance.name, 'Bob');
expect(instance.getLastName(), 'Marley');

// when
final targetJson = JsonMapper.serialize(instance, SerializationOptions(indent: ''));

// then
expect(targetJson, json);
```

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
output:
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

## Constructor parameters

Sometimes you don't really care or don't want to store some json property as a dedicated class field,
but instead, you would like to use it's value in constructor to calculate other class properties.
This way you don't have a convenience to annotate a class field, but you could utilize constructor parameter for that.    

With the input JSON like this:
```json
{"LogistikTeileInOrdnung":"true"}
```

You could potentially have a class like this:
```dart
@jsonSerializable
class BusinessObject {
  final bool logisticsChecked;
  final bool logisticsOK;

  BusinessObject()
      : logisticsChecked = false,
        logisticsOK = true;

  @jsonConstructor
  BusinessObject.fromJson(
      @JsonProperty(name: 'LogistikTeileInOrdnung') String processed)
      : logisticsChecked = processed != null && processed != 'null',
        logisticsOK = processed == 'true';
}
```

## Unmapped properties

If you are looking for an alternative to Java Jackson `@JsonAnySetter / @JsonAnyGetter`
It is possible to configure the same scenario as follows:

```dart
@jsonSerializable
class UnmappedProperties {
  String name;

  Map<String, dynamic> _extraPropsMap = {};

  @jsonProperty
  void unmappedSet(String name, dynamic value) {
    _extraPropsMap[name] = value;
  }

  @jsonProperty
  Map<String, dynamic> unmappedGet() {
    return _extraPropsMap;
  }
}

// given
final json = '''{"name":"Bob","extra1":1,"extra2":"xxx"}''';

// when
final instance = JsonMapper.deserialize<UnmappedProperties>(json);

// then
expect(instance.name, 'Bob');
expect(instance._extraPropsMap['name'], null);
expect(instance._extraPropsMap['extra1'], 1);
expect(instance._extraPropsMap['extra2'], 'xxx');
```

## Iterable types

Since Dart language has no possibility to create typed iterables dynamically, it's a bit of a challenge
to create exact typed lists/sets/etc via reflection approach. Those types has to be declared explicitly.

For example List() will produce `List<dynamic>` type which can't be directly set to the concrete
target field `List<Car>` for instance. So obvious workaround will be to cast 
`List<dynamic> => List<Car>`, which can be performed as `List<dynamic>().cast<Car>()`.

In order to do so, we'll use Value Decorator Function inspired by Decorator pattern.

```dart
final String json = '[{"modelName": "Audi", "color": "Color.Green"}]';
JsonMapper().useAdapter(JsonMapperAdapter(
  valueDecorators: {
    typeOf<List<Car>>(): (value) => value.cast<Car>(),
    typeOf<Set<Car>>(): (value) => value.cast<Car>()
  })
);

final myCarsList = JsonMapper.deserialize<List<Car>>(json);
final myCarsSet = JsonMapper.deserialize<Set<Car>>(json);
```

Basic iterable based generics using Dart built-in types like `List<num>, List<String>, List<bool>,
List<DateTime>, Set<num>, Set<String>, Set<bool>, Set<DateTime>, etc.` supported out of the box.

For custom iterable types like `List<Car> / Set<Car>` you have to provide value decorator function 
as showed in a code snippet above before using deserialization. This function will have explicit 
cast to concrete iterable type.

### OR an *easy case* 

When you are able to pre-initialize your Iterables with an empty instance,
like on example below, you don't need to mess around with value decorators.

```dart
@jsonSerializable
class Item {}

@jsonSerializable
class IterablesContainer {
  List<Item> list = [];
  Set<Item> set = {};
}

// given
final json = '''{"list":[{}, {}],"set":[{}, {}]}''';

// when
final target = JsonMapper.deserialize<IterablesContainer>(json);

// then
expect(target.list, TypeMatcher<List<Item>>());
expect(target.list.first, TypeMatcher<Item>());
expect(target.list.length, 2);

expect(target.set, TypeMatcher<Set<Item>>());
expect(target.set.first, TypeMatcher<Item>());
expect(target.set.length, 2);
```

### List of Lists of Lists ...

Using value decorators, it's possible to configure nested lists of
virtually any depth.

```dart
@jsonSerializable
class Item {}

@jsonSerializable
class ListOfLists {
  List<List<Item>> lists;
}

// given
final json = '''{
 "lists": [
   [{}, {}],
   [{}, {}, {}]
 ]
}''';

// when
JsonMapper().useAdapter(JsonMapperAdapter(
  valueDecorators: {
    typeOf<List<List<Item>>>(): (value) => value.cast<List<Item>>(),
    typeOf<List<Item>>(): (value) => value.cast<Item>()
  })
);

final target = JsonMapper.deserialize<ListOfLists>(json);
// then
expect(target.lists.length, 2);
expect(target.lists.first.length, 2);
expect(target.lists.last.length, 3);
expect(target.lists.first.first, TypeMatcher<Item>());
expect(target.lists.last.first, TypeMatcher<Item>());
```

## Enum types

Enum construction in Dart has a specific meaning, and has to be treated accordingly.

Generally, we always have to bear in mind following cases around Enums:

* Your own Enums declared as part of your program code, thus they **can** be annotated.
* Enums from third party packages, they **can not** be annotated.

So whenever possible, you should annotate your Enum declarations as follows
```dart
@jsonSerializable
@Json(enumValues: Color.values)
enum Color { Red, Blue, Green, Brown, Yellow, Black, White }
```

And annotate class fields referencing Enums as follows
```dart
@JsonProperty(enumValues: Color.values)
Color color;

@JsonProperty(enumValues: Color.values)
List<Color> colors;

@JsonProperty(enumValues: Color.values)
Set<Color> colorsSet;

@JsonProperty(enumValues: Color.values)
Map<Color, int> colorPriorities = <Color, int>{};
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
  List<Business> businesses = [];

  Stakeholder(this.fullName, this.businesses);
}

// given
final jack = Stakeholder("Jack", [Startup(10), Hotel(4)]);

// when
final String json = JsonMapper.serialize(jack);
final Stakeholder target = JsonMapper.deserialize(json);

// then
expect(target.businesses[0], TypeMatcher<Startup>());
expect(target.businesses[1], TypeMatcher<Hotel>());
```

## Serialization template

In case you already have an instance of huge JSON Map object
and portion of it needs to be surgically updated, then you can pass
your `Map<String, dynamic>` instance as a `template` parameter for
`SerializationOptions`

```dart
enum Color { Red, Blue, Green, Brown, Yellow, Black, White }

// given
final template = {'a': 'a', 'b': true};

// when
final json = JsonMapper.serialize(Car('Tesla S3', Color.Black),
  SerializationOptions(indent: '', template: template));

// then
expect(json,
  '''{"a":"a","b":true,"modelName":"Tesla S3","color":"Color.Black"}''');
```

## Deserialization template

In case you need to deserialize specific `Map<K, V>` type then you can pass
typed instance of it as a `template` parameter for `DeserializationOptions`.

Since typed `Map<K, V>` instance cannot be created dynamically due to Dart
language nature, so you are providing ready made instance to use for deserialization output.

```dart
enum Color { Red, Blue, Green, Brown, Yellow, Black, White }

// given
final json = '{"Color.Black":1,"Color.Blue":2}';

// when
final target = JsonMapper.deserialize(
          json, DeserializationOptions(template: <Color, int>{}));

// then
expect(target, TypeMatcher<Map<Color, int>>());
expect(target.containsKey(Color.Black), true);
expect(target.containsKey(Color.Blue), true);
expect(target[Color.Black], 1);
expect(target[Color.Blue], 2);
```

## Name casing styles [Pascal, Kebab, Snake, SnakeAllCaps]

Assuming your Dart code is following [Camel case style][9], but that is not 
always `true` for JSON models, they could follow 
[one of those popular - Pascal, Kebab, Snake, SnakeAllCaps][10] styles, right? 

That's why we need a smart way to manage that, instead of
hand coding each property using `@JsonProperty(name: ...)` it is possible to pass
`CaseStyle` parameter to serialization / deserialization methods. 

```dart
@jsonSerializable
class NameCaseObject {
  String mainTitle;
  String description;
  bool hasMainProperty;

  NameCaseObject({this.mainTitle, this.description, this.hasMainProperty});
}

/// Serialization

// given
final instance = NameCaseObject(
    mainTitle: 'title', description: 'desc', hasMainProperty: true);
// when
final json = JsonMapper.serialize(instance,
    SerializationOptions(indent: '', caseStyle: CaseStyle.Kebab));
// then
expect(json, '''{"main-title":"title","description":"desc","has-main-property":true}''');

/// Deserialization

// given
final json = '''{"main-title":"title","description":"desc","has-main-property":true}''';
// when
final instance = JsonMapper.deserialize<NameCaseObject>(
    json, DeserializationOptions(caseStyle: CaseStyle.Kebab));
// then
expect(instance.mainTitle, 'title');
expect(instance.description, 'desc');
expect(instance.hasMainProperty, true);
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
class BarObject {
  @JsonProperty(name: 'baz/items')
  List<String> items;

  BarObject({this.items});
}

// when
final instance = JsonMapper.deserialize<BarObject>(json);

// then
expect(instance.items.length, 3);
expect(instance.items, ['a', 'b', 'c']);
```  
you'll have it done nice and quick.

`@Json(name: 'root/foo/bar')` provides a *root nesting* for the entire annotated class,
this means all class fields will be nested under this 'root/foo/bar' path in Json.

`@JsonProperty(name: 'baz/items')` provides a field nesting relative to the class *root nesting* 

`name` is compliant with [RFC 6901][rfc6901] JSON pointer

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
JsonMapper().useAdapter(JsonMapperAdapter(
  converters: {
    String: CustomStringConverter()
  })
);
```

OR use it individually on selected class fields, via `@JsonProperty` annotation 

```dart
@JsonProperty(converter: CustomStringConverter())
String title;
```

## Annotations

* `@JsonSerializable()` or `@jsonSerializable` for short, It's a **required** marker annotation for class or Enum declarations.
Use it to mark all the Dart objects you'd like to be traveling to / from JSON
    * Has **NO** params
* `@JsonConstructor()` or `@jsonConstructor` for short, It's an **optional** constructor only marker annotation. 
Use it to mark specific Dart class constructor you'd like to be used during deserialization.    
    * *scheme* dynamic [Scheme](#schemes) marker to associate this meta information with particular mapping scheme
* `@Json(...)` It's an *optional* annotation for class or Enum declaration, describes a Dart object to JSON Object mapping.
Why it's not a `@JsonObject()`? just for you to type less characters :smile:
    * *name* Defines [RFC 6901][rfc6901] JSON pointer, denotes the json Object root name/path to be used for mapping.
Example: `'foo', 'bar', 'foo/bar/baz'`
    * *typeNameProperty* declares the necessity for annotated class and all it's subclasses to dump their own type name to
the property named as this param value
    * *enumValues* Provides a way to specify enum values, via Dart built in capability for all Enum instances. `Enum.values`
    * *ignoreNullMembers* If set to `true` Null class members will be excluded from serialization process
    * *allowCircularReferences* As of `int` type. Allows certain number of circular object references during serialization.
    * *scheme* dynamic [Scheme](#schemes) marker to associate this meta information with particular mapping scheme
* `@JsonProperty(...)` It's an *optional* class member annotation, describes JSON Object property mapping.
    * *name* Defines [RFC 6901][rfc6901] JSON pointer, denotes the name/path to be used for property mapping relative to the class *root nesting*
Example: `'foo', 'bar', 'foo/bar/baz'`
    * *scheme* dynamic [Scheme](#schemes) marker to associate this meta information with particular mapping scheme
    * *converter* Declares custom converter instance, to be used for annotated field serialization / deserialization 
    * *converterParams* A `Map<String, dynamic>` of named parameters to be passed to the converter instance
    * *ignore* A bool declares annotated field as ignored so it will be excluded from serialization / deserialization process
    * *ignoreIfNull* A bool declares annotated field as ignored if it's value is null so it will be excluded from serialization / deserialization process
    * *enumValues* Provides a way to specify enum values, via Dart built in capability for all Enum instances. `Enum.values`
    * *defaultValue* Defines field default value

## Known limitations

* [Dart code obfuscation][obfuscation]. If you are using or planning to use `extra-gen-snapshot-options=--obfuscate` option with your Flutter project,
this library shouldn't be your primary choice then. At the moment there is no workaround for this to play nicely together.

## Complementary adapter libraries

If you want a seamless integration with popular use cases, feel free to pick an 
existing adapter or create one for your use case and make a PR to this repo.

**Adapter** - is a library which contains a bundle of pre-configured:

* custom [converters](#custom-types)
* custom [value decorators](#iterable-types)
* custom typeInfo decorators
 
For example, you would like to refer to `Color` type from Flutter in your model class.

* Make sure you have following dependencies in your `pubspec.yaml`:

    ```yaml
    dependencies:
      dart_json_mapper:
      dart_json_mapper_flutter:
    dev_dependencies:
      build_runner:
    ```
* Usually, adapter library exposes `final` adapter definition instance, to be provided as a parameter to `JsonMapper().useAdapter(adapter)`

    ```dart
    import 'dart:ui' show Color;
    import 'package:dart_json_mapper/dart_json_mapper.dart' show JsonMapper, jsonSerializable;    
    import 'package:dart_json_mapper_flutter/dart_json_mapper_flutter.dart' show flutterAdapter;
    
    import 'main.reflectable.dart' show initializeReflectable;
    
    @jsonSerializable
    class ColorfulItem {
      String name;
      Color color;
    
      ColorfulItem(this.name, this.color);
    }
    
    void main() {
      initializeReflectable();
      JsonMapper().useAdapter(flutterAdapter);
      
      print(JsonMapper.serialize(
         ColorfulItem('Item 1', Color(0x3f4f5f))
      ));
    }
    ```
    output:
    ```json
    {
      "name": "Item 1",
      "color": "#3F4F5F"
    }
    ```
### You can easily mix and combine several adapters using following one-liner: 

```dart
JsonMapper()
   .useAdapter(fixnumAdapter)
   .useAdapter(flutterAdapter)
   .useAdapter(mobXAdapter)
   .info(); // print out a list of used adapters to console
```

[1]: https://github.com/flutter/flutter/issues/1150
[2]: https://pub.dartlang.org/packages/intl
[3]: https://pub.dartlang.org/packages/reflectable
[4]: https://github.com/k-paxian/samples/tree/master/jsonexample
[7]: https://github.com/mobxjs/mobx.dart
[8]: https://github.com/dart-lang/fixnum
[9]: https://en.wikipedia.org/wiki/Camel_case
[10]: https://medium.com/better-programming/string-case-styles-camel-pascal-snake-and-kebab-case-981407998841
[11]: https://github.com/flutter/flutter
[12]: https://www.baeldung.com/jackson-annotations

[obfuscation]: https://flutter.dev/docs/deployment/obfuscate

[rfc6901]: https://tools.ietf.org/html/rfc6901

[docs]: https://pub.dev/documentation/dart_json_mapper/latest/dart_json_mapper/dart_json_mapper-library.html

[ci-badge]: https://github.com/k-paxian/dart-json-mapper/workflows/Pipeline/badge.svg
[ci-badge-url]: https://github.com/k-paxian/dart-json-mapper/actions?query=workflow%3A%22Pipeline%22

[pedantic-badge]: https://dart-lang.github.io/linter/lints/style-pedantic.svg
[pedantic-url]: https://github.com/dart-lang/pedantic

## Contributors

### Code Contributors

This project exists thanks to all the people who contribute. [[Contribute](CONTRIBUTING.md)].
<a href="https://github.com/k-paxian/dart-json-mapper/graphs/contributors"><img src="https://opencollective.com/dart-json-mapper/contributors.svg?width=890&button=false" /></a>

### Financial Contributors

Become a financial contributor and help us sustain our community. [[Contribute](https://opencollective.com/dart-json-mapper/contribute)]

#### Individuals

<a href="https://opencollective.com/dart-json-mapper"><img src="https://opencollective.com/dart-json-mapper/individuals.svg?width=890"></a>

#### Organizations

Support this project with your organization. Your logo will show up here with a link to your website. [[Contribute](https://opencollective.com/dart-json-mapper/contribute)]

<a href="https://opencollective.com/dart-json-mapper/organization/0/website"><img src="https://opencollective.com/dart-json-mapper/organization/0/avatar.svg"></a>
<a href="https://opencollective.com/dart-json-mapper/organization/1/website"><img src="https://opencollective.com/dart-json-mapper/organization/1/avatar.svg"></a>
<a href="https://opencollective.com/dart-json-mapper/organization/2/website"><img src="https://opencollective.com/dart-json-mapper/organization/2/avatar.svg"></a>
<a href="https://opencollective.com/dart-json-mapper/organization/3/website"><img src="https://opencollective.com/dart-json-mapper/organization/3/avatar.svg"></a>
<a href="https://opencollective.com/dart-json-mapper/organization/4/website"><img src="https://opencollective.com/dart-json-mapper/organization/4/avatar.svg"></a>
<a href="https://opencollective.com/dart-json-mapper/organization/5/website"><img src="https://opencollective.com/dart-json-mapper/organization/5/avatar.svg"></a>
<a href="https://opencollective.com/dart-json-mapper/organization/6/website"><img src="https://opencollective.com/dart-json-mapper/organization/6/avatar.svg"></a>
<a href="https://opencollective.com/dart-json-mapper/organization/7/website"><img src="https://opencollective.com/dart-json-mapper/organization/7/avatar.svg"></a>
<a href="https://opencollective.com/dart-json-mapper/organization/8/website"><img src="https://opencollective.com/dart-json-mapper/organization/8/avatar.svg"></a>
<a href="https://opencollective.com/dart-json-mapper/organization/9/website"><img src="https://opencollective.com/dart-json-mapper/organization/9/avatar.svg"></a>
