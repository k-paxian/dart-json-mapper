[![SWUbanner](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/banner2-direct.svg)](https://vshymanskyy.github.io/StandWithUkraine)
[![Build Status](https://github.com/k-paxian/dart-json-mapper/actions/workflows/ci.yaml/badge.svg)](https://github.com/k-paxian/dart-json-mapper/actions/workflows/ci.yaml)
[![pub package](https://img.shields.io/pub/v/dart_json_mapper.svg)](https://pub.dev/packages/dart_json_mapper)
[![Pub Points](https://img.shields.io/pub/points/dart_json_mapper)](https://pub.dev/packages/dart_json_mapper/score)

This package allows programmers to annotate Dart objects to serialize/deserialize them to/from JSON.

## Introduction

This library provides a powerful and flexible way to handle JSON serialization and deserialization in Dart. It is designed to be compatible with all Dart platforms, including Flutter, by avoiding `dart:mirrors`. The library is inspired by popular serialization libraries like Jackson, Gson, and Serde, offering a rich feature set with a simple and clean API.

The core philosophy of this library is to keep your model classes clean and free of serialization logic. This is achieved through a powerful code generation mechanism that generates a single `*.mapper.g.dart` file for your entire project, containing all the necessary mapping logic.

## Why dart_json_mapper?

- **Cross-Platform Compatibility**: Works on all platforms where Dart runs, with no dependency on `dart:mirrors`.
- **Leaner Code**: No need to extend your classes from any mixins or base classes.
- **No Magic**: No enforced private constructors, `_$` prefixes, or `static` fields.
- **Predictable and Maintainable**: The "configuration over code" approach brings predictability to your codebase and reduces the amount of code you need to read and maintain.
- **Separation of Concerns**: Serialization and deserialization are not the responsibility of your model classes.

This library's reflection mechanism is based on the [reflectable][3] library. This means that "extended types information" is auto-generated from your existing Dart program, guided only by the annotated classes. As a result, type information is accessible at runtime at a reduced cost.

## Comparison with `json_serializable`

While Google's `json_serializable` is the standard for JSON serialization in Dart, `dart_json_mapper` offers a different approach with a richer feature set. Here's a quick comparison:

| Feature                 | `json_serializable`                                                                                                      | `dart_json_mapper`                                                                                                                                    |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Code Generation**     | Generates a separate `*.g.dart` file for each class.                                                                     | Generates a single `main.mapper.g.dart` file for the entire project.                                                                                  |
| **API & Boilerplate**   | Requires a factory constructor (`fromJson`), a `toJson` method, and a mixin in your model classes.                         | Uses a central `JsonMapper` object for serialization, keeping your model classes clean.                                                               |
| **Advanced Features**   | Core serialization features, with custom converters for advanced scenarios.                                              | Rich, built-in feature set, including polymorphism, object cloning, advanced mapping, and schemes.                                                  |
| **Community & Support** | Backed by Google and has a large, active community, making it a safe and reliable choice for most projects.              | A powerful and flexible alternative with a smaller community, ideal for projects that require its advanced features.                                 |

In summary, `json_serializable` is the more standard, straightforward, and widely adopted solution from the Dart team. `dart_json_mapper` offers a more feature-rich, "batteries-included" experience with more powerful out-of-the-box capabilities, potentially at the cost of being a less common choice.

* [Basic setup](#basic-setup)
* [Annotations](#annotations)
* [Builder](#builder)
* [Known limitations](#known-limitations)
* [Documentation][docs]
* [Error Handling](#error-handling)
* [Configuration use cases](#format-datetime--num-types)
    * [Extended classes](#inherited-classes-derived-from-abstract--base-class)
    * [Classes with Mixins](#classes-enhanced-with-mixins-derived-from-abstract-class)
    * [Immutable classes](#example-with-immutable-class)
    * [Get or Set fields](#get-or-set-fields)
    * [Constructor parameters](#constructor-parameters)
    * [Unmapped properties](#unmapped-properties)
    * [DateTime / num types](#format-datetime--num-types)
    * [Iterable types](#iterable-types)
    * [Value injection](#value-injection)
    * [Enum types](#enum-types)
    * [Enums having String / num values](#enums-having-string--num-values)
    * [Name casing styles](#name-casing-styles-pascal-kebab-snake-snakeallcaps)
    * [Serialization template](#serialization-template)
    * [Deserialization template](#deserialization-template)
    * [Custom types](#custom-types)
    * [Nesting](#nesting-configuration)
    * [Name aliases](#name-aliases-configuration)
    * [Relative path reference to parent field from nested object "../id"](#relative-path-reference-to-parent-field-from-nested-object-id)
    * [Relative path reference to parent itself from nested object ".."](#relative-path-reference-to-parent-itself-from-nested-object-)
    * [Schemes](#schemes)
    * [Objects flattening](#objects-flattening)
    * [Objects cloning](#objects-cloning)
    * [URI Conversion](#uri-conversion)
* [Adapters](#complementary-adapter-libraries)
    * [How to use adapter?](#complementary-adapter-libraries)
    * [![pub package](https://img.shields.io/pub/v/dart_json_mapper_built.svg)](https://pub.dev/packages/dart_json_mapper_built) | [dart_json_mapper_built](adapters/built) | [Built Collection][16]
    * [![pub package](https://img.shields.io/pub/v/dart_json_mapper_mobx.svg)](https://pub.dev/packages/dart_json_mapper_mobx) | [dart_json_mapper_mobx](adapters/mobx) | [MobX][7]
    * [![pub package](https://img.shields.io/pub/v/dart_json_mapper_fixnum.svg)](https://pub.dev/packages/dart_json_mapper_fixnum) | [dart_json_mapper_fixnum](adapters/fixnum) | [Fixnum][8]
    * [![pub package](https://img.shields.io/pub/v/dart_json_mapper_flutter.svg)](https://pub.dev/packages/dart_json_mapper_flutter) | [dart_json_mapper_flutter](adapters/flutter) | [Flutter][11]

## Basic setup

Please add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  dart_json_mapper:
dev_dependencies:
  build_runner:
  dart_json_mapper_builder:
```

Say, you have a dart program *main.dart* having some classes intended to be traveling to JSON and back.
- First thing you should do is to put `@jsonSerializable` annotation on each of those classes
- Next step is to auto generate *main.mapper.g.dart* file. And afterwards import that file into *main.dart*

**lib/main.dart**
```dart
import 'package:dart_json_mapper/dart_json_mapper.dart'
    show JsonMapper, jsonSerializable, JsonProperty;

import 'main.mapper.g.dart' show initializeJsonMapper;

@jsonSerializable
class MyData {
  final int a;
  @JsonProperty(name: 'd')
  final String c;

  @JsonProperty(ignore: true)
  final bool b;

  const MyData({required this.a, required this.b, required this.c});
}

void main() {
  initializeJsonMapper();

  final myData = MyData(a: 456, b: true, c: 'yes');
  final json = JsonMapper.serialize(myData);

  print(json);
}
```
Output:
```json
{"a":456,"d":"yes"}
```

Go ahead and create / update `build.yaml` file in your project root directory with the following snippet:

```yaml
targets:
  $default:
    builders:
      dart_json_mapper:
        generate_for:
          # In this example, we want to generate code for all files in the `lib` directory.
          - lib/**.dart

      # dart_json_mapper is a wrapper around the reflectable builder.
      # This configuration is needed to prevent the original reflectable builder from running.
      reflectable:
        generate_for:
          - no/files
```

Now run the code generation step with the root of your package as the current directory:

```shell
dart run build_runner build --delete-conflicting-outputs
```

**You'll need to re-run code generation each time you are making changes to `lib/main.dart`**
So for development time, use `watch` like this:

```shell
dart run build_runner watch --delete-conflicting-outputs
```

Each time you modify your project code, all `*.mapper.g.dart` files will be updated as well.
- Next step is to add `*.mapper.g.dart` to your .gitignore
- And this is it, you are all set and ready to go. Happy coding!

## Format DateTime / num types

In order to format `DateTime` or `num` instance as a JSON string, it is possible to
provide [intl][2] based formatting patterns.

**DateTime**
```dart
@jsonSerializable
class MyDates {
  @JsonProperty(converterParams: {'format': 'MM-dd-yyyy H:m:s'})
  final DateTime lastPromotionDate;

  @JsonProperty(converterParams: {'format': 'MM/dd/yyyy'})
  final DateTime hireDate;

  const MyDates({required this.lastPromotionDate, required this.hireDate});
}
```
Output:
```json
{"lastPromotionDate":"05-13-2008 22:33:44","hireDate":"02/28/2003"}
```

**num**
```dart
@jsonSerializable
class MyNumbers {
  @JsonProperty(converterParams: {'format': '##.##'})
  final num salary;

  const MyNumbers({required this.salary});
}
```
Output:
```json
{"salary":"1200000.25"}
```

As well, it is possible to utilize `converterParams` map to provide custom
parameters to your [custom converters](#custom-types).

## Get or Set fields

When relying on Dart `getters / setters`, no need to annotate them. But when you have custom `getter / setter` methods, you should provide annotations for them.

```dart
@jsonSerializable
class AllPrivateFields {
  String? _name;
  String? _lastName;

  set name(dynamic value) {
    _name = value;
  }

  String? get name => _name;

  @JsonProperty(name: 'lastName')
  void setLastName(dynamic value) {
    _lastName = value;
  }

  @JsonProperty(name: 'lastName')
  String? getLastName() => _lastName;
}
```

## Example with immutable class

```dart
@jsonSerializable
enum Color { red, blue, green, brown, yellow, black, white }

@jsonSerializable
class Car {
  @JsonProperty(name: 'modelName')
  final String model;
  final Color color;

  @JsonProperty(ignore: true)
  final Car? replacement;

  const Car({required this.model, required this.color, this.replacement});
}

@jsonSerializable
class Immutable {
  final int id;
  final String name;
  final Car car;

  const Immutable({required this.id, required this.name, required this.car});
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

Due to Dart's limitations with reflection, deserializing generic iterable types like `List<T>` or `Set<T>` requires special handling. This library offers several ways to manage this, from automatic code generation to manual configuration.

### Automatic Deserialization with the Builder

The recommended approach is to let the builder handle iterable deserialization automatically. The builder scans your code and generates the necessary value decorator functions for all annotated public classes. This means that for most common cases, like `List<Car>` or `Set<Car>`, you don't need to do anything extra.

```dart
final json = '[{"modelName": "Audi", "color": "green"}]';
final myCarsList = JsonMapper.deserialize<List<Car>>(json);
final myCarsSet = JsonMapper.deserialize<Set<Car>>(json);
```

For custom iterable types like `HashSet<Car>` or `UnmodifiableListView<Car>`, you can configure the [Builder](#builder) to support them.

### Pre-initialized Iterables

If you can pre-initialize your iterables with an empty instance, you don't need to worry about value decorators at all.

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
expect(target.list.length, 2);
expect(target.set, TypeMatcher<Set<Item>>());
expect(target.set.length, 2);
```

### Manual Value Decorator Functions

For more complex scenarios, you can provide value decorator functions manually, either globally or on a per-class basis.

* **Global Adapter**:

```dart
JsonMapper().useAdapter(JsonMapperAdapter(
  valueDecorators: {
    typeOf<List<Car>>(): (value) => value.cast<Car>(),
    typeOf<Set<Car>>(): (value) => value.cast<Car>()
  })
);

final json = '[{"modelName": "Audi", "color": "green"}]';
final myCarsList = JsonMapper.deserialize<List<Car>>(json);
final myCarsSet = JsonMapper.deserialize<Set<Car>>(json);
```

* **Inline in a Class**:

```dart
@jsonSerializable
@Json(valueDecorators: CarsContainer.valueDecorators)
class CarsContainer {
  static Map<Type, ValueDecoratorFunction> valueDecorators() =>
      {
        typeOf<List<Car>>(): (value) => value.cast<Car>(),
        typeOf<Set<Car>>(): (value) => value.cast<Car>()
      };

  List<Car> myCarsList;
  Set<Car> myCarsSet;
}
```

### Nested Lists

Using value decorators, it's possible to configure nested lists of virtually any depth.

```dart
@jsonSerializable
class Item {}

@jsonSerializable
@Json(valueDecorators: ListOfLists.valueDecorators)
class ListOfLists {
  static Map<Type, ValueDecoratorFunction> valueDecorators() =>
      {
        typeOf<List<List<Item>>>(): (value) => value.cast<List<Item>>(),
        typeOf<List<Item>>(): (value) => value.cast<Item>()
      };
  
  List<List<Item>>? lists;
}

// given
final json = '''{
 "lists": [
   [{}, {}],
   [{}, {}, {}]
 ]
}''';

// when
final target = JsonMapper.deserialize<ListOfLists>(json)!;

// then
expect(target.lists?.length, 2);
```

## Enum types

This library provides full support for enums, whether they are part of your codebase or from a third-party package.

### Your Own Enums

If the enum is part of your project, you can make it serializable by adding the `@jsonSerializable` annotation.

```dart
@jsonSerializable
enum Color { red, blue, green, brown, yellow, black, white }
```

### Third-Party Enums

If you need to serialize an enum from a third-party package, you can register it using an adapter.

```dart
import 'package:some_package' show ThirdPartyEnum;

JsonMapper().useAdapter(
    JsonMapperAdapter(enumValues: {
        ThirdPartyEnum: ThirdPartyEnum.values,
    })
);
```

### Enum Converters

This library provides three built-in enum converters:

- `enumConverterShort`: Produces short string values (e.g., `"red"`, `"blue"`). This is the default.
- `enumConverter`: Produces fully qualified string values (e.g., `"Color.red"`, `"Color.blue"`).
- `enumConverterNumeric`: Produces numeric values (e.g., `0`, `1`).

You can change the default converter globally like this:

```dart
// lib/main.dart
void main() {
  initializeJsonMapper(adapters: [
   JsonMapperAdapter(converters: {Enum: enumConverter})
  ]);
}
```

### Enums with Custom Values

You can map enums to custom `String` or `num` values by providing a `mapping` and an optional `defaultValue` when registering the enum.

```dart
import 'package:some_package' show ThirdPartyEnum;

JsonMapper().useAdapter(
    JsonMapperAdapter(enumValues: {
       ThirdPartyEnum: EnumDescriptor(
                            values: ThirdPartyEnum.values,
                      defaultValue: ThirdPartyEnum.A,
                           mapping: <ThirdPartyEnum, dynamic>{
                                      ThirdPartyEnum.A: 'AAA',
                                      ThirdPartyEnum.B: 123,
                                      ThirdPartyEnum.C: true
                                    }
                        )
    })
);
```

## Inherited classes derived from abstract / base class

Please use complementary `@Json(discriminatorProperty: 'type')` annotation for **abstract or base** class
to specify which class field(`type` in this snippet below) will be used to store a value for distinguishing concrete subclass type.

Please use complementary `@Json(discriminatorValue: <your property value>)` annotation for **subclasses**
derived from abstract or base class. If this annotation omitted, **class name** will be used as `discriminatorValue`

This ensures, that _dart-json-mapper_ will be able to reconstruct the object with the proper type during deserialization process.

```dart
@jsonSerializable
enum BusinessType { Private, Public }

@jsonSerializable
@Json(discriminatorProperty: 'type')
abstract class Business {
  String? name;
  BusinessType? type;
}

@jsonSerializable
@Json(discriminatorValue: BusinessType.Private)
class Hotel extends Business {
  int stars;

  Hotel(this.stars);
}

@jsonSerializable
@Json(discriminatorValue: BusinessType.Public)
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

## Classes enhanced with Mixins derived from abstract class

Similar configuration as above also works well for class mixins

```dart
@Json(discriminatorProperty: 'type')
@jsonSerializable
abstract class A {}

@jsonSerializable
mixin B on A {}

@jsonSerializable
class C extends A with B {}

@jsonSerializable
class MixinContainer {
  final Set<int> ints;
  final B b;

  const MixinContainer(this.ints, this.b);
}

// given
final json = r'''{"ints":[1,2,3],"b":{"type":"C"}}''';
final instance = MixinContainer({1, 2, 3}, C());

// when
final targetJson = JsonMapper.serialize(instance);
final target = JsonMapper.deserialize<MixinContainer>(targetJson);

// then
expect(targetJson, json);
expect(target, TypeMatcher<MixinContainer>());
expect(target.b, TypeMatcher<C>());
```

## Serialization template

In case you already have an instance of huge JSON Map object
and portion of it needs to be surgically updated, then you can pass
your `Map<String, dynamic>` instance as a `template` parameter for
`SerializationOptions`

```dart
// given
final template = {'a': 'a', 'b': true};

// when
final json = JsonMapper.serialize(Car('Tesla S3', Color.black),
  SerializationOptions(indent: '', template: template));

// then
expect(json,
  '''{"a":"a","b":true,"modelName":"Tesla S3","color":"black"}''');
```

## Deserialization template

In case you need to deserialize specific `Map<K, V>` type then you can pass
typed instance of it as a `template` parameter for `DeserializationOptions`.

Since typed `Map<K, V>` instance cannot be created dynamically due to Dart
language nature, so you are providing ready made instance to use for deserialization output.

```dart
// given
final json = '{"black":1,"blue":2}';

// when
final target = JsonMapper.deserialize(
          json, DeserializationOptions(template: <Color, int>{}));

// then
expect(target, TypeMatcher<Map<Color, int>>());
expect(target.containsKey(Color.black), true);
expect(target.containsKey(Color.blue), true);
expect(target[Color.black], 1);
expect(target[Color.blue], 2);
```

## Name casing styles [Pascal, Kebab, Snake, SnakeAllCaps]

Assuming your Dart code is following [Camel case style][9], but that is not 
always `true` for JSON models, they could follow 
[one of those popular - Pascal, Kebab, Snake, SnakeAllCaps][10] styles, right? 

That's why we need a smart way to manage that, instead of
hand coding each property using `@JsonProperty(name: ...)` it is possible to pass
`CaseStyle` parameter to serialization / deserialization methods OR specify this
preference on a class level using `@Json(caseStyle: CaseStyle.kebab)`.

```dart
@jsonSerializable
enum Color { red, blue, gray, grayMetallic, green, brown, yellow, black, white }

@jsonSerializable
@Json(caseStyle: CaseStyle.kebab)
class NameCaseObject {
  String mainTitle;
  bool hasMainProperty;
  Color primaryColor;

  NameCaseObject({
      this.mainTitle,
      this.hasMainProperty,
      this.primaryColor = Color.grayMetallic});
}

/// Serialization

// given
final instance = NameCaseObject(mainTitle: 'title', hasMainProperty: true);
// when
final json = JsonMapper.serialize(instance, SerializationOptions(indent: ''));
// then
expect(json, '''{"main-title":"title","has-main-property":true,"primary-color":"gray-metallic"}''');

/// Deserialization

// given
final json = '''{"main-title":"title","has-main-property":true,"primary-color":"gray-metallic"}''';
// when
final instance = JsonMapper.deserialize<NameCaseObject>(json);
// then
expect(instance.mainTitle, 'title');
expect(instance.hasMainProperty, true);
expect(instance.primaryColor, Color.grayMetallic);
```

## Nesting configuration

In case if you need to operate on particular portions of huge JSON object and 
you don't have a true desire to reconstruct the same deep nested JSON objects 
hierarchy with corresponding Dart classes. This section is for you!

Say, you have a json similar to this one:
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

And with code similar to this one:

```dart
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

## Relative path reference to parent field from nested object "../id"

When it's handy to refer to the parent fields values, it's possible to use path like notation "../"

```json
[
  {"id":1,"name":"category1","products":[
         {"id":3629,"name":"Apple","features":[{"id":9,"name":"Red Color"}]},
         {"id":5674,"name":"Banana"}]},
  {"id":2,"name":"category2","products":[
         {"id":7834,"name":"Car"},
         {"id":2386,"name":"Truck"}
   ]}
]
```

```dart
@jsonSerializable
class Feature {
  @JsonProperty(name: '../../id')
  num categoryId;

  @JsonProperty(name: '../id')
  num productId;

  num id;
  String name;

  Feature({this.name, this.id});
}

@jsonSerializable
class Product {
  @JsonProperty(name: '../id')
  num categoryId;

  num id;
  String name;

  @JsonProperty(ignoreIfNull: true)
  List<Feature> features;

  Product({this.name, this.id, this.features});
}

@jsonSerializable
class ProductCategory {
  num id;
  String name;
  List<Product> products;

  ProductCategory({this.id, this.name, this.products});
}
```

### Relative path reference to parent itself from nested object ".."

In some cases objects need to interact with their (owning) parent object. The easiest pattern is to
add a referencing field for the parent which is initialized during construction of the child object. 
The path notation ".." supports this pattern:

```dart
@jsonSerializable
class Parent {
  String? lastName;
  List<Child> children = [];
}

@jsonSerializable
class Child {
  String? firstName;

  @JsonProperty(name: '..')
  Parent parent;

  Child(this.parent);
}
```

You are now able to deserialize the following structure:

```json
{
  "lastName": "Doe",
  "children": [
    {"firstName": "Eve"},
    {"firstName": "Bob"},
    {"firstName": "Alice"}
]}
```

and each `Child` object will have a reference on it's parent. And this parent field will not leak out
to the serialized JSON object

## Value injection

Sometimes you have to *inject* certain values residing outside of a JSON string into the target
deserialized object. Using the `JsonProperty.inject` flag, one may do so.

```dart
class Outside {}

@jsonSerializable
class Inside {
  String? foo;

  @JsonProperty(name: 'data/instance', inject: true)
  Outside? outside;
}
```

You may then inject the values in the `deserialize` method:

```json
{
  "foo": "Bar"
}
```

```dart
Outside outsideInstance = Outside();
final target = JsonMapper.deserialize<Inside>(json,
  DeserializationOptions(injectableValues: {'data': {'instance': outsideInstance}})!;
```

## Name aliases configuration

For cases when aliasing technique is desired, it's possible to optionally merge / route *many* json properties
into *one* class field. First name from the list is treated as *primary* i.e. used for serialization
direction. The rest of items are treated as aliases joined by the `??` operation.

```dart
@jsonSerializable
class FieldAliasObject {
  // same as => alias ?? fullName ?? name
  @JsonProperty(name: ['alias', 'fullName', 'name'])
  final String name;

  const FieldAliasObject({
    this.name,
  });
}
```

## Schemes

Scheme - is a set of annotations associated with common scheme id.
This enables the possibility to map a **single** Dart class to **many** different JSON structures.

This approach usually useful for distinguishing [DEV, PROD, TEST, ...] environments, w/o producing separate 
Dart classes for each environment.  

```dart
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

## Objects flattening

Consider a paginated API which returns a page of results along with pagination metadata that
identifies how many results were requested, how far into the total set of results we are looking at,
and how many results exist in total. If we are paging through a total of 1053 results 100 at a time,
the third page may look like this:

```json
{
  "limit": 100,
  "offset": 200,
  "total": 1053,
  "users": [
    {"id": "49824073-979f-4814-be10-5ea416ee1c2f", "username": "john_doe"},
    ...
  ]
}
```

This same scheme with `limit` and `offset` and `total` fields may be shared across lots of different API queries.
For example we may want paginated results when querying for users, for issues, for projects, etc.

In this case it can be convenient to factor the common pagination metadata fields into a
reusable `Pagination` shared class that can be flattened & blended into each API response object.

```dart
@jsonSerializable
class Pagination {
  num? limit;
  num? offset;
  num? total;
}

@jsonSerializable
class UsersPage {
  @JsonProperty(flatten: true)
  Pagination? pagination;

  List<User>? users;
}
```

If it's desired to define common prefix for flattened fields
`@JsonProperty.name` attribute could be utilized for that alongside with `flatten: true` attribute.

Case style could be defined as usual, on a class level `@Json(caseStyle: CaseStyle.snake)` and/or global scope
with `DeserializationOptions(caseStyle: CaseStyle.kebab)` and `SerializationOptions(caseStyle: CaseStyle.kebab)`
If omitted, `CaseStyle.camel` is used by default.

```dart
@jsonSerializable
class Pagination {
  num? limit;
  num? offset;
  num? total;
}

@jsonSerializable
@Json(caseStyle: CaseStyle.snake)
class UsersPage {
  @JsonProperty(name: 'pagination', flatten: true)
  Pagination? pagination;

  List<User>? users;
}
```

This will output:

```json
{
  "pagination_limit": 100,
  "pagination_offset": 200,
  "pagination_total": 1053,
  "users": [
    {"id": "49824073-979f-4814-be10-5ea416ee1c2f", "username": "john_doe"},
    ...
  ]
}
```

## Objects cloning

If you are wondering how to deep-clone Dart Objects, or even considering using libraries like [Freezed][15] to accomplish that, then this section will probably be useful for you.

### `clone()` / `copy()`

You can create a deep clone of an object using the `clone()` or `copy()` methods.

```dart
// given
final car = Car('Tesla S3', Color.black);

// when
final cloneCar = JsonMapper.copy(car);

// then
expect(cloneCar == car, false);
expect(cloneCar.color == car.color, true);
expect(cloneCar.model == car.model, true);
```

### `copyWith()`

You can also create a copy of an object with some properties overridden using the `copyWith()` method.

```dart
// given
final car = Car('Tesla S3', Color.black);

// when
final cloneCar = JsonMapper.copyWith(car, {'color': 'blue'}); // overriding Black by Blue

// then
expect(cloneCar == car, false);
expect(cloneCar.color, Color.blue);
expect(cloneCar.model, car.model);
```

### `mergeMaps()`

You can recursively merge two maps using the `mergeMaps()` method.

```dart
// given
final mapA = {'a': 1, 'b': {'c': 2}};
final mapB = {'b': {'d': 3}, 'e': 4};

// when
final mergedMap = JsonMapper.mergeMaps(mapA, mapB);

// then
expect(mergedMap, {'a': 1, 'b': {'c': 2, 'd': 3}, 'e': 4});
```

## Raw JSON string

It is possible to embed a raw JSON string into a target object without any extra quotes.
This could be useful for cases when you have a string field, that is already a valid JSON string.

```dart
@jsonSerializable
class RawBean {
    String? name;

    @JsonProperty(rawJson: true)
    String? json;

    RawBean(this.name, this.json);
}

final bean = RawBean('My bean', '{"attr":false}');
```

should produce:

```json
{
    "name":"My bean",
    "json":{
        "attr":false
    }
}
```

## Debugging

You can print out the current mapper configuration to the console using the `info()` method. This is useful for debugging issues with adapters.

```dart
JsonMapper().info();
```

## Custom types

For the very custom types, specific ones, or doesn't currently supported by this library, you can 
provide your own custom Converter class per each custom runtimeType.

```dart
/// Abstract class for custom converters implementations
abstract class ICustomConverter<T> {
  dynamic toJSON(T object, SerializationContext context);
  T fromJSON(dynamic jsonValue, DeserializationContext context);
}
```

All you need to get going with this, is to implement this abstract class:
 
```dart
class CustomStringConverter implements ICustomConverter<String> {
  const CustomStringConverter() : super();

  @override
  String fromJSON(dynamic jsonValue, DeserializationContext context) {
    return jsonValue;
  }

  @override
  dynamic toJSON(String object, SerializationContext context) {
    return '_${object}_';
  }
}
```

And register it afterwards, if you want to have it applied for **all** occurrences of specified type:

```dart
JsonMapper().useAdapter(JsonMapperAdapter(
  converters: {
    String: CustomStringConverter()
  })
);
```

OR use it individually on selected class fields, via `@JsonProperty` annotation:

```dart
@JsonProperty(converter: CustomStringConverter())
String title;
```

## Annotations

This library provides a set of annotations to control the serialization and deserialization process.

### `@jsonSerializable`

A **required** marker annotation for classes, mixins, or enums that you want to be serializable.

| Parameter | Description |
| --- | --- |
| **None** | This annotation has no parameters. |

### `@jsonConstructor`

An **optional** annotation to mark a specific constructor to be used for deserialization.

| Parameter | Description |
| --- | --- |
| `scheme` | A dynamic [Scheme](#schemes) marker to associate this meta information with a particular mapping scheme. |

### `@Json`

An **optional** annotation for class declarations that describes the mapping between a Dart object and a JSON object.

| Parameter | Description |
| --- | --- |
| `name` | Defines the [RFC 6901][rfc6901] JSON pointer that denotes the JSON object's root name/path to be used for mapping (e.g., `'foo'`, `'foo/bar/baz'`). |
| `caseStyle` | The case style to use for the JSON keys (e.g., `CaseStyle.snake`). |
| `discriminatorProperty` | Defines the class property to be used as a source of truth for discrimination logic in a hierarchy of inherited classes. |
| `discriminatorValue` | Defines a custom override value for the discriminator. |
| `valueDecorators` | Provides an inline way to specify a static function that returns a map of value decorators to support type casting for `Map<K, V>` and other generic iterables. |
| `ignoreNullMembers` | If `true`, `null` class members will be excluded from the serialization process. |
| `ignoreDefaultMembers` | If `true`, class members with default values will be excluded from the serialization process. |
| `processAnnotatedMembersOnly` | If `true`, only annotated class members will be processed. |
| `allowCircularReferences` | An `int` that allows a certain number of circular object references during serialization. |
| `scheme` | A dynamic [Scheme](#schemes) marker to associate this meta information with a particular mapping scheme. |

### `@JsonProperty`

An **optional** annotation for class members that describes the mapping of a JSON object property.

| Parameter | Description |
| --- | --- |
| `name` | Defines the [RFC 6901][rfc6901] JSON pointer that denotes the name/path/aliases to be used for property mapping relative to the class root nesting (e.g., `'foo'`, `['foo', 'bar']`, `'../foo'`). |
| `scheme` | A dynamic [Scheme](#schemes) marker to associate this meta information with a particular mapping scheme. |
| `converter` | Declares a custom converter instance to be used for the annotated field. |
| `converterParams` | A `Map` of parameters to be passed to the converter instance. |
| `flatten` | Declares the annotated field to be flattened and merged with the host object. |
| `notNull` | A `bool` that declares the annotated field as NOT NULL. |
| `required` | A `bool` that declares the annotated field as required. |
| `inject` | A `bool` that declares the annotated field value to be directly injected from `DeserializationOptions.injectableValues`. |
| `ignore` | A `bool` that declares the annotated field as ignored. |
| `ignoreForSerialization` | A `bool` that declares the annotated field as excluded from serialization. |
| `ignoreForDeserialization` | A `bool` that declares the annotated field as excluded from deserialization. |
| `ignoreIfNull` | A `bool` that declares the annotated field as ignored if its value is `null`. |
| `ignoreIfDefault` | A `bool` that declares the annotated field as ignored if its value is equal to the default. |
| `defaultValue` | Defines the field's default value. |

## Builder

This library introduces own builder used to pre-build Default adapter for your application code.
Technically, provided builder wraps the [reflectable][3] builder output and adds a bit more generated code to it.

Builder can be configured using `build.yaml` file at the root of your project.

```yaml
targets:
  $default:
    builders:
      # This part configures dart_json_mapper builder
      dart_json_mapper:
        options:
          iterables: List, Set, HashSet, UnmodifiableListView
        generate_for:
          - example/**.dart
          - test/_test.dart

      # This part is needed to tell original reflectable builder to stay away
      # it overrides default options for reflectable builder to an **empty** set of files
      reflectable:
        generate_for:
          - no/files
```

Primary mission for the builder at this point is to generate Iterables support for your custom classes.

Options:

```yaml
iterables: List, Set, HashSet, UnmodifiableListView
```

This option if omitted defaults to `List, Set` is used to configure a list of iterables you would like
to be supported for you out of the box. For example you have a `Car` class in your app and
would like to have `List<Car>` and `Set<Car>` support for deserialization, then you could omit this option.

And when you would like to have a deserialization support for other iterables like `HashSet<Car>, UnmodifiableListView<Car>`
you could add them to the list for this option.

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
    
    import 'main.mapper.g.dart' show initializeJsonMapper;
    
    @jsonSerializable
    class ColorfulItem {
      String name;
      Color color;
    
      ColorfulItem(this.name, this.color);
    }
    
    void main() {
      initializeJsonMapper(adapters: [flutterAdapter]);
      
      print(JsonMapper.serialize(
         ColorfulItem('Item 1', Color(0x003f4f5f))
      ));
    }
    ```
    Output:
    ```json
    {
      "name": "Item 1",
      "color": "#003F4F5F"
    }
    ```
    
### You can easily mix and combine several adapters using following one-liner: 

```dart
JsonMapper()
   .useAdapter(fixnumAdapter)
   .useAdapter(flutterAdapter)
   .useAdapter(mobXAdapter)
   .useAdapter(builtAdapter)
   .info(); // print out a list of used adapters to console
```

[1]: https://github.com/flutter/flutter/issues/1150
[2]: https://pub.dartlang.org/packages/intl
[3]: https://pub.dartlang.org/packages/reflectable
[4]: https://github.com/appvision-gmbh/json2typescript
[5]: https://github.com/serde-rs/serde
[6]: https://github.com/google/gson
[7]: https://github.com/mobxjs/mobx.dart
[8]: https://github.com/dart-lang/fixnum
[9]: https://en.wikipedia.org/wiki/Camel_case
[10]: https://medium.com/better-programming/string-case-styles-camel-pascal-snake-and-kebab-case-981407998841
[11]: https://github.com/flutter/flutter
[12]: https://www.baeldung.com/jackson-annotations
[13]: https://pub.dev/packages/build#implementing-your-own-builders
[14]: https://pub.dev/packages/super_enum
[15]: https://pub.dev/packages/freezed
[16]: https://pub.dev/packages/built_collection

[obfuscation]: https://flutter.dev/docs/deployment/obfuscate

[rfc6901]: https://tools.ietf.org/html/rfc6901

[docs]: https://pub.dev/documentation/dart_json_mapper/latest/dart_json_mapper/dart_json_mapper-library.html

## URI Conversion

You can easily convert a Dart object to a URI for a GET request using the `toUri` method. This is useful for building API clients.

```dart
@jsonSerializable
class SearchParams {
  String query;
  int limit;

  SearchParams(this.query, this.limit);
}

// given
final params = SearchParams('dart', 10);

// when
final uri = JsonMapper.toUri(getParams: params, baseUrl: 'https://api.example.com/search');

// then
expect(uri.toString(), 'https://api.example.com/search?query=dart&limit=10');
```

## Error Handling

This library defines a set of custom exception classes to help you handle errors during serialization and deserialization. All exceptions inherit from `JsonMapperError`. Here are some of the most common exceptions:

- `MissingAnnotationOnTypeError`: Thrown when you try to serialize or deserialize a class that is not annotated with `@jsonSerializable`.
- `FieldCannotBeNullError`: Thrown when a field that is marked as not-nullable is `null`.
- `FieldIsRequiredError`: Thrown when a required field is missing from the JSON.
- `CircularReferenceError`: Thrown when a circular reference is detected during serialization.
- `JsonMapperSubtypeError`: Thrown when the discriminator value for a subtype is not recognized.
- `CannotCreateInstanceError`: Thrown when an instance of a class cannot be created.

You can catch these exceptions to implement custom error handling logic in your application.

```dart
try {
  final user = JsonMapper.deserialize<User>('{"name": null}');
} on FieldCannotBeNullError catch (e) {
  print(e);
}
```

[ci-badge]: https://github.com/k-paxian/dart-json-mapper/workflows/Pipeline/badge.svg
[ci-badge-url]: https://github.com/k-paxian/dart-json-mapper/actions?query=workflow%3A%22Pipeline%22