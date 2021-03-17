import 'package:analyzer/dart/element/element.dart';

import 'comparable_class_element.dart';
import 'library_visitor.dart';

class ChangeAnalyzer {
  LibraryVisitor visitorA;
  LibraryVisitor? visitorB;

  ChangeAnalyzer(this.visitorA, this.visitorB);

  Map<String, ComparableClassElement> getClassesMap(
          Iterable<ClassElement> classes) =>
      classes.fold({}, (value, element) {
        value[element.getDisplayString(withNullability: false)] =
            ComparableClassElement(element);
        return value;
      });

  bool get hasChanges {
    final classElementsA = visitorA.visitedPublicAnnotatedClassElements;
    final classElementsB = visitorB!.visitedPublicAnnotatedClassElements;

    final annotatedClassesCountChanged =
        classElementsA.length != classElementsB.length;
    late var anyAnnotatedClassChanged;

    if (!annotatedClassesCountChanged) {
      final classesMapA = getClassesMap(classElementsA.values);
      final classesMapB = getClassesMap(classElementsB.values);
      anyAnnotatedClassChanged = classesMapA.keys
          .map((className) => classesMapA[className] != classesMapB[className])
          .fold(false, (dynamic value, element) => value || element);
    }

    return annotatedClassesCountChanged || anyAnnotatedClassChanged;
  }
}
