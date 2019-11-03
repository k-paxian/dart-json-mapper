part of json_mapper.test;

@JsonSerializable()
class Customer {
  @JsonProperty(name: 'Id')
  final int id;
  @JsonProperty(name: 'Name')
  final String name;

  const Customer(this.id, this.name);
}

@JsonSerializable()
class ServiceOrderItemModel {
  @JsonProperty(name: 'Id')
  final int id;
  @JsonProperty(name: 'Sequence')
  final int sequence;
  @JsonProperty(name: 'Description')
  final String description;

  const ServiceOrderItemModel({this.id, this.sequence, this.description});
}

@JsonSerializable()
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

testValueDecorators() {
  final String carListJson = '[{"modelName":"Audi","color":"Color.Green"}]';
  final String ordersListJson = '''[  
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
  final String intListJson = '[1,3,5]';
  final iterableCarDecorator = (value) => value.cast<Car>();
  final iterableCustomerDecorator = (value) => value.cast<Customer>();

  group("[Verify value decorators]", () {
    test("Set<int> / List<int> using default value decorators", () {
      // when
      Set<int> targetSet = JsonMapper.deserialize(intListJson);
      List<int> targetList = JsonMapper.deserialize(intListJson);

      // then
      expect(targetSet.length, 3);
      expect(targetSet.first, TypeMatcher<int>());
      expect(targetList.length, 3);
      expect(targetList.first, TypeMatcher<int>());
    });

    test("Custom Set<Car> value decorator", () {
      // given
      final Set<Car> set = Set<Car>();
      set.add(Car("Audi", Color.Green));

      // when
      String json = JsonMapper.serialize(set, '');

      // then
      expect(json, carListJson);

      // given
      JsonMapper.registerValueDecorator<Set<Car>>(iterableCarDecorator);

      // when
      Set<Car> target = JsonMapper.deserialize(carListJson);

      // then
      expect(target.length, 1);
      expect(target.first, TypeMatcher<Car>());
      expect(target.first.model, "Audi");
      expect(target.first.color, Color.Green);
    });

    test("Custom List<Car> value decorator", () {
      // given
      JsonMapper.registerValueDecorator<List<Car>>(iterableCarDecorator);

      // when
      List<Car> target = JsonMapper.deserialize(carListJson);

      // then
      expect(target.length, 1);
      expect(target[0], TypeMatcher<Car>());
      expect(target[0].model, "Audi");
      expect(target[0].color, Color.Green);
    });

    test("Custom List<ServiceOrderModel> value decorator", () {
      // given
      JsonMapper.registerValueDecorator<List<Customer>>(
          iterableCustomerDecorator);
      JsonMapper.registerValueDecorator<List<ServiceOrderModel>>(
          (value) => value.cast<ServiceOrderModel>());
      JsonMapper.registerValueDecorator<List<ServiceOrderItemModel>>(
          (value) => value.cast<ServiceOrderItemModel>());

      // when
      List<ServiceOrderModel> target = JsonMapper.deserialize(ordersListJson);

      // then
      expect(target.length, 1);
      expect(target[0], TypeMatcher<ServiceOrderModel>());
      expect(target[0].id, 96);
      expect(target[0].expertId, 1);
    });

    test(
        "Should dump typeName to json property when"
        " @Json(typeNameProperty: 'typeName')", () {
      // given
      final jack = Stakeholder("Jack", [Startup(10), Hotel(4)]);

      // when
      JsonMapper.registerValueDecorator<List<Business>>(
          (value) => value.cast<Business>());
      final String json = JsonMapper.serialize(jack);
      final Stakeholder target = JsonMapper.deserialize(json);

      // then
      expect(target.businesses[0], TypeMatcher<Startup>());
      expect(target.businesses[1], TypeMatcher<Hotel>());
    });
  });
}
