import 'dart:io';
import 'package:path/path.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:lakos/src/model.dart';
import 'package:lakos/src/resolve_imports.dart';
import 'package:lakos/src/compute_metrics.dart';

const alwaysIgnore = '{.**,doc/**,build/**}';

/// Parse the import line to get the package or file path.
String parseImportLine(String line) {
  var openQuote = false;
  var importPath = '';
  for (var char in line.split('')) {
    if (openQuote == false && (char == "'" || char == '"')) {
      openQuote = true;
      continue;
    }
    if (openQuote == true && (char == "'" || char == '"')) {
      break;
    }
    if (openQuote == true) {
      importPath += char;
    }
  }
  if (importPath.isEmpty) {
    return null;
  }
  return importPath;
}

/// Recurses into the rootDir and gets all the subfolders as sugraphs.
List<Subgraph> getDirTree(Directory rootDir, String ignore) {
  var dirs = [rootDir];
  var subgraphs = [
    Subgraph(rootDir.path.replaceFirst(rootDir.path, '').replaceAll('\\', '/'),
        basename(rootDir.path))
  ];
  var treeSubgraphs = <Subgraph>[];
  treeSubgraphs.add(subgraphs.first);

  var leaves = <Subgraph>[];

  var dartFilesGlob = Glob('*.dart');
  var ignoreGlob = Glob(ignore, context: Context(current: rootDir.path));
  var alwaysIgnoreGlob =
      Glob(alwaysIgnore, context: Context(current: rootDir.path));

  // Recursively build the subgraph tree.
  // The trick is to keep track of two lists (dirs and subgraphs)
  // in the while loop at the same time.
  while (dirs.isNotEmpty) {
    var currentDir = dirs.removeAt(0);
    var currentSubgraph = subgraphs.removeAt(0);

    var dirsOnly = currentDir
        .listSync(recursive: false, followLinks: false)
        .whereType<Directory>()
        .where((dir) => !alwaysIgnoreGlob.matches(dir.path))
        .where((dir) => !ignoreGlob.matches(dir.path));
    var filesOnly = dartFilesGlob
        .listSync(root: currentDir.path, followLinks: false)
        .whereType<File>()
        .where((file) => !alwaysIgnoreGlob.matches(file.path))
        .where((file) => !ignoreGlob.matches(file.path));

    if (dirsOnly.isEmpty) {
      leaves.add(currentSubgraph);
    }

    // Add directories as subgraphs
    for (var dir in dirsOnly) {
      var subgraph = Subgraph(
          dir.path.replaceFirst(rootDir.path, '').replaceAll('\\', '/'),
          basename(dir.path));
      currentSubgraph.subgraphs.add(subgraph);
      subgraph.parent = currentSubgraph;
    }

    // Add dart files as nodes
    for (var file in filesOnly) {
      currentSubgraph.nodes
          .add(file.path.replaceFirst(rootDir.path, '').replaceAll('\\', '/'));
    }

    // Recurse breadth first
    dirs.addAll(dirsOnly);
    subgraphs.addAll(currentSubgraph.subgraphs);
  }

  // Recursively remove empty subgraphs which don't contain any dart files
  while (leaves.isNotEmpty) {
    var leaf = leaves.removeLast();
    if (leaf.parent != null) {
      if (leaf.nodes.isEmpty && leaf.subgraphs.isEmpty) {
        leaf.parent.subgraphs.remove(leaf);

        // Recurse up the tree depth first
        leaves.add(leaf.parent);
      }
    }
  }

  return treeSubgraphs;
}

/// Returns all Dart files recursively from the rootDir.
Iterable<File> getDartFiles(Directory rootDir, String ignore) {
  var dartFilesGlob = Glob('**.dart');
  var ignoreGlob = Glob(ignore, context: Context(current: rootDir.path));
  var alwaysIgnoreGlob =
      Glob(alwaysIgnore, context: Context(current: rootDir.path));

  var dartFiles = dartFilesGlob
      .listSync(root: rootDir.path, followLinks: false)
      .whereType<File>()
      .where((file) => !alwaysIgnoreGlob.matches(file.path))
      .where((file) => !ignoreGlob.matches(file.path));
  return dartFiles;
}

/// Returns a map of Dart files as Nodes.
Map<String, Node> getDartFileNodes(
    Directory rootDir, String ignore, bool showNodeMetrics) {
  var dartFiles = getDartFiles(rootDir, ignore);

  // Add dart files as nodes
  var nodes = <String, Node>{};
  for (var file in dartFiles) {
    var id = file.path.replaceFirst(rootDir.path, '').replaceAll('\\', '/');
    var label = basenameWithoutExtension(file.path);
    nodes[id] = Node(id, label, showNodeMetrics: showNodeMetrics);
  }
  return nodes;
}

/// Read each Dart file and get the import and export paths.
List<Edge> getEdges(
    Directory rootDir, String ignore, File pubspecYaml, List<String> nodes) {
  var edges = <Edge>[];

  var dartFiles = getDartFiles(rootDir, ignore);

  for (var dartFile in dartFiles) {
    var from =
        dartFile.path.replaceFirst(rootDir.path, '').replaceAll('\\', '/');

    // Grab the imports from the dart file
    var lines = dartFile.readAsLinesSync();
    for (var line in lines) {
      if (line.startsWith('import') || line.startsWith('export')) {
        var parsedImportLine = parseImportLine(line);
        if (parsedImportLine == null) {
          continue;
        }

        File resolvedFile;
        if (parsedImportLine.startsWith('package:')) {
          resolvedFile =
              resolvePackageFileFromPubspecYaml(pubspecYaml, parsedImportLine);
        } else if (parsedImportLine.startsWith('dart:') ||
            parsedImportLine.startsWith('dart-ext:')) {
          continue; // Ignore dart: or dart-ext: imports
        } else {
          try {
            resolvedFile = resolveFile(dartFile, parsedImportLine);
          } catch (e) {
            resolvedFile = null;
          }
        }

        // Only add dart files that exist--account for imports inside strings, comments, etc.
        if (resolvedFile != null &&
            resolvedFile.existsSync() &&
            isWithin(rootDir.path, resolvedFile.path) &&
            resolvedFile.path.endsWith('.dart')) {
          var to = resolvedFile.path
              .replaceFirst(rootDir.path, '')
              .replaceAll('\\', '/');
          // No self loops
          if (from != to) {
            // Only add edges to nodes that exist
            if (nodes.contains(to)) {
              edges.add(Edge(from, to,
                  directive: line.startsWith('import')
                      ? Directive.Import
                      : Directive.Export));
            }
          }
        }
      }
    }
  }
  return edges;
}

/// Thrown by [buildModel] if pubspec.yaml can't be found in or above the rootDir.
class PubspecYamlNotFoundException implements Exception {
  final String message;
  PubspecYamlNotFoundException(this.message);
  @override
  String toString() => 'PubspecYamlNotFoundException: $message';
}

/// This is the main function for API usage. Returns a [Model] object.
///
/// - `rootDir` -- The root directory (required).
///
/// - `ignoreGlob` -- A glob pattern of files/folders to ignore.
///
/// - `showTree` -- Show the directory tree?
///
/// - `showMetrics` -- Show metrics?
///
/// - `showNodeMetrics` -- Show node metrics?
///
/// Throws [FileSystemException] if rootDir doesn't exist.
///
/// Throws [PubspecYamlNotFoundException] if pubspec.yaml can't be found in or above the rootDir.
///
/// Throws [FormatException] if ignoreGlob is invalid.
Model buildModel(Directory rootDir,
    {String ignoreGlob = '!**',
    bool showTree = true,
    bool showMetrics = false,
    bool showNodeMetrics = false}) {
  // Convert relative to absolute path.
  if (!rootDir.isAbsolute) {
    rootDir = Directory(normalize(rootDir.absolute.path));
  }

  // Always use forward slashes
  rootDir = Directory(rootDir.path.replaceAll('\\', '/'));

  var pubspecYaml = findPubspecYaml(rootDir);
  if (pubspecYaml == null) {
    throw PubspecYamlNotFoundException(
        'pubspec.yaml not found in or above the root directory.');
  }

  var model = Model(rootDir: rootDir.path)
    ..nodes =
        getDartFileNodes(rootDir, ignoreGlob, showNodeMetrics && showMetrics);

  if (showTree) {
    model.subgraphs = getDirTree(rootDir, ignoreGlob);
  }

  model.edges.addAll(
      getEdges(rootDir, ignoreGlob, pubspecYaml, model.nodes.keys.toList()));

  if (showMetrics) {
    model.metrics = computeMetrics(model);
  }

  return model;
}
