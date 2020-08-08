/// In addition to the command line tool, lakos can also be used as a library.
/// For example, lakos/bin/lakos.dart uses package:lakos/lakos.dart.
/// There is only one function, buildModel, which returns the Model object.
/// The model can then be printed in different formats with model.getOutput.
/// Or the model can be further analyzed, especially model.metrics.
library lakos;

export 'src/build_model.dart' show buildModel;
export 'src/model.dart';
