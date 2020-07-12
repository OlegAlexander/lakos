import 'dart:io';
import 'package:test/test.dart';
import 'package:lakos/build_model.dart';
import 'get_package_location.dart';

void main() {
  test('buildModel rootDir does not exist', () {
    try {
      buildModel(Directory('/i/dont/exist'));
    } catch (e) {
      expect(e, isA<FileSystemException>());
    }
  });

  test('buildModel pubspec.yaml not found', () {
    try {
      if (Platform.isWindows) {
        buildModel(Directory('C:/'));
      } else {
        buildModel(Directory('/'));
      }
    } catch (e) {
      expect(e, isA<PubspecYamlNotFoundException>());
    }
  });
}
