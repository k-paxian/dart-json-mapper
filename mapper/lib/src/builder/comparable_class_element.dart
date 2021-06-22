import 'package:analyzer/dart/element/element.dart';

class ComparableClassElement {
  ClassElement element;

  ComparableClassElement(this.element);

  String _elementsListAsString(Iterable<Element> list) =>
      list.map((element) => element.displayName).join('');

  @override
  bool operator ==(Object other) => hashCode == other.hashCode;

  @override
  String toString() {
    return element.displayName;
  }

  @override
  int get hashCode =>
      _elementsListAsString(element.accessors).hashCode +
      _elementsListAsString(element.methods).hashCode +
      _elementsListAsString(element.typeParameters).hashCode +
      _elementsListAsString(element.constructors).hashCode +
      _elementsListAsString(element.fields).hashCode;
}
