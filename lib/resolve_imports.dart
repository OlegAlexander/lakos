import 'dart:io' as io;
import 'dart:cli' as cli;
import 'package:package_config/package_config.dart' as package_config;
import 'package:path/path.dart' as path;

package_config.PackageConfig findPackageConfigUriSync(io.Directory rootDir) {
  // Thanks cli.waitFor for not turning this entire project into an async/await dance
  // just because a single function happens to return a Future!
  return cli.waitFor<package_config.PackageConfig>(package_config
      .findPackageConfigUri(Uri(scheme: 'file', path: rootDir.path)));
}

io.File resolveFile(io.File thisDartFile, String relativeFile) {
  var thisDartFileUri = Uri.file(thisDartFile.path);
  var resolvedUri = thisDartFileUri.resolve(relativeFile);
  return io.File.fromUri(resolvedUri);
}

io.File resolvePackage(
    package_config.PackageConfig packageConfig, String packageFile) {
  var directiveUri = Uri.parse(packageFile);
  var resolvedUri = packageConfig.resolve(directiveUri);
  if (resolvedUri == null) {
    return null;
  }
  // Fix issue with double back slash from . on Windows.
  var fixedPath = path.normalize(resolvedUri.toFilePath());
  return io.File(fixedPath);
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

/// Convert to a relative file in lib directory, then resolve from pubspec.yaml
io.File resolvePackageFileFromPubspecYaml(
    io.File pubspecYaml, String packageFile) {
  packageFile = packageFile.replaceFirst('package:', '');
  var packageFilePathParts = path.split(packageFile);
  packageFilePathParts[0] = 'lib'; // Replace package name with lib
  packageFile = path.joinAll(packageFilePathParts).replaceAll('\\', '/');
  return resolveFile(pubspecYaml, packageFile);
}
