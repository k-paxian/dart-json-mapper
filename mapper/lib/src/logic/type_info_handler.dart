import 'package:collection/collection.dart' show IterableExtension;

import '../class_info.dart';
import '../mapper.dart';
import '../model/index.dart';

class TypeInfoHandler {
  final JsonMapper _mapper;

  TypeInfoHandler(this._mapper);

  TypeInfo getDeclarationTypeInfo(Type declarationType, Type? valueType) =>
      getTypeInfo((declarationType == dynamic && valueType != null)
          ? valueType
          : declarationType);

  TypeInfo getTypeInfo(Type type) {
    if (_mapper.typeInfoCache[type] != null) {
      return _mapper.typeInfoCache[type]!;
    }
    var result = TypeInfo(type);
    for (var decorator in _mapper.typeInfoDecorators.values) {
      decorator.init(_mapper.classes, _mapper.valueDecorators, _mapper.enumValues);
      result = decorator.decorate(result);
    }
    if (_mapper.mixins[result.typeName] != null) {
      result.mixinType = _mapper.mixins[result.typeName]!.reflectedType;
    }
    _mapper.typeInfoCache[type] = result;
    return result;
  }

  Type? getGenericParameterTypeByIndex(num parameterIndex, TypeInfo genericType) =>
      genericType.isGeneric &&
              genericType.parameters.length - 1 >= parameterIndex
          ? genericType.parameters.elementAt(parameterIndex as int)
          : null;

  Type? getTypeByStringName(String? typeName) =>
      _mapper.classes.keys.firstWhereOrNull((t) => t.toString() == typeName);

  String? getDiscriminatorProperty(
          ClassInfo classInfo, DeserializationOptions? options) =>
      classInfo
          .getMetaWhere((Json meta) => meta.discriminatorProperty != null,
              options?.scheme)
          ?.discriminatorProperty;
}