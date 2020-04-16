import 'dart:io' as io;
import 'package:test/test.dart';

void main() {
  test('Wrong number of arguments.', () {
    var result = io.Process.runSync('dart', ['bin/lakos.dart']);
    expect(result.stdout.toString().split('\n')[0].trim(),
        'Wrong number of arguments.');
    expect(result.exitCode, 1);
  });

  test('Invalid mode', () {
    var result = io.Process.runSync('dart', ['bin/lakos.dart', 'beast', '.']);
    expect(
        result.stdout.toString().split('\n')[0].trim(), 'Invalid mode: beast');
    expect(result.exitCode, 1);
  });
}
