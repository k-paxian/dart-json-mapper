part of json_mapper.test;

@jsonSerializable
class NavbarTab {
  final String icon;
  @JsonProperty(defaultValue: 'car')
  final String title;
  final bool on;
  NavbarTab({this.icon, this.title, this.on});
}

@jsonSerializable
@Json(valueDecorators: NavbarConfig.valueDecorators)
class NavbarConfig {
  static Map<Type, ValueDecoratorFunction> valueDecorators() => {
        typeOf<Map<String, NavbarTab>>(): (value) =>
            value.cast<String, NavbarTab>()
      };

  NavbarConfig(
      {this.tabs,
      this.activeColor,
      this.inactiveColor,
      this.backgroundColor,
      this.fontSize});

  final Map<String, NavbarTab> tabs;
  final String activeColor;
  final String inactiveColor;
  final String backgroundColor;
  final double fontSize;
}

@jsonSerializable
class NoticeItem {}

@Json(valueDecorators: NoticeList.valueDecorators)
@jsonSerializable
class NoticeList {
  static Map<Type, ValueDecoratorFunction> valueDecorators() =>
      {typeOf<List<NoticeItem>>(): (value) => value.cast<NoticeItem>()};

  final List<NoticeItem> list;

  const NoticeList(this.list);
}

@jsonSerializable
class TestChain extends _TestChain {}

@jsonSerializable
abstract class _TestChain {
  List<String> mailingList = <String>[];
}

@jsonSerializable
class Customer {
  @JsonProperty(name: 'Id')
  final int id;
  @JsonProperty(name: 'Name')
  final String name;

  const Customer(this.id, this.name);
}

@jsonSerializable
class ServiceOrderItemModel {
  @JsonProperty(name: 'Id')
  final int id;
  @JsonProperty(name: 'Sequence')
  final int sequence;
  @JsonProperty(name: 'Description')
  final String description;

  const ServiceOrderItemModel({this.id, this.sequence, this.description});
}

@jsonSerializable
class ServiceOrderModel {
  @JsonProperty(name: 'Id')
  int id;
  @JsonProperty(name: 'Number')
  int number;
  @JsonProperty(name: 'CustomerId')
  int customerId;
  @JsonProperty(name: 'Customer')
  Customer customer;
  @JsonProperty(name: 'ExpertId')
  int expertId;
  @JsonProperty(name: 'Start')
  DateTime start;
  @JsonProperty(name: 'Items')
  List<ServiceOrderItemModel> items;

  @JsonProperty(name: 'End')
  DateTime end;
  @JsonProperty(name: 'Resume')
  String resume;

  ServiceOrderModel({
    this.id,
    this.number,
    this.customerId,
    this.expertId,
    this.start,
    this.end,
    this.resume,
    this.customer,
    this.items,
  });
}

@jsonSerializable
class Item {}

@jsonSerializable
class ListOfLists {
  List<List<Item>> lists;
}

void testValueDecorators() {
  final carListJson = '[{"modelName":"Audi","color":"Color.Green"}]';
  final ordersListJson = '''[  
  {
    "Id": 96,
    "Number": 96,
    "CustomerId": 1,
    "Customer": {
      "Id": 1,
      "Name": "Xxxx",
      "Emails": [
        {
          "Id": 1,
          "Name": "Arthur",
          "Address": "arthur@xxxx.com.br"
        },
        {
          "Id": 2,
          "Name": "Fernanda",
          "Address": "fernanda@xxxx.com.br"
        }
      ]
    },
    "ExpertId": 1,
    "Expert": {
      "Name": "Diego Garcia",
      "Title": "Diretor Técnico"
    },
    "Start": "2019-02-12T15:06:21.313144",
    "End": null,
    "Resume": null,
    "Items": []
  }
  ]''';
  final intListJson = '[1,3,5]';
  final iterableCarDecorator = (value) => value.cast<Car>();
  final iterableCustomerDecorator = (value) => value.cast<Customer>();

  group('[Verify value decorators]', () {
    test('Custom Map<K, V> decorator', () {
      // given
      final jsonMap = {
        'tabs': {
          'home': {'icon': '0xe800', 'title': 'Home', 'on': true},
          'sections': {'icon': '0xe801', 'on': true},
          'x': {'icon': '0xe801', 'title': null, 'on': true}
        },
        'active_color': null,
        'inactive_color': null,
        'background_color': null,
        'font_size': null
      };

      // when
      final target = JsonMapper.fromMap<NavbarConfig>(jsonMap);

      // then
      expect(target, TypeMatcher<NavbarConfig>());
      expect(target.tabs['home'].title, 'Home');
      expect(target.tabs['sections'].title, 'car');
      expect(target.tabs['x'].title, 'car');
    });

    test('Inherited List<String> property', () {
      // given
      final test = TestChain();
      test.mailingList.add('test12345@test.com');
      test.mailingList.add('test2222@test.com');
      test.mailingList.add('test33333@test.com');
      // when
      final json = JsonMapper.serialize(test, compactOptions);
      final instance = JsonMapper.deserialize<TestChain>(json);
      // then
      expect(json,
          '''{"mailingList":["test12345@test.com","test2222@test.com","test33333@test.com"]}''');
      expect(instance, TypeMatcher<TestChain>());
      expect(instance.mailingList.length, 3);
    });

    test('Set<int> / List<int> using default value decorators', () {
      // when
      final targetSet = JsonMapper.deserialize<Set<int>>(intListJson);
      final targetList = JsonMapper.deserialize<List<int>>(intListJson);

      // then
      expect(targetSet.length, 3);
      expect(targetSet.first, TypeMatcher<int>());
      expect(targetList.length, 3);
      expect(targetList.first, TypeMatcher<int>());
    });

    test('Inline value decorators', () {
      // when
      final target = JsonMapper.deserialize<NoticeList>('{"list":[{},{}]}');

      // then
      expect(target.list.first, TypeMatcher<NoticeItem>());
      expect(target.list.length, 2);
    });

    test('Custom Set<Car> value decorator', () {
      // given
      final set = <Car>{};
      set.add(Car('Audi', Color.Green));

      // when
      final json = JsonMapper.serialize(set, compactOptions);

      // then
      expect(json, carListJson);

      // given
      final adapter = JsonMapperAdapter(
          valueDecorators: {typeOf<Set<Car>>(): iterableCarDecorator});
      JsonMapper().useAdapter(adapter);

      // when
      final target = JsonMapper.deserialize<Set<Car>>(carListJson);

      // then
      expect(target.length, 1);
      expect(target.first, TypeMatcher<Car>());
      expect(target.first.model, 'Audi');
      expect(target.first.color, Color.Green);

      JsonMapper().removeAdapter(adapter);
    });

    test('Custom List<Car> value decorator', () {
      // given
      final adapter = JsonMapperAdapter(
          valueDecorators: {typeOf<List<Car>>(): iterableCarDecorator});
      JsonMapper().useAdapter(adapter);

      // when
      final target = JsonMapper.deserialize<List<Car>>(carListJson);

      // then
      expect(target.length, 1);
      expect(target[0], TypeMatcher<Car>());
      expect(target[0].model, 'Audi');
      expect(target[0].color, Color.Green);

      JsonMapper().removeAdapter(adapter);
    });

    test('Custom List<ServiceOrderModel> value decorator', () {
      // given
      final adapter = JsonMapperAdapter(valueDecorators: {
        typeOf<List<Customer>>(): iterableCustomerDecorator,
        typeOf<List<ServiceOrderModel>>(): (value) =>
            value.cast<ServiceOrderModel>(),
        typeOf<List<ServiceOrderItemModel>>(): (value) =>
            value.cast<ServiceOrderItemModel>()
      });
      JsonMapper().useAdapter(adapter);

      // when
      final target =
          JsonMapper.deserialize<List<ServiceOrderModel>>(ordersListJson);

      // then
      expect(target.length, 1);
      expect(target[0], TypeMatcher<ServiceOrderModel>());
      expect(target[0].id, 96);
      expect(target[0].expertId, 1);

      JsonMapper().removeAdapter(adapter);
    });

    test('List of Lists', () {
      // given
      final json = '''{
 "lists": [
   [{}, {}],
   [{}, {}, {}]
 ]
}''';
      final adapter = JsonMapperAdapter(valueDecorators: {
        typeOf<List<List<Item>>>(): (value) => value.cast<List<Item>>(),
        typeOf<List<Item>>(): (value) => value.cast<Item>()
      });
      JsonMapper().useAdapter(adapter);

      // when
      final target = JsonMapper.deserialize<ListOfLists>(json);

      // then
      expect(target.lists.length, 2);
      expect(target.lists.first.length, 2);
      expect(target.lists.last.length, 3);
      expect(target.lists.first.first, TypeMatcher<Item>());
      expect(target.lists.last.first, TypeMatcher<Item>());

      JsonMapper().removeAdapter(adapter);
    });
  });
}
