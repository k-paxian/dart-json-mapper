import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';

class LibraryVisitor extends RecursiveElementVisitor {
  Map<num, ClassElement> visitedPublicClassElements = {};
  Map<num, ClassElement> visitedPublicAnnotatedClassElements = {};
  Map<String, ImportElement> visitedImports = {};

  @override
  void visitImportElement(ImportElement element) {
    final importIdentifier = element.importedLibrary != null
        ? element.importedLibrary.identifier
        : null;
    if (importIdentifier != null &&
        !visitedImports.containsKey(importIdentifier) &&
        importIdentifier.startsWith('asset:')) {
      visitedImports.putIfAbsent(importIdentifier, () => element);
      element.importedLibrary.visitChildren(this);
    }
    super.visitImportElement(element);
  }

  @override
  void visitClassElement(ClassElement element) {
    if (!element.isPrivate &&
        !visitedPublicClassElements.containsKey(element.id)) {
      visitedPublicClassElements.putIfAbsent(element.id, () => element);
      if (element.metadata.isNotEmpty &&
          element.metadata.any((meta) =>
                  meta
                      .computeConstantValue()
                      .type
                      .getDisplayString(withNullability: false) ==
                  'JsonSerializable') !=
              null) {
        visitedPublicAnnotatedClassElements.putIfAbsent(
            element.id, () => element);
      }
    }
    super.visitClassElement(element);
  }
}
