import 'dart:io' as io;
import 'package:path/path.dart' as path;

/// Resolve one file relative to another.
io.File resolveFile(io.File thisDartFile, String relativeFile) {
  var thisDartFileUri = Uri.file(thisDartFile.path);
  var resolvedUri = thisDartFileUri.resolve(relativeFile);
  return io.File.fromUri(resolvedUri);
}

/// Searches up the directory tree until it finds the pubspec.yaml file.
/// Returns null if pubspec.yaml is not found.
io.File findPubspecYaml(io.Directory currentDir) {
  if (!currentDir.isAbsolute) {
    currentDir = io.Directory(path.normalize(currentDir.absolute.path));
  }
  var rootDir = path.split(currentDir.path).first;
  while (currentDir.path != rootDir) {
    var currentDirItems =
        currentDir.listSync(recursive: false, followLinks: false);
    var pubspecYaml = currentDirItems.whereType<io.File>().where(
        (file) => path.basename(file.path).toLowerCase() == 'pubspec.yaml');
    if (pubspecYaml.length == 1) {
      return pubspecYaml.first;
    } else {
      currentDir = currentDir.parent;
    }
  }
  return null;
}

/// Convert to a relative file in lib directory, then resolve from pubspec.yaml.
io.File resolvePackageFileFromPubspecYaml(
    io.File pubspecYaml, String packageFile) {
  packageFile = packageFile.replaceFirst('package:', '');
  var packageFilePathParts = path.split(packageFile);
  packageFilePathParts[0] = 'lib'; // Replace package name with lib
  packageFile = path.joinAll(packageFilePathParts).replaceAll('\\', '/');
  return resolveFile(pubspecYaml, packageFile);
}
