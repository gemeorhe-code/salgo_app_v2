String formatCOP(int amount) {
  final String digits = amount.toString();
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[i]);
  }
  return '\$${buffer.toString()}';
}

String formatMinutes(int minutes) {
  if (minutes < 60) {
    return '$minutes min';
  }
  final int hours = minutes ~/ 60;
  final int rest = minutes % 60;
  return rest == 0 ? '$hours h' : '$hours h $rest min';
}
