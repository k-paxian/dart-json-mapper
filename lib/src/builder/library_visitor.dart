import 'package:analyzer/dart/element/element.dart';

import '../model/annotations.dart';

class LibraryVisitor {
  Map<num, ClassElement> visitedPublicClassElements = {};
  Map<num, ClassElement> visitedPublicAnnotatedClassElements = {};
  Map<num, EnumElement> visitedPublicAnnotatedEnumElements = {};
  Map<String, LibraryElement?> visitedLibraries = {};

  final _annotationClassName = jsonSerializable.runtimeType.toString();
  String? packageName;

  LibraryVisitor(this.packageName);

  List<InterfaceElement> get visitedPublicAnnotatedElements {
    return [
      ...visitedPublicAnnotatedClassElements.values,
      ...visitedPublicAnnotatedEnumElements.values
    ];
  }

  void visitLibraryExportElement(LibraryElement element) {
    visitLibrary(element);
  }

  void visitLibraryImportElement(LibraryElement element) {
    visitLibrary(element);
  }

  bool _hasAnnotation(Element element) {
    // Check annotations by iterating through element's metadata
    // Using a simple check to avoid issues with API changes
    try {
      final elementStr = element.toString();
      return elementStr.contains(_annotationClassName) || 
             elementStr.contains('@JsonSerializable') ||
             elementStr.contains('@jsonSerializable');
    } catch (e) {
      return false;
    }
  }

  void visitClassElement(ClassElement element) {
    if (!element.isPrivate &&
        !visitedPublicClassElements.containsKey(element.id)) {
      visitedPublicClassElements.putIfAbsent(element.id, () => element);
      if (_hasAnnotation(element)) {
        visitedPublicAnnotatedClassElements.putIfAbsent(
            element.id, () => element);
      }
    }
  }

  void visitEnumElement(EnumElement element) {
    if (!element.isPrivate &&
        !visitedPublicAnnotatedEnumElements.containsKey(element.id)) {
      visitedPublicAnnotatedEnumElements.putIfAbsent(element.id, () => element);
      if (_hasAnnotation(element)) {
        visitedPublicAnnotatedEnumElements.putIfAbsent(
            element.id, () => element);
      }
    }
  }

  void visitLibrary(LibraryElement? element) {
    if (element == null) return;
    
    final identifier = element.identifier;
    if (!visitedLibraries.containsKey(identifier) &&
        (identifier.startsWith('asset:') ||
            identifier.startsWith(packageName!))) {
      visitedLibraries.putIfAbsent(identifier, () => element);
      
      // Use reflection to access elements dynamically to handle API changes
      try {
        // Try to get topLevelElements via reflection or use known patterns
        // For now, we'll use a simplified approach that works with the public API
        
        // In analyzer 8.x, we need to use different approach
        // We'll iterate through what we can access
        final elementImpl = element as dynamic;
        
        // Try to access units or definingCompilationUnit
        try {
          final units = elementImpl.units as List<dynamic>?;
          if (units != null) {
            for (var unit in units) {
              for (var cls in (unit.classes as List<dynamic>)) {
                if (cls is ClassElement) visitClassElement(cls);
              }
              for (var enm in (unit.enums as List<dynamic>)) {
                if (enm is EnumElement) visitEnumElement(enm);
              }
            }
          }
        } catch (e) {
          // If units don't exist, try definingCompilationUnit
          try {
            final defUnit = elementImpl.definingCompilationUnit;
            for (var cls in (defUnit.classes as List<dynamic>)) {
              if (cls is ClassElement) visitClassElement(cls);
            }
            for (var enm in (defUnit.enums as List<dynamic>)) {
              if (enm is EnumElement) visitEnumElement(enm);
            }
          } catch (e2) {
            // Skip if unable to access
          }
        }
      } catch (e) {
        // Skip if unable to process
      }
    }
  }
}
