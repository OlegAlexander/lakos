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
