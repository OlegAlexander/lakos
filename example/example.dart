import 'dart:io';
import 'package:lakos/lakos.dart';

void main() {
  var model =
      buildModel(Directory('.'), ignoreGlob: 'test/**', showMetrics: true);
  print(model.getOutput(OutputFormat.Dot));
  print(model.getOutput(OutputFormat.Json));

  if (!model.metrics!.isAcyclic) {
    print('Dependency cycle detected.');
  }

  var nodesSortedBySloc = model.nodes.values.toList();
  nodesSortedBySloc.sort((a, b) => a.sloc!.compareTo(b.sloc!));
  for (var node in nodesSortedBySloc) {
    print('${node.sloc}: ${node.id}');
  }

  // Further analysis with the directed_graph library
  var digraph = model.toDirectedGraph();
  print(digraph.topologicalOrdering);
}
