import 'package:test/test.dart';
import 'package:args/command_runner.dart' as command_runner;

class LakosCommandRunner extends command_runner.CommandRunner {
  LakosCommandRunner(String executableName, String description)
      : super(executableName, description);

  @override
  String get usageFooter => '''

Examples:

  dot command:

    // Pass output directly to dot
    lakos dot -d . | dot -Tsvg -o example.svg
    lakos dot -d ./lib --no-tree | dot -Tpng -Gdpi=300 -o example.png

    // Save output to a dot file first and then use dot
    lakos dot -d /path/to/dart/package --ignore-dirs=doc,test -o example.dot
    dot -Tpng example.dot -Gdpi=300 -o example.png

  metrics command:

    // Print metrics for current directory
    lakos metrics -d .

    // Save metrics to json file
    lakos metrics -d /path/to/dart/package --ignore-dirs=doc,test -o example.json

Notes:

  Only 'import' and 'export' directives are supported; 'library' and 'part' are not.

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
    // [argResults] is set before [run()] is called and contains the options
    // passed to this command.
    // print('dirs: ${argResults['dirs']}');
    // print('layout: ${argResults['layout']}');
    print('dot dir: ${globalResults['dir']}');
    print('dot layout: ${argResults['layout']}');
  }
}

class MetricsCommand extends command_runner.Command {
  @override
  final name = 'metrics';
  @override
  final description = 'Print modular programming metrics in JSON format.';

  MetricsCommand() {}

  @override
  void run() {
    print('metrics dir: ${globalResults['dir']}');
    print('Metrics not implemented yet.');
  }
}

void main() {
  var runner =
      LakosCommandRunner('lakos', 'A tool for modular programming in Dart.')
        ..argParser.addFlag('version',
            abbr: 'v', help: 'Print version.', negatable: false)
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
        ..addCommand(MetricsCommand());

  test('dot', () {
    runner.run(['dot', '-d', '.', '--layout', 'LR']);
    runner.printUsage();
    runner.commands['dot'].printUsage();
  });

  test('metrics', () {
    runner.run(['metrics', '-d', '.']);
    runner.commands['metrics'].printUsage();
  });
}
