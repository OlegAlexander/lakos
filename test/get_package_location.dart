import 'dart:io' as io;
import 'package:pub_cache/pub_cache.dart';

// TODO Consider using cache.getLatestVersion(packageName).resolve().location instead of specific version.
// Because you are not expecting the exact output anyway in your tests.
// This way you can use ^version in pubspec.yaml.

/// Return the location of the package on disk.
/// Or return null if the package doesn't exist in the pub cache.
io.Directory getPackageLocation(String packageName, String packageVersion) {
  var cache = PubCache();
  var allVersions = cache.getAllPackageVersions(packageName);
  for (var version in allVersions) {
    if (version.version.toString() == packageVersion) {
      return version.resolve().location;
    }
  }
  return null;
}
