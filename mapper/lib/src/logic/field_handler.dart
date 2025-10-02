import '../errors.dart';
import '../model/index.dart';

class FieldHandler {
  static bool isNullableField(JsonProperty? meta) =>
      !(JsonProperty.isRequired(meta) || JsonProperty.isNotNull(meta));

  static bool isFieldIgnored(
          [Json? classMeta,
          JsonProperty? meta,
          DeserializationOptions? options]) =>
      (meta != null &&
          (meta.ignore == true ||
              ((meta.ignoreForSerialization == true ||
                      JsonProperty.hasParentReference(meta) ||
                      meta.inject == true) &&
                  options is SerializationOptions) ||
              (meta.ignoreForDeserialization == true &&
                  options is! SerializationOptions)) &&
          isNullableField(meta));

  static bool isFieldIgnoredByDefault(
          JsonProperty? meta, Json? classMeta, SerializationOptions options) =>
      meta?.ignoreIfDefault == true ||
      classMeta?.ignoreDefaultMembers == true ||
      options.ignoreDefaultMembers == true;

  static bool isFieldIgnoredByValue(
          [dynamic value,
          Json? classMeta,
          JsonProperty? meta,
          DeserializationOptions? options]) =>
      ((meta != null &&
              (isFieldIgnored(classMeta, meta, options) ||
                  meta.ignoreIfNull == true && value == null)) ||
          (options is SerializationOptions &&
              (((options.ignoreNullMembers == true ||
                          classMeta?.ignoreNullMembers == true) &&
                      value == null) ||
                  ((isFieldIgnoredByDefault(meta, classMeta, options)) &&
                      JsonProperty.isDefaultValue(meta, value) == true)))) &&
      isNullableField(meta);

  static void checkFieldConstraints(dynamic value, String name,
      dynamic hasJsonProperty, JsonProperty? fieldMeta) {
    if (JsonProperty.isNotNull(fieldMeta) &&
        (hasJsonProperty == false || (value == null))) {
      throw FieldCannotBeNullError(name, message: fieldMeta!.notNullMessage);
    }
    if (hasJsonProperty == false && JsonProperty.isRequired(fieldMeta)) {
      throw FieldIsRequiredError(name, message: fieldMeta!.requiredMessage);
    }
  }
}