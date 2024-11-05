import 'package:dart_mail/dart_mail.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  test('calculate', () async {
    print(Directory.current);
    await driver('test/testdata.txt');
    expect(42, 42);
  });
}
