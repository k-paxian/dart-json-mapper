import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';

import '../model/annotations.dart';

class LibraryVisitor extends RecursiveElementVisitor {
  Map<num, ClassElement> visitedPublicClassElements = {};
  Map<num, ClassElement> visitedPublicAnnotatedClassElements = {};
  Map<String, LibraryElement?> visitedLibraries = {};

  final _annotationClassName = jsonSerializable.runtimeType.toString();
  String? packageName;

  LibraryVisitor(this.packageName);

  @override
  void visitExportElement(ExportElement element) {
    _visitLibrary(element.exportedLibrary);
    super.visitExportElement(element);
  }

  @override
  void visitImportElement(ImportElement element) {
    _visitLibrary(element.importedLibrary);
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
                  .computeConstantValue()!
                  .type!
                  .getDisplayString(withNullability: false) ==
              _annotationClassName)) {
        visitedPublicAnnotatedClassElements.putIfAbsent(
            element.id, () => element);
      }
    }
    super.visitClassElement(element);
  }

  void _visitLibrary(LibraryElement? element) {
    final identifier = element?.identifier;
    if (identifier != null &&
        !visitedLibraries.containsKey(identifier) &&
        (identifier.startsWith('asset:') ||
            identifier.startsWith(packageName!))) {
      visitedLibraries.putIfAbsent(identifier, () => element);
      element!.visitChildren(this);
    }
  }
}
