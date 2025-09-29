/// The most popular ways to combine multiple words as a single string
enum CaseStyle { camel, pascal, kebab, snake, snakeAllCaps }

/// Default case style when not specified explicitly
const defaultCaseStyle = CaseStyle.camel;

/// Converts [input] of certain [caseStyle] to List of words
List<String> toWords(String input, [CaseStyle? caseStyle = defaultCaseStyle]) {
  final effectiveCaseStyle = caseStyle ?? defaultCaseStyle;
  switch (effectiveCaseStyle) {
    case CaseStyle.snake:
    case CaseStyle.snakeAllCaps:
      return input.split('_');
    case CaseStyle.kebab:
      return input.split('-');
    case CaseStyle.pascal:
      if (input == input.toUpperCase()) {
        return [input];
      }
      return deCapitalize(input)
          .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'),
              (match) => '${match.group(1)} ${match.group(2)}')
          .replaceAllMapped(RegExp('([A-Z])([A-Z])(?=[a-z])'),
              (match) => '${match.group(1)} ${match.group(2)}')
          .toLowerCase()
          .split(' ');
    case CaseStyle.camel:
      if (input == input.toUpperCase()) {
        return [input];
      }
      return input
          .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'),
              (match) => '${match.group(1)} ${match.group(2)}')
          .replaceAllMapped(RegExp('([A-Z])([A-Z])(?=[a-z])'),
              (match) => '${match.group(1)} ${match.group(2)}')
          .toLowerCase()
          .split(' ');
    default:
      return input.split(' ');
  }
}

/// Omits leading words from [input] when they are equal to [prefix] words
String skipPrefix(String prefix, String input,
    [CaseStyle? caseStyle = defaultCaseStyle]) {
  final effectiveCaseStyle = caseStyle ?? defaultCaseStyle;
  final prefixWords = toWords(prefix, effectiveCaseStyle);
  final inputWords = toWords(input, effectiveCaseStyle);
  int index = -1;
  final result = inputWords.where((element) {
    index++;
    if (index < prefixWords.length) {
      return prefixWords[index] != element;
    }
    return true;
  });
  return transformIdentifierCaseStyle(result.join(' '), caseStyle, null);
}

String capitalize(String input) => input.replaceFirstMapped(
    RegExp(r'(^|\s)[a-z]'), (match) => match.group(0)!.toUpperCase());

String deCapitalize(String input) => input.replaceFirstMapped(
    RegExp(r'(^|\s)[A-Z]'), (match) => match.group(0)!.toLowerCase());

/// Transforms identifier from [sourceCaseStyle] to [targetCaseStyle]
String transformIdentifierCaseStyle(
    String source, CaseStyle? targetCaseStyle, CaseStyle? sourceCaseStyle) {
  if (sourceCaseStyle == targetCaseStyle) {
    return source;
  }
  switch (targetCaseStyle) {
    case CaseStyle.kebab:
      return toWords(source, sourceCaseStyle).join('-');
    case CaseStyle.snake:
      return toWords(source, sourceCaseStyle).join('_');
    case CaseStyle.snakeAllCaps:
      return toWords(source, sourceCaseStyle).join('_').toUpperCase();
    case CaseStyle.pascal:
      return toWords(source, sourceCaseStyle)
          .map((word) => capitalize(word))
          .join('');
    case CaseStyle.camel:
      return deCapitalize(toWords(source, sourceCaseStyle)
          .map((word) => word.toLowerCase())
          .map((e) => capitalize(e))
          .join(''));
    default:
      return source;
  }
}
