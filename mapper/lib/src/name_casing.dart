/// The most popular ways to combine multiple words as a single string
enum CaseStyle { camel, pascal, kebab, snake, snakeAllCaps }

/// Default case style when not specified explicitly
const defaultCaseStyle = CaseStyle.camel;

/// Converts [input] of certain [caseStyle] to words separated by single spaces
String toWords(String input, [CaseStyle? caseStyle = defaultCaseStyle]) {
  final effectiveCaseStyle = caseStyle ?? defaultCaseStyle;
  switch (effectiveCaseStyle) {
    case CaseStyle.snake:
    case CaseStyle.snakeAllCaps:
      return input.split('_').join(' ');
    case CaseStyle.kebab:
      return input.split('-').join(' ');
    case CaseStyle.pascal:
    case CaseStyle.camel:
      return input
          .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'),
              (match) => '${match.group(1)} ${match.group(2)}')
          .replaceAllMapped(RegExp('([A-Z])([A-Z])(?=[a-z])'),
              (match) => '${match.group(1)} ${match.group(2)}')
          .toLowerCase();
    default:
      return input;
  }
}

/// Omits leading words from [input] when they are equal to [prefix] words
String skipPrefix(String prefix, String input,
    [CaseStyle? caseStyle = defaultCaseStyle]) {
  final effectiveCaseStyle = caseStyle ?? defaultCaseStyle;
  final prefixWords = toWords(prefix, effectiveCaseStyle).split(' ');
  final inputWords = toWords(input, effectiveCaseStyle).split(' ');
  int index = -1;
  final result = inputWords.where((element) {
    index++;
    if (index < prefixWords.length) {
      return prefixWords[index] != element;
    }
    return true;
  });
  return transformFieldName(result.join(' '), caseStyle);
}

String capitalize(String input) => input.replaceFirstMapped(
    RegExp(r'(^|\s)[a-z]'), (match) => match.group(0)!.toUpperCase());

String deCapitalize(String input) => input.replaceFirstMapped(
    RegExp(r'(^|\s)[A-Z]'), (match) => match.group(0)!.toLowerCase());

/// Transforms identifier name from [sourceCaseStyle] to [targetCaseStyle]
String transformFieldName(String source, CaseStyle? targetCaseStyle,
    [CaseStyle sourceCaseStyle = defaultCaseStyle]) {
  switch (targetCaseStyle) {
    case CaseStyle.kebab:
      return toWords(source, sourceCaseStyle).replaceAll(' ', '-');
    case CaseStyle.snake:
      return toWords(source, sourceCaseStyle).replaceAll(' ', '_');
    case CaseStyle.snakeAllCaps:
      return toWords(source, sourceCaseStyle)
          .replaceAll(' ', '_')
          .toUpperCase();
    case CaseStyle.pascal:
      return toWords(source, sourceCaseStyle)
          .split(' ')
          .map((word) => capitalize(word))
          .join();
    case CaseStyle.camel:
      return deCapitalize(source.split(' ').map((e) => capitalize(e)).join(''));
    default:
      return source;
  }
}
