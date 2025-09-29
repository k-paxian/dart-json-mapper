import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:test/test.dart';

@jsonSerializable
class PageImpl<T> {
  List<T>? content;
  bool? last;
  int? totalPages;
  int? totalElements;
  bool? first;
  int? size;
  int? number;
  int? numberOfElements;
  bool? empty;
}

@jsonSerializable
class Advertising {
  String? title;
  double? price;
  int? quantity;
  String? description;
  List<String>? images;
  List<String>? sourceImages;
  String? sourceId;
  String? sourceUrl;
}

@jsonSerializable
class AdvertisingPage extends PageImpl<Advertising> {
  @override
  List<Advertising>? content = [];
}

void testIssue225() {
  group('Issue 225', () {
    test('should deserialize generic list correctly', () {
      const json = '''
      {
         "content":[
            {
               "id":25438,
               "created":"2024-07-04T18:46:31.048683Z",
               "updated":"2024-07-04T20:45:00.030320Z",
               "title":"SCOOTER HOVERBOARD BATERIA"
            }
         ],
         "last":false,
         "totalPages":23962,
         "totalElements":23962,
         "first":true,
         "size":1,
         "number":0,
         "numberOfElements":1,
         "empty":false
      }
      ''';
      final page = JsonMapper.deserialize<AdvertisingPage>(json);
      expect(page, isA<AdvertisingPage>());
      expect(page?.content, isA<List<Advertising>>());
      expect(page?.content?.first, isA<Advertising>());
      expect(page?.content?.first.title, 'SCOOTER HOVERBOARD BATERIA');
    });
  });
}