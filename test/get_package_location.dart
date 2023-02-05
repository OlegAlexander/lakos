import 'dart:io';
import 'pub_cache/pub_cache.dart';

/// Return the location of the package on disk (latest version).
/// Or return null if the package doesn't exist in the pub cache.
Directory? getPackageLocation(String packageName) {
  if (packageName == '.') {
    return Directory('.');
  }
  var cache = PubCache();
  var packageRef = cache.getLatestVersion(packageName);
  if (packageRef != null) {
    return packageRef.resolve()!.location;
  }
  return null;
}
