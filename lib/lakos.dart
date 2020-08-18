/// In addition to the command line tool, `lakos` can also be used as a library.
///
/// Use [buildModel] to construct a [Model] object.
///
/// Use [Model.getOutput] to print the model in dot or JSON format.
///
/// Use [Model.toDirectedGraph] for further analysis with the `directed_graph` library.
///
/// See [example/example.dart](https://github.com/OlegAlexander/lakos/blob/master/example/example.dart).
library lakos;

export 'src/build_model.dart' show buildModel, PubspecYamlNotFoundException;
export 'src/model.dart';
