## 1.3.0

- **CLI breaking change:** --no-cycles-allowed no longer requires --metrics to be on.

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
