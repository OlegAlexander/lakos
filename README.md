<img src="https://user-images.githubusercontent.com/42989765/94331664-5fb94f00-ff83-11ea-81ea-ac252e1243a1.png" alt="Example dependency graph" width="100%"/>

`lakos` is a command line tool and library that can:

- Visualize Dart library dependencies in Graphviz `dot`.
- Detect dependency cycles.
- Identify orphans.
- Compute useful dependency graph metrics.

# Command Line Usage

```console
Usage: lakos [options] <root-directory>

-f, --format=<FORMAT>          Output format.
                               [dot (default), json]
                               
-o, --output=<FILE>            Save output to a file instead of printing it.
                               (defaults to "STDOUT")
                               
    --[no-]tree                Show directory structure as subgraphs.
                               (defaults to on)
                               
-m, --[no-]metrics             Compute and show global metrics.
                               (defaults to --no-metrics)
                               
    --[no-]node-metrics        Show node metrics. Only works when --metrics is true.
                               (defaults to --no-node-metrics)
                               
-i, --ignore=<GLOB>            Exclude files and directories with a glob pattern.
                               (defaults to "!**")
                               
-c, --node-color=<lavender>    Any X11 or hex color.
                               Gradients are possible with a : separator.
                               For example, #e0e0f9:#c2c2f4
                               (defaults to "lavender")
                               
    --font=<Calibri>           Any Pango-Cairo font.
                               (defaults to "Calibri")
                               
-l, --layout=<TB>              Graph layout direction. AKA "rankdir" in Graphviz.

          [BT]                 bottom to top
          [LR]                 left to right
          [RL]                 right to left
          [TB] (default)       top to bottom

    --[no-]cycles-allowed      With --no-cycles-allowed lakos runs normally
                               but exits with a non-zero exit code
                               if a dependency cycle is detected.
                               Useful for CI builds.
                               (defaults to --no-cycles-allowed)
```

## Examples

Print dot graph for the current directory (not very useful):

```console
lakos .
```

Pass output directly to Graphviz `dot` in one line (a lot more useful):

```console
lakos . | dot -Tpng -Gdpi=200 -o example.png
```

Save output to a dot file first and then generate an SVG using Graphviz `dot`:

```console
lakos -o example.dot .
dot -Tsvg example.dot -o example.svg
```

## Notes

- Nodes are Dart libraries. Edges are "uses" or "depends on" relationships.
- Exports are drawn with a dashed edge.
- Orphan nodes are octagons (with `--metrics`).
- Only `import` and `export` directives are supported; `library` and `part` are not.
- Only libraries under the root-directory are shown; Dart core and external packages are not.

## More Examples

`lakos` run on itself with metrics, ignoring tests.

```console
lakos -o dot_images/lakos.metrics_no_test.dot -m -i test/** .
```

<img src="https://user-images.githubusercontent.com/42989765/94331699-9ee7a000-ff83-11ea-956c-f559ec5fbb60.png" alt="Lakos run on itself with metrics, ignoring tests." width="100%"/>


Show node metrics.

```console
lakos -o dot_images/args.no_test_node_metrics.dot -m -i test/** --node-metrics /root/.pub-cache/hosted/pub.dartlang.org/args-1.6.0
```

<img src="https://user-images.githubusercontent.com/42989765/94335258-27b80900-ff8f-11ea-8656-83112b3edd16.png" alt="Show node metrics." width="100%"/>

No directory tree.

```console
lakos --no-tree -o dot_images/string_scanner.no_test_no_tree.dot -i test/** /root/.pub-cache/hosted/pub.dartlang.org/string_scanner-1.0.5
```

<img src="https://user-images.githubusercontent.com/42989765/94331765-11588000-ff84-11ea-951e-a4dee2cb8990.png" alt="No directory tree." width="100%"/>

Left to right layout.

```console
lakos -o dot_images/test.no_test_lr.dot -i test/** -l LR /root/.pub-cache/hosted/pub.dartlang.org/test-1.15.3
```

<img src="https://user-images.githubusercontent.com/42989765/94331795-449b0f00-ff84-11ea-8ae2-8945bf628ab5.png" alt="Left to right layout." width="100%"/>

Gradient node color, different font.

```console
lakos -o dot_images/pub_cache.font_color.dot -c #f6e0b8:#c5a867 --font Cambria /root/.pub-cache/hosted/pub.dartlang.org/pub_cache-0.2.3
```

<img src="https://user-images.githubusercontent.com/42989765/94331961-b32c9c80-ff85-11ea-9abe-196addd40669.png" alt="Gradient node color, different font." width="100%"/>


Example JSON output:

```console
lakos -f json -o dot_images/pub_cache.metrics_no_test.json -m -i test/** /root/.pub-cache/hosted/pub.dartlang.org/pub_cache-0.2.3
```

<details> <summary>Click to show the JSON output.</summary>

```json
{
  "rootDir": "/root/.pub-cache/hosted/pub.dartlang.org/pub_cache-0.2.3",
  "nodes": {
    "/example/list.dart": {
      "id": "/example/list.dart",
      "label": "list",
      "cd": 3,
      "inDegree": 0,
      "outDegree": 1,
      "instability": 1.0,
      "sloc": 14
    },
    "/lib/pub_cache.dart": {
      "id": "/lib/pub_cache.dart",
      "label": "pub_cache",
      "cd": 2,
      "inDegree": 2,
      "outDegree": 1,
      "instability": 0.33,
      "sloc": 162
    },
    "/lib/src/impl.dart": {
      "id": "/lib/src/impl.dart",
      "label": "impl",
      "cd": 2,
      "inDegree": 1,
      "outDegree": 1,
      "instability": 0.5,
      "sloc": 95
    }
  },
  "subgraphs": [
    {
      "id": "",
      "label": "pub_cache-0.2.3",
      "nodes": [],
      "subgraphs": [
        {
          "id": "/example",
          "label": "example",
          "nodes": ["/example/list.dart"],
          "subgraphs": []
        },
        {
          "id": "/lib",
          "label": "lib",
          "nodes": ["/lib/pub_cache.dart"],
          "subgraphs": [
            {
              "id": "/lib/src",
              "label": "src",
              "nodes": ["/lib/src/impl.dart"],
              "subgraphs": []
            }
          ]
        }
      ]
    }
  ],
  "edges": [
    {
      "from": "/example/list.dart",
      "to": "/lib/pub_cache.dart",
      "directive": "import"
    },
    {
      "from": "/lib/pub_cache.dart",
      "to": "/lib/src/impl.dart",
      "directive": "import"
    },
    {
      "from": "/lib/src/impl.dart",
      "to": "/lib/pub_cache.dart",
      "directive": "import"
    }
  ],
  "metrics": {
    "isAcyclic": false,
    "firstCycle": ["/lib/pub_cache.dart", "/lib/src/impl.dart", "/lib/pub_cache.dart"],
    "numNodes": 3,
    "numEdges": 3,
    "avgDegree": 1.0,
    "orphans": [],
    "ccd": 7,
    "acd": 2.33,
    "nccd": 1.4,
    "totalSloc": 271,
    "avgSloc": 90.33
  }
}
```

</details>

## Convert to GML

Still can't get enough graph visualization goodness? Try this!

```console
lakos -i test/** /root/.pub-cache/hosted/pub.dartlang.org/test-1.15.3 | gv2gml -o dot_images/test.gml
```

`gv2gml` converts dot format into [GML format](https://en.wikipedia.org/wiki/Graph_Modelling_Language), which you can open in yEd, Gephi, Cytoscape, etc.

<img src="https://user-images.githubusercontent.com/42989765/93006268-f3fcce00-f50e-11ea-9f96-e6ce9c8cffbb.png" alt="GML file imported into yEd." width="100%"/>

## Global Metrics

Use `--metrics` to compute and show these.

**isAcyclic:** True if the library dependencies form a directed acyclic graph (DAG). False if the graph contains dependency cycles. True is better.

**firstCycle:** The first dependency cycle found if the graph is not acyclic. Available in the JSON output.

**numNodes:** Number of Dart libraries (nodes) in the graph.

**numEdges:** Number of edges (dependencies) in the graph.

**avgDegree:** The average number of incoming/outgoing edges per node. Average degree (directed graph) = numEdges / numNodes. This metric can compare graphs of different sizes. Similar to the ACD, the average degree can be interpreted as the average number of nodes that *will* need to change when one node changes. Lower is better.

**numOrphans:** Number of Dart libraries that have no imports and are imported nowhere. (inDegree and outDegree are 0.)

**ccd:** The Cumulative Component Dependency (CCD) is the sum of all Component Dependencies. The CCD can be interpreted as the total "coupling" of the graph. Lower is better.

**acd:** The Average Component Dependency (ACD). ACD = CCD / numNodes. Similar to the avgDegree, the ACD can be interpreted as the average number of nodes that *may* need to change when one node changes. Lower is better.

**nccd:** The Normalized Cumulative Component Dependency. This is the CCD divided by a CCD of a binary tree of the same size. This metric can compare graphs of different sizes. If the NCCD is below 1.0, the graph is "horizontal". If the NCCD is above 1.0, the graph is "vertical". If the NCCD is above 2.0, the graph probably contains cycles. Lower is better.

**totalSloc:** Total Source Lines of Code for all nodes.

**avgSloc:** The average SLOC per node. The average SLOC should arguably be kept within some Goldilocks range: not too big and not too small.

## Node Metrics

Use `--metrics --node-metrics` to show these.

**cd:** The Component Dependency (CD) is the number of nodes a particular node depends on directly or transitively, including itself.

**inDegree:** The number of nodes that depend on this node. (Number of incoming edges.)

**outDegree:** The number of nodes this node depends on. (Number of outgoing edges.)

**instability:** A node metric by Robert C. Martin related to the Stable-Dependencies Principle: Depend in the direction of stability. Instability = outDegree / (inDegree + outDegree). This yields a value from 0 to 1, where 0 means 100% stable and 1 means 100% unstable. In general, node instability should decrease in the direction of dependency. In other words, lower level nodes should be more stable and more reusable than higher level nodes.

**sloc:** Source Lines of Code is the number of lines of code ignoring comments and blank lines. Note: my SLOC counter function doesn't deal correctly with comments inside multi-line strings or multi-line comments in the middle of code.

## Exit Codes

Use these in your CI pipeline, especially DependencyCycleDetected.

<ol start="0">
  <li>Ok</li>
  <li>InvalidOption</li>
  <li>NoRootDirectorySpecified</li>
  <li>BuildModelFailed</li>
  <li>WriteToFileFailed</li>
  <li>DependencyCycleDetected</li>
</ol>

# Library Usage

In addition to the command line tool, `lakos` can also be used as a library.

Use `buildModel` to construct a `Model` object.

Use `Model.getOutput` to print the model in dot or JSON format.

Use `Model.toDirectedGraph` for further analysis with the `directed_graph` library.

See [example/example.dart](https://github.com/OlegAlexander/lakos/blob/master/example/example.dart).

# Inspiration

`lakos` is named after John Lakos, author of [_Large-Scale C++ Software Design_](https://www.amazon.com/Large-Scale-Software-Design-John-Lakos/dp/0201633620). This book presents:

- A graph-theoretic argument for keeping module dependencies acyclic.
- A set of "levelization techniques", such as Escalation and Demotion, to help avoid cyclic dependencies.
- A set of coupling metrics, such as the CCD, ACD, and the NCCD.
- An emphasis on physical design (files, folders) working in harmony with logical design (functions, classes).

# Similar Tools

- Dart: pubviz (for packages)
- C/C++: cinclude2dot
- JavaScript/TypeScript: madge, dependency-cruiser
- C#: NDepend
- Java: Sonargraph, JArchitect
- Python: pydeps
- Haskell: graphmod
