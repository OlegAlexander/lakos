import 'dart:io' as io;
import 'package:args/args.dart' as args;
import 'package:lakos/build_model.dart' as build_model;
import 'package:lakos/model.dart' as model;

enum ExitCodes { Ok, InvalidOption, NoRootDirectorySpecified, BuildModelFailed }

const usageHeader = '''

Usage: lakos [options] <root-directory>
''';

const usageFooter = '''

Examples:

  // Print dot graph for current directory
  lakos .

  // Pass output directly to Graphviz dot in one line
  lakos . | dot -Tsvg -o example.svg
  lakos --no-tree ./lib | dot -Tpng -Gdpi=300 -o example.png

  // Save output to a dot file first and then use Graphviz dot to generate the graph image
  lakos --output example.dot /path/to/dart/package
  dot -Tpng example.dot -Gdpi=300 -o example.png

Notes:

  * Exports are drawn with a dashed edge.
  * Only 'import' and 'export' directives are supported; 'library' and 'part' are not.
''';

void printUsage(args.ArgParser parser) {
  print(usageHeader);
  print(parser.usage);
  print(usageFooter);
}

void main(List<String> arguments) {
  // Validate args > Create model > compute metrics > output formats > fail if thresholds exceeded
  // Use this lib for graph algorithms https://pub.dev/packages/directed_graph
  // SLOC command: cloc --include-lang=Dart --by-file .

  var parser = args.ArgParser()
    ..addOption('format',
        abbr: 'f',
        help: 'Output format.',
        valueHelp: 'format',
        allowed: ['dot', 'json'],
        defaultsTo: 'dot')
    ..addOption('output',
        abbr: 'o',
        help: 'Save output to a file instead of printing it.',
        valueHelp: 'file',
        defaultsTo: 'STDOUT')
    ..addFlag('tree',
        abbr: 't',
        help: 'Show directory structure as subgraphs.',
        defaultsTo: true,
        negatable: true)
    ..addFlag('metrics',
        abbr: 'm',
        help: 'Compute and show metrics.',
        defaultsTo: true,
        negatable: true)
    ..addMultiOption('ignore-dirs',
        abbr: 'i',
        help: 'A comma-separated list of directories to ignore.',
        valueHelp: '.git,.dart_tool',
        defaultsTo: ['.git', '.dart_tool'])
    // TODO Should we always start in the package root?
    // Or are we allowed to start deeper in the package?
    // If you always start at the package root, then ignore-dirs may be test, bin, etc.
    // Or it can be glob paths relative to the package root.
    // .git, .dart_tool should be implied.
    // Otherwise, if you can start deeper in the package, then ignore-dirs may be
    // dirs deeper in the package and you may even have ignore-files
    // or just a generic ignore flag supporting glob paths.
    ..addOption('layout',
        abbr: 'l',
        help: 'Graph layout direction. AKA "rankdir" in Graphviz.',
        valueHelp: 'TB',
        allowed: ['TB', 'LR', 'BT', 'RL'],
        allowedHelp: {
          'TB': 'top to bottom',
          'LR': 'left to right',
          'BT': 'bottom to top',
          'RL': 'right to left'
        },
        defaultsTo: 'TB');

  args.ArgResults argResults;

  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    print(e);
    printUsage(parser);
    io.exit(ExitCodes.InvalidOption.index);
  }

  if (argResults.rest.length != 1) {
    print('No root directory specified.');
    printUsage(parser);
    io.exit(ExitCodes.NoRootDirectorySpecified.index);
  }

  var dir = io.Directory(argResults.rest[0]);
  var format = argResults['format'] as String;
  var output = io.File(argResults['output']);
  var tree = argResults['tree'] as bool;
  var metrics = argResults['metrics'] as bool;
  var ignoreDirs = argResults['ignore-dirs'] as List<String>;
  var layout = argResults['layout'] as String;

  model.Model graph;
  try {
    graph = build_model.buildModel(dir,
        ignoreDirs: ignoreDirs,
        showTree: tree,
        showMetrics: metrics,
        layout: layout);
  } catch (e) {
    print(e);
    io.exit(ExitCodes.BuildModelFailed.index);
  }

  print(build_model.getOutput(graph, format));
  // TODO Add output to file.
}
