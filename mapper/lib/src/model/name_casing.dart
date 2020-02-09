enum CaseStyle { Camel, Pascal, Kebab, Snake, SnakeAllCaps }

String toWords(String input) => input
    .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}')
    .replaceAllMapped(RegExp('([A-Z])([A-Z])(?=[a-z])'),
        (match) => '${match.group(1)} ${match.group(2)}')
    .toLowerCase();

String capitalize(String input) => input.replaceFirstMapped(
    RegExp('(^|\s)[a-z]'), (match) => match.group(0).toUpperCase());

String transformFieldName(String input, CaseStyle caseStyle) {
  switch (caseStyle) {
    case CaseStyle.Kebab:
      return toWords(input).replaceAll(' ', '-');
    case CaseStyle.Snake:
      return toWords(input).replaceAll(' ', '_');
    case CaseStyle.SnakeAllCaps:
      return toWords(input).replaceAll(' ', '_').toUpperCase();
    case CaseStyle.Pascal:
      return toWords(input).split(' ').map((word) => capitalize(word)).join();
    default:
      return input;
  }
}
