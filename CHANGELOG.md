## 2.0.2

- Ignore import lines that don't end with a semicolon.
- Upgraded dependencies.

## 2.0.1

- Upgraded dependencies.

## 2.0.0

- Upgraded to null-safe directed_graph.
- Migrated lakos to null safety!

## 1.4.1

- Upgraded all dependencies to null-safe versions, except for directed_graph.
- string_scanner is no longer a direct dependency.

## 1.4.0

- **CLI breaking change:** Removed `--node-color`, `--font`, and `--layout` options because all of these can be overriden through the Graphviz `dot` command line arguments.
- Improved default graph styling.

## 1.3.4

- Got image sizes under control in readme.

## 1.3.3

- Added `--font` option.

## 1.3.2

- Only add edges to nodes that exist.

## 1.3.1

- Improved resolvedFile logic in getEdges function.

## 1.3.0

- **CLI breaking change:** `--no-cycles-allowed` no longer requires `--metrics` to be on.

## 1.2.3

- Added numEdges and avgDegree to metrics. Removed acdp.
- Added `--node-color` option.
- Made `--metrics` default to off.
- Added a `gv2gml` example in readme.
- Updated readme images.

## 1.2.2

- Upgraded to directed_graph 0.2.2.
- Added a test for piping stdout to dot.

## 1.2.1

- **API breaking change:** convertModelToDirectedGraph is now Model.toDirectedGraph.
- Replaced digraph.isAcyclic with firstCycle.isEmpty for efficiency.
- Fixed a bug with forward slash paths on Windows.

## 1.1.1

- Escaped multiplication asterisks in readme.

## 1.1.0

- Added Metrics.firstCycle.
- Exposed convertModelToDirectedGraph in the public API.
- Added more dartdoc comments to the public API.
- Made subgraph ids relative to rootDir instead of rootDir.parent.

## 1.0.0

- Initial version.
