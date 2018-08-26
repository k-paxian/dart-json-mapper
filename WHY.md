## Why is this library exists? 
`When there are so many alternatives out there`

It would be nice to have a Json serialization/deserialization library
* Compatible with all Dart platforms, including Flutter and Web platforms.
* No need to extend target classes from *any* mixins/base/abstract classes to keep code cleaner
* Clean and simple setup, transparent and straightforward usage with no heavy maintanance involved
* No extra boilerplate code involved
* Custom converters support per each target class field

But, as of today we have...

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
|[built_value][115]| yes |Over engineered solution, boilerplate, yes it's auto generated, but it is still boilerplate! enforces Immutability for all models, imply own patterns on your code base, too much responsibility in one library |


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
[115]: https://pub.dartlang.org/packages/built_value