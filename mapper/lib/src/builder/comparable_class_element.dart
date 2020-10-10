import 'package:analyzer/dart/element/element.dart';

class ComparableClassElement {
  ClassElement element;

  ComparableClassElement(this.element);

  String _elementsListAsString(Iterable<Element> list) =>
      list.map((element) => element.displayName).join('');

  @override
  bool operator ==(Object other) {
    final otherElement = (other as ComparableClassElement).element;
    final cmp = (Iterable<Element> a, Iterable<Element> b) =>
        _elementsListAsString(a) == _elementsListAsString(b);

    final result = cmp(element.accessors, otherElement.accessors) &&
        cmp(element.fields, otherElement.fields) &&
        cmp(element.methods, otherElement.methods) &&
        cmp(element.typeParameters, otherElement.typeParameters) &&
        cmp(element.constructors, otherElement.constructors);

    return result;
  }

  @override
  String toString() {
    return element.displayName;
  }
}
