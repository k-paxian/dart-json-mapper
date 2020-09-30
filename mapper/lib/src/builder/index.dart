import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';

export 'builder.dart';

class MyVisitor extends RecursiveElementVisitor {
  @override
  void visitClassElement(ClassElement element) {
    print(element.name);
    print(element.library.identifier);
    super.visitClassElement(element);
  }
}

String wrapReflectableSource(
    LibraryElement inputLibrary, String reflectableGeneratedSource) {
  inputLibrary.visitChildren(MyVisitor());
  return reflectableGeneratedSource;
}
