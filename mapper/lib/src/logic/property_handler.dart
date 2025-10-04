import 'package:dart_json_mapper/src/model/index.dart';
import 'package:reflectable/reflectable.dart' show InstanceMirror, MethodMirror;

import '../class_info.dart';
import '../json_map.dart';
import '../mapper.dart';
import 'field_handler.dart';
import 'reflection_handler.dart';

class PropertyHandler {
  final JsonMapper _mapper;

  PropertyHandler(this._mapper);

  void enumeratePublicProperties(InstanceMirror instanceMirror,
      JsonMap? jsonMap, DeserializationContext context, Function visitor) {
    final classInfo = ClassInfo.fromCache(instanceMirror.type, _mapper.classes);
    final classMeta = classInfo.getMeta(context.options.scheme);

    for (var name in classInfo.publicFieldNames) {
      final declarationMirror = classInfo.getDeclarationMirror(name);
      if (declarationMirror == null) {
        continue;
      }
      final declarationType = ReflectionHandler.getDeclarationType(declarationMirror);
      final isGetterOnly = classInfo.isGetterOnly(name);
      final meta = classInfo.getDeclarationMeta(
          declarationMirror, context.options.scheme);
      if (meta == null &&
          Json.getProcessAnnotatedMembersOnly(classMeta, context.options) == true) {
        continue;
      }

      if (FieldHandler.isFieldIgnored(classMeta, meta, context.options)) {
        continue;
      }
      final propertyContext =
          context.reBuild(classMeta: classMeta, jsonPropertyMeta: meta);
      final property = resolveProperty(
          name, jsonMap, propertyContext, classMeta, meta, (name, jsonName, _) {
        var result = instanceMirror.invokeGetter(name);
        if (result == null && jsonMap != null) {
          result = jsonMap.getPropertyValue(jsonName);
        }
        return result;
      });

      FieldHandler.checkFieldConstraints(
          property.value, name, jsonMap?.hasProperty(property.name), meta);

      if (FieldHandler.isFieldIgnoredByValue(
          property.value, classMeta, meta, propertyContext.options)) {
        continue;
      }
      final typeInfo =
          _mapper.typeInfoHandler.getDeclarationTypeInfo(declarationType, property.value?.runtimeType);
      visitor(name, property, isGetterOnly, meta, _mapper.converterHandler.getConverter(meta, typeInfo),
          typeInfo);
    }

    classInfo.enumerateJsonGetters((MethodMirror mm, JsonProperty meta) {
      final declarationType = ReflectionHandler.getDeclarationType(mm);
      final propertyContext =
          context.reBuild(classMeta: classMeta, jsonPropertyMeta: meta);
      final property = resolveProperty(
          mm.simpleName, jsonMap, propertyContext, classMeta, meta,
          (name, jsonName, _) {
        var result = instanceMirror.invoke(name, []);
        if (result == null && jsonMap != null) {
          result = jsonMap.getPropertyValue(jsonName);
        }
        return result;
      });

      FieldHandler.checkFieldConstraints(property.value, mm.simpleName,
          jsonMap?.hasProperty(property.name), meta);
      if (FieldHandler.isFieldIgnoredByValue(
          property.value, classMeta, meta, context.options)) {
        return;
      }
      final typeInfo =
          _mapper.typeInfoHandler.getDeclarationTypeInfo(declarationType, property.value?.runtimeType);
      visitor(mm.simpleName, property, true, meta,
          _mapper.converterHandler.getConverter(meta, typeInfo), _mapper.typeInfoHandler.getTypeInfo(declarationType));
    }, context.options.scheme);
  }

  PropertyDescriptor resolveProperty(
      String name,
      JsonMap? jsonMap,
      DeserializationContext context,
      Json? classMeta,
      JsonProperty? meta,
      Function getValueByName) {
    String? jsonName = name;

    if (meta != null && meta.name != null) {
      jsonName = JsonProperty.getPrimaryName(meta);
    }
    jsonName = context.transformIdentifier(jsonName!);
    var value = getValueByName(name, jsonName, meta?.defaultValue);
    if (jsonMap != null &&
        meta != null &&
        (value == null || !jsonMap.hasProperty(jsonName))) {
      final initialValue = value;
      for (final alias in JsonProperty.getAliases(meta)!) {
        final targetJsonName = transformIdentifierCaseStyle(
            alias, context.targetCaseStyle, context.sourceCaseStyle);
        if (value != initialValue || !jsonMap.hasProperty(targetJsonName)) {
          continue;
        }
        jsonName = targetJsonName;
        value = jsonMap.getPropertyValue(jsonName);
      }
    }
    if (meta != null &&
        meta.inject == true &&
        context.options.injectableValues != null) {
      final injectionJsonMap = JsonMap(context.options.injectableValues!);
      if (injectionJsonMap.hasProperty(jsonName!)) {
        value = injectionJsonMap.getPropertyValue(jsonName);
        return PropertyDescriptor(jsonName, value, false);
      } else {
        return PropertyDescriptor(jsonName, null, false);
      }
    }
    if (jsonName == JsonProperty.parentReference) {
      return PropertyDescriptor(
          jsonName!, context.parentObjectInstances!.last, false);
    }
    if (value == null &&
        meta?.defaultValue != null &&
        FieldHandler.isFieldIgnoredByDefault(
            meta, classMeta, context.options as SerializationOptions)) {
      return PropertyDescriptor(jsonName!, meta?.defaultValue, true);
    }
    return PropertyDescriptor(jsonName!, value, true);
  }
}