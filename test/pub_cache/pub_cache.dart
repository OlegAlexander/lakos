// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// ignore_for_file: hash_and_equals

/// A programmatic API for reflecting on Pub's cache directory.
library pub_cache;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart' as yaml;

import 'src/impl.dart';

/// A programmatic API for reflecting on Pub's cache directory.
class PubCache {
  /// Return the location of Pub's package cache.
  static Directory getSystemCacheLocation() {
    Map env = Platform.environment;

    if (env.containsKey('PUB_CACHE')) {
      return Directory(env['PUB_CACHE']);
    } else if (Platform.isWindows) {
      // See https://github.com/dart-lang/pub/blob/master/lib/src/system_cache.dart.

      // %LOCALAPPDATA% is preferred as the cache location over %APPDATA%, because the latter is synchronised between
      // devices when the user roams between them, whereas the former is not.
      // The default cache dir used to be in %APPDATA%, so to avoid breaking old installs,
      // we use the old dir in %APPDATA% if it exists. Else, we use the new default location
      // in %LOCALAPPDATA%.
      var appDataCacheDir =
          Directory(path.join(env['APPDATA'], 'Pub', 'Cache'));
      if (appDataCacheDir.existsSync()) {
        return appDataCacheDir;
      }
      return Directory(path.join(env['LOCALAPPDATA'], 'Pub', 'Cache'));
    } else {
      return Directory('${env['HOME']}/.pub-cache');
    }
  }

  // The location of the pub cache.
  final Directory location;

  late List<Application> _applications;
  late List<PackageRef> _packageRefs;

  /// Create a pubcache instance. [dir] defaults to the default platform pub
  /// cache location.
  PubCache([Directory? dir])
      : location = dir ?? getSystemCacheLocation() {
    _parse();
  }

  /// Return the contents of `bin/` - the scripts for the activated applications.
  List<File> getBinScripts() {
    Directory dir = _getSubDir(location, 'bin');
    return dir.existsSync()
        ? dir.listSync().whereType<File>().cast<File>().toList()
        : <File>[];
  }

  /// Return applications that have been installed via `pub global activate`.
  List<Application> getGlobalApplications() => _applications;

  /// Get all the packages and their versions that have been installed into the
  /// cache.
  List<PackageRef> getPackageRefs() => _packageRefs;

  /// Return the list of package names (not versions) that are available in the
  /// cache.
  List<String> getCachedPackages() =>
      Set<String>.from(getPackageRefs().map((p) => p.name)).toList();

  /// Return all available cached versions for a given package.
  List<PackageRef> getAllPackageVersions(String packageName) =>
      getPackageRefs().where((p) => p.name == packageName).toList();

  /// Return the most recent verison of the given package contained in the
  /// cache. This method will prefer to return only release verions. If
  /// [includePreRelease] is true, then the very latest verision will be
  /// returned, include pre-release versions.
  PackageRef? getLatestVersion(String packageName,
      {bool includePreRelease = false}) {
    List<PackageRef> refs = getAllPackageVersions(packageName);

    if (refs.isEmpty) return null;
    if (refs.length == 1) return refs.first;

    PackageRef latest = refs.first;

    if (includePreRelease) {
      for (int i = 1; i < refs.length; i++) {
        if (refs[i].version > latest.version) latest = refs[i];
      }
    } else {
      List<Version> versions = refs.map((ref) => ref.version).toList();
      Version latestVersion = Version.primary(versions);
      for (PackageRef ref in refs) {
        if (ref.version == latestVersion) latest = ref;
      }
    }

    return latest;
  }

  void _parse() {
    // Read the activated applications.
    _applications = [];

    Directory globalPackagesDir = _getSubDir(location, 'global_packages');
    if (globalPackagesDir.existsSync()) {
      _applications = globalPackagesDir
          .listSync()
          .whereType<Directory>()
          .map((dir) => Application._(this, dir))
          .toList();
    }

    // Scan hosted packages
    _packageRefs = <PackageRef>[];

    Directory dartlangDir = Directory(
        path.join(location.path, 'hosted', _getHostedPackageDirectoryName()));
    if (dartlangDir.existsSync()) {
      _packageRefs.addAll(dartlangDir
          .listSync()
          .whereType<Directory>()
          .map((dir) => DirectoryPackageRef('hosted', dir)));
    }

    // Scan for git packages (ignore the git/cache directory).
    // ace-a1a140cc933e7d44d2955a6d6033308754bb9235
    Directory gitDir = Directory(path.join(location.path, 'git'));
    if (gitDir.existsSync()) {
      Iterable<PackageRef> gitRefs = gitDir
          .listSync()
          .where(
              (dir) => dir is Directory && path.basename(dir.path) != 'cache')
          .map((dir) => GitDirectoryPackageRef(dir as Directory));
      _packageRefs.addAll(gitRefs);
    }
  }

  Directory _getSubDir(Directory dir, String name) =>
      Directory(path.join(dir.path, name));

  String _getHostedPackageDirectoryName() {
    final url = Uri.parse(
        Platform.environment['PUB_HOSTED_URL'] ?? 'https://pub.dev');
    return url.host;
  }
}

/// A Dart application; a package with an entry-point, available via `pub global
/// activate`.
class Application {
  final PubCache _cache;
  final Directory _dir;

  List<PackageRef>? _packageRefs;

  Application._(this._cache, this._dir);

  /// The name of the defining package.
  String get name => path.basename(_dir.path);

  /// The version of the application and of the defining package.
  Version get version {
    final ref = getDefiningPackageRef();
    return ref == null ? Version.none : ref.version;
  }

  /// Return the reference to the defining package. This is the package that
  /// defines the application.
  PackageRef? getDefiningPackageRef() {
    for (PackageRef ref in getPackageRefs()) {
      if (ref.name == name) return ref;
    }
    return null;
  }

  /// Return all the package references for the application. This includes the
  /// defining package as well as the direct and transitive dependencies.
  List<PackageRef> getPackageRefs() {
    if (_packageRefs == null) _parsePubspecLock();
    return _packageRefs!;
  }

  @override
  String toString() => '$name $version';

  void _parsePubspecLock() {
    File pubspecLock = File(path.join(_dir.path, 'pubspec.lock'));
    Map doc = yaml.loadYaml(pubspecLock.readAsStringSync());
    Map packages = doc['packages'];
    _packageRefs = packages.keys.map((key) {
      Map m = packages[key];
      String source = m['source'];
      if (source == 'git') {
        return PackageRefImpl.git(key, m['version'], m['description'],
            (curRef) {
          for (PackageRef ref in _cache.getPackageRefs()) {
            if (ref == curRef) return ref.resolve();
          }
          return null;
        });
      } else if (source == 'hosted') {
        return PackageRefImpl.hosted(key, m['version'], (curRef) {
          for (PackageRef ref in _cache.getPackageRefs()) {
            if (ref == curRef) return ref.resolve();
          }
          return null;
        });
      } else if (source == 'path') {
        return PackageRefImpl.path(key, m['version'], m['description']);
      } else {
        return PackageRefImpl(source, key, m['version']);
      }
    }).toList();
  }
}

/// A package reference, including the package name and version. This package
/// reference can be resolved to the actual package on disk.
abstract class PackageRef {
  /// The type of the package reference. Valid types include `hosted` and `git`.
  String get sourceType;

  /// The name of the package.
  String get name;

  /// The version of the package.
  Version get version;

  /// Resolve the package reference into the actual package, including the
  /// location on disk.
  Package? resolve();

  @override
  bool operator ==(other) {
    return other is PackageRef &&
        sourceType == other.sourceType &&
        name == other.name &&
        version == other.version;
  }

  @override
  String toString() => '$name $version';
  
}

/// A representation of a package, including the name, version, and location on
/// disk.
class Package {
  final Directory location;
  final String name;
  final Version version;

  Package(this.location, this.name, this.version);

  @override
  String toString() => '$name $version';
}
