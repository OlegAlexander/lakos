import 'dart:io' as io;
import 'package:args/command_runner.dart' as command_runner;
import 'package:lakos/dot_command.dart' as dot_command;

class LakosCommandRunner extends command_runner.CommandRunner {
  LakosCommandRunner(String executableName, String description)
      : super(executableName, description);

  @override
  String get usageFooter => '''

Examples:

  dot command:

    // Print dot graph for current directory
    lakos dot

    // Pass output directly to Graphviz dot in one line
    lakos dot | dot -Tsvg -o example.svg
    lakos dot -d ./lib --no-tree | dot -Tpng -Gdpi=300 -o example.png

    // Save output to a dot file first and then use Graphviz dot to generate the graph image
    lakos dot -d /path/to/dart/package --ignore-dirs=doc,test -o example.dot
    dot -Tpng example.dot -Gdpi=300 -o example.png

  metrics command:

    // Print metrics for current directory
    lakos metrics

    // Save metrics to a json file
    lakos metrics -d /path/to/dart/package --ignore-dirs=doc,test -o example.json

Notes:

  * Exports are drawn with a dashed edge.
  * Only 'import' and 'export' directives are supported; 'library' and 'part' are not.

''';
}

class DotCommand extends command_runner.Command {
  @override
  final name = 'dot';
  @override
  final description = 'Visualize library dependencies in Graphviz dot.';

  DotCommand() {
    argParser
      ..addFlag('tree',
          abbr: 't',
          help: 'Show directory structure as subgraphs.',
          defaultsTo: true,
          negatable: true)
      ..addOption('layout',
          abbr: 'l',
          help: 'Graph layout direction. AKA "rankdir" in Graphviz.',
          valueHelp: 'TB',
          allowed: ['TB', 'LR', 'BT', 'RL'],
          defaultsTo: 'TB');
  }

  @override
  void run() {
    var dir = io.Directory(globalResults['dir']);
    var output = io.File(globalResults['output']);
    var ignoreDirs = globalResults['ignore-dirs'] as List<String>;
    var tree = argResults['tree'] as bool;
    var layout = argResults['layout'] as String;
    dot_command.dot(dir, output, ignoreDirs, tree, layout);
  }
}

class MetricsCommand extends command_runner.Command {
  @override
  final name = 'metrics';
  @override
  final description = 'Print modular programming metrics in JSON format.';

  MetricsCommand();

  @override
  void run() {
    print('Metrics not implemented yet.');
  }
}

void main(List<String> args) {
  LakosCommandRunner('lakos', 'A tool for modular programming in Dart.')
    ..argParser
        .addFlag('version', abbr: 'v', help: 'Print version.', negatable: false)
    ..argParser.addSeparator('')
    ..argParser.addOption('dir',
        abbr: 'd',
        help: 'The root directory to analyze.',
        valueHelp: 'DIR',
        defaultsTo: '.')
    ..argParser.addOption('output',
        abbr: 'o',
        help: 'Save output to a file instead of printing it.',
        valueHelp: 'graph.dot or metrics.json',
        defaultsTo: 'STDOUT')
    ..argParser.addMultiOption('ignore-dirs',
        abbr: 'i',
        help: 'A comma-separated list of directories to ignore.',
        valueHelp: '.git,.dart_tool',
        defaultsTo: ['.git', '.dart_tool'])
    ..addCommand(DotCommand())
    ..addCommand(MetricsCommand())
    ..run(args);
}
