enum CaseStyle { camel, pascal, kebab, snake, snakeAllCaps }

String toWords(String input) => input
    .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}')
    .replaceAllMapped(RegExp('([A-Z])([A-Z])(?=[a-z])'),
        (match) => '${match.group(1)} ${match.group(2)}')
    .toLowerCase();

String capitalize(String input) => input.replaceFirstMapped(
    RegExp(r'(^|\s)[a-z]'), (match) => match.group(0)!.toUpperCase());

String? transformFieldName(String? input, CaseStyle? caseStyle) {
  switch (caseStyle) {
    case CaseStyle.kebab:
      return toWords(input!).replaceAll(' ', '-');
    case CaseStyle.snake:
      return toWords(input!).replaceAll(' ', '_');
    case CaseStyle.snakeAllCaps:
      return toWords(input!).replaceAll(' ', '_').toUpperCase();
    case CaseStyle.pascal:
      return toWords(input!).split(' ').map((word) => capitalize(word)).join();
    default:
      return input;
  }
}
