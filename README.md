[![Build Status][ci-badge]][ci-badge-url]
[![pub package](https://img.shields.io/pub/v/dart_json_mapper.svg)](https://pub.dartlang.org/packages/dart_json_mapper)
[![Build Status][pedantic-badge]][pedantic-url]

This package allows programmers to annotate Dart objects in order to
  Serialize / Deserialize them to / from JSON.
  
## Why?

* Compatible with **all** Dart platforms, including [Flutter](https://pub.dartlang.org/flutter/packages) and [Web](https://pub.dartlang.org/web/packages) platforms
* No need to extend your classes from **any** mixins/base/abstract classes to keep code leaner
* Clean and simple setup, transparent and straight-forward usage with **no heavy maintenance**
* Inspired by [json2typescript][4], feature parity with highly popular [Java Jackson][12] and only **4** [annotations](#annotations) to remember to cover all possible use cases.
* **No extra boilerplate**, 100% generated code, which you'll *never* see.
* **Complementary adapters** full control over the process when you strive for maximum flexibility.
* **NO** dependency on `dart:mirrors`, one of the reasons is described [here][1].
* Because Serialization/Deserialization is **NOT** a responsibility of your Model classes.

Dart classes reflection mechanism is based on [reflectable][3] library. 
This means "extended types information" is auto-generated out of existing Dart program 
guided by the annotated classes **only**, as the result types information is accessible at runtime, at a reduced cost.


![](banner.svg)

* [Basic setup](#basic-setup)
* [Annotations](#annotations)
* [Builder](#builder)
* [Known limitations](#known-limitations)
* [Documentation][docs]
* [Configuration use cases](#format-datetime--num-types)
    * [Extended classes](#inherited-classes-derived-from-abstract--base-class)
    * [Classes with Mixins](#classes-enhanced-with-mixins-derived-from-abstract-class)
    * [Immutable classes](#example-with-immutable-class)
    * [Get or Set fields](#get-or-set-fields)
    * [Constructor parameters](#constructor-parameters)
    * [Unmapped properties](#unmapped-properties)
    * [DateTime / num types](#format-datetime--num-types)
    * [Iterable types](#iterable-types)
    * [Enum types](#enum-types)
    * [Enums having String / num values](#enums-having-string--num-values)
    * [Name casing styles](#name-casing-styles-pascal-kebab-snake-snakeallcaps)
    * [Serialization template](#serialization-template)
    * [Deserialization template](#deserialization-template)
    * [Custom types](#custom-types)
    * [Nesting](#nesting-configuration)
    * [Name aliases](#name-aliases-configuration)
    * [Schemes](#schemes)
    * [Objects cloning](#objects-cloning)
* [Adapters](#complementary-adapter-libraries)
    * [How to use adapter?](#complementary-adapter-libraries)
    * [![pub package](https://img.shields.io/pub/v/dart_json_mapper_built.svg)](https://pub.dartlang.org/packages/dart_json_mapper_built) | [dart_json_mapper_built](adapters/built) | [Built Collection][16]
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
- Next step is to auto generate *main.mapper.g.dart* file. And afterwards import that file into *main.dart*

**lib/main.dart**
```dart
import 'package:dart_json_mapper/dart_json_mapper.dart' show JsonMapper, jsonSerializable, JsonProperty;

import 'main.mapper.g.dart' show initializeJsonMapper;

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
  initializeJsonMapper();
  
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

Go ahead and create / update `build.yaml` file in your project root directory with the following snippet:

```yaml
targets:
  $default:
    builders:
      dart_json_mapper:
          generate_for:
          # here should be listed entry point files having 'void main()' function
            - lib/main.dart

      # This part is needed to tell original reflectable builder to stay away
      # it overrides default options for reflectable builder to an **empty** set of files
      reflectable:
        generate_for:
          - no/files
```

Now run the code generation step with the root of your package as the current directory:

```shell
> pub run build_runner build --delete-conflicting-outputs
```

**You'll need to re-run code generation each time you are making changes to `lib/main.dart`**
So for development time, use `watch` like this

```shell
> pub run build_runner watch --delete-conflicting-outputs
```

Each time you modify your project code, all `*.mapper.g.dart` files will be updated as well.
- Next step is to add `*.mapper.g.dart` to your .gitignore
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
@jsonSerializable
enum Color { Red, Blue, Green, Brown, Yellow, Black, White }

@jsonSerializable
class Car {
    @JsonProperty(name: 'modelName')
    String model;
    
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
  "color": "Green"
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

Basic iterable based generics using Dart built-in types like `List<num>, List<String>, List<bool>,
List<DateTime>, Set<num>, Set<String>, Set<bool>, Set<DateTime>, etc.` supported out of the box.

In order to do so, we'll use `Value Decorator Functions` inspired by Decorator pattern.

To solve this we have a few options:

### Provide value decorator functions manually

* As a global adapter
    ```dart
    JsonMapper().useAdapter(JsonMapperAdapter(
      valueDecorators: {
        typeOf<List<Car>>(): (value) => value.cast<Car>(),
        typeOf<Set<Car>>(): (value) => value.cast<Car>()
      })
    );
    
    final json = '[{"modelName": "Audi", "color": "Green"}]';
    final myCarsList = JsonMapper.deserialize<List<Car>>(json);
    final myCarsSet = JsonMapper.deserialize<Set<Car>>(json);
    ```

* As an class inline code
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

### Rely on builder to generate global adapter having value decorator functions automatically

Builder will scan project code during build pass and will generate value decorator functions for **all**
annotated public classes in advance.

For custom iterable types like `List<Car> / Set<Car>` we **don't** have to provide value decorators
as showed in a code snippet below, thanks to the [Builder](#builder)

```dart
final json = '[{"modelName": "Audi", "color": "Green"}]';
final myCarsList = JsonMapper.deserialize<List<Car>>(json);
final myCarsSet = JsonMapper.deserialize<Set<Car>>(json);
```

For custom iterable types like `HashSet<Car> / UnmodifiableListView<Car>` we should configure
[Builder](#builder) to support that.

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
@Json(valueDecorators: ListOfLists.valueDecorators)
class ListOfLists {
  static Map<Type, ValueDecoratorFunction> valueDecorators() =>
      {
        typeOf<List<List<Item>>>(): (value) => value.cast<List<Item>>(),
        typeOf<List<Item>>(): (value) => value.cast<Item>()
      };
  
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

    So whenever possible, you should annotate your Enum declarations as follows
    ```dart
    @jsonSerializable
    enum Color { Red, Blue, Green, Brown, Yellow, Black, White }
    ```

* Standalone Enums from third party packages, they **can not** be annotated.

    So you should register those enums via adapter as follows:
    ```dart
    import 'package:some_package' show ThirdPartyEnum, ThirdPartyEnum2;
    
    JsonMapper().useAdapter(
        JsonMapperAdapter(enumValues: {
            ThirdPartyEnum: ThirdPartyEnum.values,
            ThirdPartyEnum2: ThirdPartyEnum2.values
        })
    );
    ```
    
    Enum`.values` refers to a list of all possible enum values, it's a handy built in capability of all
    enum based types. Without providing all values it's not possible to traverse it's values properly.

There are few enum converters provided out of the box:

* `enumConverterShort` produces values like: ["Red", "Blue", "Green"], unless custom value mappings provided
* `enumConverter` produces values like: ["Color.Red", "Color.Blue", "Color.Green"]
* `enumConverterNumeric` produces values like: [0, 1, 2]

Default converter for **all** enums is `enumConverterShort`

In case we would like to make a switch **globally** to the different one, or even custom converter for all enums

```dart
// lib/main.dart
void main() {
  initializeJsonMapper(adapters: [
   JsonMapperAdapter(converters: {Enum: enumConverter})
  ]);
}
```

## Enums having `String` / `num` values

What are the options if you would like to serialize / deserialize Enum values as custom values?

* Wrap each enum as a class, to reflect it's values as something different
* Use other libraries for sealed classes like [SuperEnum][14], [Freezed][15]

OR

While registering standalone enums via adapter it is possible to specify value `mapping` for each enum,
alongside `defaultValue` which will be used during deserialization of _unknown_ Enum values.

```dart
import 'package:some_package' show ThirdPartyEnum, ThirdPartyEnum2, ThirdPartyEnum3;

JsonMapper().useAdapter(
    JsonMapperAdapter(enumValues: {
        ThirdPartyEnum: ThirdPartyEnum.values,
       ThirdPartyEnum2: EnumDescriptor(
                            values: ThirdPartyEnum2.values,
                           mapping: <ThirdPartyEnum2, String>{
                                      ThirdPartyEnum2.A: 'AAA',
                                      ThirdPartyEnum2.B: 'BBB',
                                      ThirdPartyEnum2.C: 'CCC'
                                    }
                        ),
       ThirdPartyEnum3: EnumDescriptor(
                            values: ThirdPartyEnum3.values,
                      defaultValue: ThirdPartyEnum3.A,
                           mapping: <ThirdPartyEnum3, num>{
                                      ThirdPartyEnum3.A: -1.2,
                                      ThirdPartyEnum3.B: 2323,
                                      ThirdPartyEnum3.C: 1.2344
                                    }
                        )
    })
);
```

So this way, you'll still operate on classic / pure Dart enums and with all that sending & receiving
them as mapped values. After registering those enums once, no matter where in the code you'll use them
later they will be handled according to the configuration given w/o annotating them beforehand.

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

## Classes enhanced with Mixins derived from abstract class

Similar configuration as above also works well for class mixins

```dart
@Json(typeNameProperty: 'type')
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
final json = JsonMapper.serialize(Car('Tesla S3', Color.Black),
  SerializationOptions(indent: '', template: template));

// then
expect(json,
  '''{"a":"a","b":true,"modelName":"Tesla S3","color":"Black"}''');
```

## Deserialization template

In case you need to deserialize specific `Map<K, V>` type then you can pass
typed instance of it as a `template` parameter for `DeserializationOptions`.

Since typed `Map<K, V>` instance cannot be created dynamically due to Dart
language nature, so you are providing ready made instance to use for deserialization output.

```dart
// given
final json = '{"Black":1,"Blue":2}';

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
`CaseStyle` parameter to serialization / deserialization methods OR specify this
preference on a class level using `@Json(caseStyle: CaseStyle.Kebab)`.

```dart
@jsonSerializable
enum Color { Red, Blue, Gray, GrayMetallic, Green, Brown, Yellow, Black, White }

@jsonSerializable
@Json(caseStyle: CaseStyle.Kebab)
class NameCaseObject {
  String mainTitle;
  bool hasMainProperty;
  Color primaryColor;

  NameCaseObject({
      this.mainTitle,
      this.hasMainProperty,
      this.primaryColor = Color.GrayMetallic});
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
expect(instance.primaryColor, Color.GrayMetallic);
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
  @JsonProperty(name: '../../id', ignoreForSerialization: true)
  num categoryId;

  @JsonProperty(name: '../id', ignoreForSerialization: true)
  num productId;

  num id;
  String name;

  Feature({this.name, this.id});
}

@jsonSerializable
class Product {
  @JsonProperty(name: '../id', ignoreForSerialization: true)
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

## Objects cloning

If you are wondering how to deep-clone Dart Objects,
or even considering using libraries like [Freezed][15] to accomplish that,
then this section probably will be useful for you

```dart
// given
final car = Car('Tesla S3', Color.Black);

// when
final cloneCar = JsonMapper.copy(car);

// then
expect(cloneCar == car, false);
expect(cloneCar.color == car.color, true);
expect(cloneCar.model == car.model, true);
```

Or if you would like to override some properties for the clonned object instance

```dart
// given
final car = Car('Tesla S3', Color.Black);

// when
final cloneCar = JsonMapper.copyWith(car, {'color': Color.Blue}); // overriding Black by Blue

// then
expect(cloneCar == car, false);
expect(cloneCar.color, Color.Blue);
expect(cloneCar.model, car.model);
```

## Custom types

For the very custom types, specific ones, or doesn't currently supported by this library, you can 
provide your own custom Converter class per each custom runtimeType.

```dart
/// Abstract class for custom converters implementations
abstract class ICustomConverter<T> {
  dynamic toJSON(T object, [SerializationContext context]);
  T fromJSON(dynamic jsonValue, [DeserializationContext context]);
}
```

All you need to get going with this, is to implement this abstract class
 
```dart
class CustomStringConverter implements ICustomConverter<String> {
  const CustomStringConverter() : super();

  @override
  String fromJSON(dynamic jsonValue, [DeserializationContext context]) {
    return jsonValue;
  }

  @override
  dynamic toJSON(String object, [SerializationContext context]) {
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
* `@Json(...)` It's an **optional** annotation for class or Enum declaration, describes a Dart object to JSON Object mapping.
Why it's not a `@JsonObject()`? just for you to type less characters :smile:
    * *name* Defines [RFC 6901][rfc6901] JSON pointer, denotes the json Object root name/path to be used for mapping.
Example: `'foo', 'bar', 'foo/bar/baz'`
    * *caseStyle* The most popular ways to combine words into a single string. Based on assumption: That all Dart class fields initially given as CaseStyle.Camel
    * *typeNameProperty* declares the necessity for annotated class and all it's subclasses to dump their own type name to
the property named as this param value
    * *valueDecorators* Provides an inline way to specify a static function which will return a Map of value decorators, to support type casting activities for Map<K, V>, and other generic Iterables<T> instead of global adapter approach
    * *ignoreNullMembers* If set to `true` Null class members will be excluded from serialization process
    * *processAnnotatedMembersOnly* If set to `true` Only annotated class members will be processed
    * *allowCircularReferences* As of `int` type. Allows certain number of circular object references during serialization.
    * *scheme* dynamic [Scheme](#schemes) marker to associate this meta information with particular mapping scheme
* `@JsonProperty(...)` It's an **optional** class member annotation, describes JSON Object property mapping.
    * *name* Defines [RFC 6901][rfc6901] JSON pointer, denotes the name/path/aliases to be used for property mapping relative to the class *root nesting*
Example: `'foo', 'bar', 'foo/bar/baz', ['foo', 'bar', 'baz'], '../foo/bar'`
    * *scheme* dynamic [Scheme](#schemes) marker to associate this meta information with particular mapping scheme
    * *converter* Declares custom converter instance, to be used for annotated field serialization / deserialization 
    * *converterParams* A `Map` of parameters to be passed to the converter instance
    * *notNull* A bool declares annotated field as NOT NULL for serialization / deserialization process
    * *required* A bool declares annotated field as required for serialization / deserialization process i.e. needs to be present explicitly
    * *ignore* A bool declares annotated field as ignored so it will be excluded from serialization / deserialization process
    * *ignoreForSerialization* A bool declares annotated field as excluded from serialization process
    * *ignoreForDeserialization* A bool declares annotated field as excluded from deserialization process
    * *ignoreIfNull* A bool declares annotated field as ignored if it's value is null so it will be excluded from serialization / deserialization process
    * *defaultValue* Defines field default value

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
    output:
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

[ci-badge]: https://github.com/k-paxian/dart-json-mapper/workflows/Pipeline/badge.svg
[ci-badge-url]: https://github.com/k-paxian/dart-json-mapper/actions?query=workflow%3A%22Pipeline%22

[pedantic-badge]: https://dart-lang.github.io/linter/lints/style-pedantic.svg
[pedantic-url]: https://github.com/dart-lang/pedantic
