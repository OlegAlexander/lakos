import 'dart:io' as io;
import 'package:args/args.dart' as args;
import 'package:lakos/build_model.dart' as build_model;
import 'package:lakos/model.dart' as model;

enum ExitCode {
  Ok,
  InvalidOption,
  NoRootDirectorySpecified,
  BuildModelFailed,
  WriteToFileFailed,
  CyclesDetected,
  MetricsThresholdExceeded
}

const outputDefault = 'STDOUT';
const defaultNccdThreshold = '2.0';

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
  * Orphan nodes are bold.
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
  // TODO Consider not using import as everywhere.

  var parser = args.ArgParser()
    ..addOption('format',
        abbr: 'f',
        help: 'Output format.',
        valueHelp: 'FORMAT',
        allowed: ['dot', 'json'],
        defaultsTo: 'dot')
    ..addOption('output',
        abbr: 'o',
        help: 'Save output to a file instead of printing it.',
        valueHelp: 'FILE',
        defaultsTo: outputDefault)
    ..addFlag('tree',
        help: 'Show directory structure as subgraphs.',
        defaultsTo: true,
        negatable: true)
    ..addFlag('metrics',
        help: 'Compute and show global metrics.',
        defaultsTo: true,
        negatable: true)
    ..addFlag('node-metrics',
        help: 'Show node metrics. Only works when --metrics is true.',
        defaultsTo: false,
        negatable: true)
    ..addOption('ignore',
        abbr: 'i',
        help: 'Exclude files and directories with a glob pattern.',
        valueHelp: 'GLOB',
        defaultsTo: '!**')
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
        defaultsTo: 'TB')
    ..addFlag('cycles-allowed',
        help:
            'Fail with a non-zero exit code if dependency cycles are detected. Only works when --metrics is true.',
        defaultsTo: false,
        negatable: true)
    ..addOption('nccd-threshold',
        help:
            'Fail with a non-zero exit code if the NCCD exceeds the threshold. The threshold must be a positive double. Only works when --metrics is true.',
        valueHelp: defaultNccdThreshold,
        defaultsTo: defaultNccdThreshold);

  // Parse args.
  args.ArgResults argResults;

  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    print(e);
    printUsage(parser);
    io.exit(ExitCode.InvalidOption.index);
  }

  if (argResults.rest.length != 1) {
    print('No root directory specified.');
    printUsage(parser);
    io.exit(ExitCode.NoRootDirectorySpecified.index);
  }

  // Get options.
  var rootDir = io.Directory(argResults.rest[0]);
  var format = argResults['format'] as String;
  var output = argResults['output'] as String;
  var tree = argResults['tree'] as bool;
  var metrics = argResults['metrics'] as bool;
  var nodeMetrics = argResults['node-metrics'] as bool;
  var ignore = argResults['ignore'] as String;
  var layout = argResults['layout'] as String;
  var cyclesAllowed = argResults['cycles-allowed'] as bool;
  // TODO Consider removing the nccdThreshold
  var nccdThreshold = 0.0;
  try {
    nccdThreshold = double.parse(argResults['nccd-threshold']);
  } catch (e) {
    print(e);
    printUsage(parser);
    io.exit(ExitCode.InvalidOption.index);
  }

  // Build model.
  model.Model graph;
  try {
    graph = build_model.buildModel(rootDir,
        ignoreGlob: ignore,
        showTree: tree,
        showMetrics: metrics,
        showNodeMetrics: nodeMetrics,
        layout: layout);
  } catch (e) {
    print(e);
    io.exit(ExitCode.BuildModelFailed.index);
  }

  // Write output to STDOUT or a file.
  var contents = '';
  switch (format) {
    case 'dot':
      contents = graph.getOutput(model.OutputFormat.Dot);
      break;
    case 'json':
      contents = graph.getOutput(model.OutputFormat.Json);
      break;
  }

  if (output == outputDefault) {
    print(contents);
  } else {
    try {
      io.File(output).writeAsStringSync(contents);
    } catch (e) {
      print(e);
      io.exit(ExitCode.WriteToFileFailed.index);
    }
  }

  // Metrics thresholds.
  if (metrics) {
    if (!cyclesAllowed) {
      if (!graph.metrics.isAcyclic) {
        io.exit(ExitCode.CyclesDetected.index);
      }
    }
    if (graph.metrics.nccd > nccdThreshold) {
      io.exit(ExitCode.MetricsThresholdExceeded.index);
    }
  }
}
