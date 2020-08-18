/// In addition to the command line tool, `lakos` can also be used as a library.
///
/// Use [buildModel] to construct a [Model] object.
///
/// Use [convertModelToDirectedGraph] for further analysis with the directed_graph library.
///
/// See example/example.dart.
library lakos;

export 'src/build_model.dart' show buildModel, PubspecYamlNotFoundException;
export 'src/metrics.dart' show convertModelToDirectedGraph;
export 'src/model.dart';
