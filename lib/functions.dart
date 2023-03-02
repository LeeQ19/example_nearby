import 'dart:math';

String getRandomString(int length) {
  const availableChars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final random = Random();
  final randomString = List.generate(length, (index) => availableChars[random.nextInt(availableChars.length)]).join();

  return randomString;
}
