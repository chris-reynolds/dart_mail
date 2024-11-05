import 'dart:io';
import 'package:dart_mail/dart_mail.dart' as dart_mail;

void main(List<String> arguments) async {
  if (arguments.length != 1) {
    stderr.write('Invalid Usage: dart_mail <filename>');
    exit(16);
  }
  await dart_mail.driver(arguments[0]);
}
