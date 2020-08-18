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
