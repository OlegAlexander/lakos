// Conclusion: Don't use mirrors to parse the imports
// because it only works when a library is imported.
// Use analyzer to parse imports instead.

import 'package:test/test.dart';
import 'dart:mirrors' as mirrors;
import 'package:pub_cache/pub_cache.dart' deferred as pub_cache;

void main() {
  test('all libraries', () {
    var mirrorSystem = mirrors.currentMirrorSystem();
    for (var lib in mirrorSystem.libraries.keys) {
      print(lib);
    }
  });

  test('deferred loadLibrary', () {
    pub_cache.loadLibrary();
    var mirrorSystem = mirrors.currentMirrorSystem();
    var pubCacheMirror = mirrorSystem.findLibrary(Symbol('pub_cache'));
    print('Location: ${pubCacheMirror.uri}');
    for (var dep in pubCacheMirror.libraryDependencies) {
      print('Dep: ${dep.targetLibrary.uri}');
    }
  });

  test('findLibrary', () {
    // NOTE: This only works when pub_cache is imported.
    var mirrorSystem = mirrors.currentMirrorSystem();
    var pubCacheMirror = mirrorSystem
        .libraries[(Uri(scheme: 'package', path: 'pub_cache/pub_cache.dart'))];
    print(pubCacheMirror);
    print('Location: ${pubCacheMirror.uri}');
    for (var dep in pubCacheMirror.libraryDependencies) {
      print('Dep: ${dep.targetLibrary.uri}');
    }
  });
}
