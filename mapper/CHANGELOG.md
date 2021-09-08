## 2.1.8

* Remove local model packages from `dev_dependencies` to avoid penalties from pub.dev scoring algorithm

## 2.1.7

* #155, (feat) Introduce modularization, i.e. multi project setup is possible now. Model packages could be reused by different projects, flutter/web/etc.

## 2.1.6

* #150, (feat) Introduce `@JsonProperty.ignoreIfDefault` & `@Json.ignoreDefaultMembers`
* #152, (fix) Nullable list throws exception on being serialized when null

## 2.1.5

* (feat) Treat `ignoreForSerialization: true` by default when parent ".." is referenced OR field value is injected
* #147, (feat) Custom values injection during deserialization call

## 2.1.4

* #143, (fix) Unhandled Exception: type 'Null' is not a subtype of type 'Object'
* #144, (feat) Relative path reference to parent itself from nested object ".."

## 2.1.3

* replace `pedantic` linter by `lints` package
* Annotate annotations with the supported target types, to minimize incorrect usage.

## 2.1.2

* #137, Support custom `Iterable` converter
* bump dart to 2.13

## 2.1.1

* #131, `@JsonProperty` annotation in superclass should be inherited for overriden getters
* `deserialize` method extended to accept json `String` or parsed json `Object`
* #133, #135, second pass for converter during deserialization has been removed, more speed for deserialization

## 2.1.0

* #128, Introduce `flatten` attribute to `@JsonProperty` meta
* #97, sound null safety

## 2.0.9

* #127, Proper support for positional constructor arguments

## 2.0.8

* #126, Inaccurate implementation for contexts comparison improved

## 2.0.7

* #125, Fix null collection case with value decorator
* #120, Support read only getters as discriminator property

## 2.0.6

* #121, Support deserialization from type variable

## 2.0.5

* #120, Support for subclass using a discriminator property `@Json(typeNameProperty)` => `@Json(discriminatorProperty)`
        For migration from old versions just replace all `typeNameProperty` by `discriminatorProperty`.
        Global option `DeserializationOptions.typeNameProperty` has been removed.

## 2.0.4

* improve pub score for static analysis

## 2.0.3

* improve pub score for static analysis

## 2.0.2

* update changelog

## 2.0.1

* add readme

## 2.0.0

* #97, null safety support

## 1.7.13

* #118, fix: Add defaultValue handling for `enumConverterNumeric`
* #77, fix: Flutter for Web: Dynamic call with too many arguments. Arguments: [Instance of 'NativeJavaScriptObject']

## 1.7.12

* #117, fix: Cached values from converters made more accurate in terms of different types

## 1.7.11

* #115, fix: Null pointer on Flutter AOT app build
* #114, introduce async init method `initializeJsonMapperAsync`

## 1.7.10

* #111, feat: Support for relative reference to parent field from nested object "../id"
* #112, feat: Introduce support for field aliases. `@JsonProperty(name: ['alias', 'fullName', 'name'])`
* #77, fix: Flutter for Web: Dynamic call with too many arguments

## 1.7.9

* #110, feat: Support for Enum `EnumDescriptor.defultValue` on unknown values during deserialization

## 1.7.8

* #108, #109, feat: Flags `JsonProperty.notNull` `JsonProperty.required` spanned over serialization / deserialization process consistently
* #110, feat: Support for `String` / `Num` Enum values mappings introduced

## 1.7.7

* #106, fix: Do not generate invalid code when there is no main entry point provided, in case of library package for instance.
* #107, fix: Unmapped properties contains inherited readonly entries with custom json name
* #108, feat: Introduced `JsonProperty.required` to mark field as mandatory to be present in the JSON payload
* #109, feat: Introduced `JsonProperty.notNull` to mark field as mandatory to be present in the JSON payload & cannot be NULL

## 1.7.6

* #104, fix: Custom converter results cache layer does not work as expected

## 1.7.5

* #103, feat: Mixins Deserialization support introduced

## 1.7.4

* #100, fix: Naming conflicts in generated file. Prefixes introduced

## 1.7.3

* #99, fix: builder crawling over exports statements improved

## 1.7.2

* #91, Enum values inherit CaseStyle from the parent serializable class or global option.
* #94, fix: Deserialization fails when using [enumConverterNumeric]

## 1.7.1

* **Breaking change** Custom converters contract changed. `JsonProperty` replaced by serialization/deserialization `context`. Allowing each custom converter instance to have diverse context information
* #90, Support deserialization to default enum value for unknown values

## 1.7.0

* **Breaking change** Enums handling changed, no more repetitive `@JsonProperty(enumValues: Color.values)`. Annotate local Enums and Register third party Enums once per application
* Issue #88 addressed. Refine imports in auto-generated `*.mapper.g.dart` so no name conflicts will be possible

## 1.6.5

* Introduced converters for `RegExp`, `Uri` types.
* Internal `JsonMapper` methods made private.
* Introduced cache layer on top of converters outputs, brings modest performance boost. #86.

## 1.6.4

* `enumConverterShort` is the default one for all Enums. More intuitive and compact.
* Attempt to fix #87. Crawling through local package sources for annotated classes.

## 1.6.3

* Improved incremental builds speed. From now on code regeneration in a `watch mode` will be triggered only when annotated classes affected. Issue #81 addressed.

## 1.6.2

* Fix incremental runs on builder

## 1.6.1

* Update docs, improve pub package score

## 1.6.0

* Own builder introduced, to support `List, Set, HashSet, UnmodifiableListView` iterables to slightly ease the pain
of manual adding value decorators per each model class. From now on, support for `List<T>, Set<T>` iterables will be
out of the box by default.
* `Duration` converter introduced

## 1.5.24

* Issue #82 proper fix, `@JsonProperty(ignoreForSerialization / ignoreForDeserialization)` flags introduced to make your code more explicit and obvious

## 1.5.23

* Issue #82 resolved, Pick up annotation from constructor parameter

## 1.5.22

* Issue #80 resolved, Serialization template should be picked up from level 0 only

## 1.5.21

* Issue #79 resolved, `@Json(processAnnotatedMembersOnly: true)` introduced

## 1.5.20

* Issue #78 resolved, double @JsonConstructor with different Schemes

## 1.5.19

* Issue #75 resolved, double converter invocation omitted in case of fields intersection between constructor arguments and public class fields.

## 1.5.18

* Optional short Enum converter introduced. "Black" instead of "Color.Black"

## 1.5.17

* Performance **4x** improvement.

## 1.5.16

* `caseStyle` property introduced on `@Json` annotation, assign caseStyle on a class level

## 1.5.15

* #63, #66, `Map<Enum, CustomType>` support improved

## 1.5.14

* #65, `@JsonProperty.defaultValue` handling bug fix

## 1.5.13

* #9, Map<K, V> support improved

## 1.5.12

* #64, Added support for class fields as of Map type having Enum as a Key or Value **AND initialized** via class constructor

## 1.5.11

* #60, Introduced ability to specify inline value decorators, complimentary to global registration as apart of an adapter

## 1.5.10

* #58, Introduced ability to customize default Enums converter via adapter.

## 1.5.9

* #53, Global serialization option `ignoreUnknownTypes` introduced as an alternative for Java Jackson's `@JsonIgnoreProperties(ignoreUnknown = true)`

## 1.5.8

* #47, Introduced support for `composition over inheritance`
using composition of `Generic<T>` with `T`.

## 1.5.7

* #49, Support for types `HashSet, HashMap, UnmodifiableListView, UnmodifiableMapView` as a subset of `dart:collection`

## 1.5.6

* #49, Enums support with Iterables(List, Set), Map enhanced.
* #49, Global option `typeNameProperty` introduced.
* #49, Global option `processAnnotatedMembersOnly` introduced.

## 1.5.5

* #47, Proper handling for annotated `Generics` classes.

## 1.5.4

* #46, Introduce default converter for Map<K, V>.

## 1.5.3

* Custom getter / setter methods support added.
* #41, Fix null pointer on Iterables processing.

## 1.5.2

* #36, Allow serialize same object instances same nesting level.  

## 1.5.1

* Adapters management improved. Easily extend & configure mapper capabilities via modular approach. 

## 1.5.0

* #34, Default Iterables converter introduced. 
Partial solution to avoid value decorators approach for the cases when
it is possible to pre-initialize Iterable field with an empty instance.

## 1.4.4

* #33, Provide default values for `@JsonProperty(defaultValue: ...)`
* #35, SerializationOptions enriched with global `ignoreNullMembers` flag 

## 1.4.3

* #32, Collect Unmapped Properties implemented

## 1.4.2

* #30, Support for RFC 6901 JSON pointer for mapping names/paths

## 1.4.1

* #29, List of Lists use case covered.

## 1.4.0

* Enhancement #21 implemented, support @JsonConstructor to pick appropriate 
constructor for deserialization.
* Enhancement #23 implemented, support for field names casing options for serialization. [Pascal, Kebab, Snake, SnakeAllCaps]

## 1.3.5

* fix for #28
* Enhancement #22 implemented, support @JsonProperty annotation on constructor params when there is no associated field.

## 1.3.4

* Bump reflectable dependency to the latest stable

## 1.3.3

* Fix issue #26

## 1.3.2

* Fix special A/B inception case for #25

## 1.3.1

* Imports refactored, from now on *everything* is imported from a single
`import 'package:dart_json_mapper/dart_json_mapper.dart';` instead of several imports

## 1.2.10

* Optional `template` parameter added to `SerializationOptions`. Allows to render JSON on top of existing template map object.

## 1.2.9

* Introduced possibility to specify number of allowed circular references `@Json(allowCircularReferences: 1)`   

## 1.2.8

* Schemes introduced. Scheme - is a set of meta annotations associated with common scheme id.
This enables the possibility to map *single* Dart class to *many* JSON structures.   

## 1.2.7

* adopt pedantic for code style lints

## 1.2.6

* Introduced deep nesting for property names

## 1.2.5

* Introduced clone util method. Clone Dart objects made simple!
* Introduced support for public getters-only serialization

## 1.2.4

* fix converter resolution logic

## 1.2.3

* Fixnum support extracted as a standalone adapter library

## 1.2.2

* proper fix for issue #20, support for complementary "adapter" libraries added

## 1.2.1

* fix for issue #20

## 1.2.0

* Improved configuration for class hierarchies processing. [breaking change]
* fix for issues #19, #18

## 1.1.12

* A convenience toJson/fromJson methods introduced

## 1.1.11

* fix lint errors, update dependencies

## 1.1.10

* fix for issue #15

## 1.1.9

* proper fix for issue #9
* refactoring

## 1.1.8

* @JsonProperty.ignoreIfNull introduced, to skip null properties from processing

## 1.1.7

* Issues #10, #11 has been fixed

## 1.1.6

* Issue #9 has been fixed

## 1.1.5

* Map<String, dynamic> easing methods toMap/fromMap introduced.

## 1.1.4

* Issue #8 has been fixed

## 1.1.3

* Documented use case with Inherited classes derived from abstract / base class

## 1.1.2

* Issues #5, #6 has been fixed

## 1.1.1

* Issue #4 has been fixed

## 1.1.0

* Update build process, from now on relying on build_runner configured over build.yaml
* Issues #2, #3 has been fixed

## 1.0.9

* Added support for derived classes

## 1.0.8

* Fixnum types Int32, Int64 support added

## 1.0.7

* Iterable based types support enhanced

## 1.0.6

* Set based types support added

## 1.0.5

* Uint8List, BigInt types support added

## 1.0.4

* Value decorators support enhanced

## 1.0.3

* Value decorator introduced

## 1.0.2

* Added some docs
* Added test on ignored class field

## 1.0.1

* Improved Support for Map<K, V> type
* Added basic Support for dynamic type

## 1.0.0

* Positional constructor parameters support
* Support for Symbol, Map types
* More tests added

## 0.1.3

* Support Dart 2.0
* Support latest reflectable library changes
* Remove dependency on barback

## 0.1.2

* Converters registry introduced
* Error handling improved

## 0.1.1

* Converter auto detection based on field type
* Update pubspec for Dart 2.0

## 0.1.0

* Update readme
* Immutable classes serialization / deserialization support

## 0.0.9

* Tiny update to fix pubspec & readme

## 0.0.8

* Circular reference detection during serialization added

## 0.0.7

* Support Lists of Enums, Dates, Numbers etc.
* @JsonSerializable() => @jsonSerializable

## 0.0.6

* build & watch scripts added as a tooling for development time

## 0.0.5

* DateConverter & NumberConverter introduced
* Parameters for custom converter introduced

## 0.0.4

* Convert Enum values to string by default, to skip a disordered values drawback 
with indexed enum values.
* Enum's does not have to be annotated, since almost all of them are parts of 
third party libraries w/o access for modification.
* dateTimeConverter introduced

## 0.0.2

* Remove dependency on dart:mirrors.

## 0.0.0

* First published release.
