<p align="center"><img src="https://user-images.githubusercontent.com/42989765/94976346-8c142480-04c9-11eb-920f-0d3412f1f042.png" alt="Example dependency graph" width="70%"/></p>

`lakos` is a command line tool and library that can:

- Visualize internal Dart library dependencies in Graphviz `dot`.
- Detect dependency cycles.
- Identify orphans.
- Compute useful dependency graph metrics.

# Command Line Usage

```console
Usage: lakos [options] <root-directory>

-f, --format=<FORMAT>        Output format.
                             [dot (default), json]

-o, --output=<FILE>          Save output to a file instead of printing it.
                             (defaults to "STDOUT")

    --[no-]tree              Show directory structure as subgraphs.
                             (defaults to on)

-m, --[no-]metrics           Compute and show global metrics.
                             (defaults to --no-metrics)

    --[no-]node-metrics      Show node metrics. Only works when --metrics is true.
                             (defaults to --no-node-metrics)

-i, --ignore=<GLOB>          Exclude files and directories with a glob pattern.
                             (defaults to "!**")

    --[no-]cycles-allowed    With --no-cycles-allowed lakos runs normally
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

Pass output directly to Graphviz `dot` in one line (much more useful):

```console
lakos . | dot -Tpng -Gdpi=200 -o example.png
```

Save output to a dot file first and then generate an SVG using Graphviz `dot`:

```console
lakos -o example.dot .
dot -Tsvg example.dot -o example.svg
```

## Notes

- Nodes are internal Dart libraries. Edges are "uses" or "depends on" relationships.
- Exports are drawn with a dashed edge.
- Orphan nodes are octagons (with `--metrics`).
- Only `import` and `export` directives are supported; `library` and `part` are not.
- Only libraries under the root-directory are shown; Dart core and external packages are not.

## More Examples

`lakos` run on itself with metrics, ignoring tests.

```console
lakos -o dot_images/lakos.metrics_no_test.dot -m -i test/** .
```

<p align="center"><img src="https://user-images.githubusercontent.com/42989765/94977052-eada9d80-04cb-11eb-98fe-9e27886923df.png" alt="Lakos run on itself with metrics, ignoring tests." width="70%"/></p>

Show node metrics.

```console
lakos -o dot_images/args.no_test_node_metrics.dot -m -i test/** --node-metrics /root/.pub-cache/hosted/pub.dartlang.org/args-1.6.0
```

<p align="center"><img src="https://user-images.githubusercontent.com/42989765/94977108-2c6b4880-04cc-11eb-9039-433a7390d42d.png" alt="Show node metrics." width="90%"/></p>

No directory tree.

```console
lakos --no-tree -o dot_images/string_scanner.no_test_no_tree.dot -i test/** /root/.pub-cache/hosted/pub.dartlang.org/string_scanner-1.0.5
```

<p align="center"><img src="https://user-images.githubusercontent.com/42989765/94977170-72281100-04cc-11eb-9a92-ae932f368ca8.png" alt="No directory tree." width="70%"/></p>

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

## Ignoring Multiple Directories

Use curly brackets in the glob pattern to ignore multiple folders:

```console
lakos -i "{lib/extensions/**,test/**}" .
```

## Styling Graphviz

You may override the default style attributes directly through the Graphviz `dot` command line arguments. In Graphviz, the style attributes are divided into 3 sections: `graph`, `node`, and `edge`. To override a specific attribute, use the `-G`, `-N`, and `-E` prefix, respectively. For example, `-Nfillcolor=white` will set the node fill color to white. All the Graphviz style attributes can be found [here](https://graphviz.org/doc/info/attrs.html).

Example of left to right layout.

```console
dot -Tpng dot_images/test.lr.dot -Grankdir=LR -Gdpi=200 -o dot_images/test.lr.png
```

<p align="center"><img src="https://user-images.githubusercontent.com/42989765/94977365-3f324d00-04cd-11eb-8e05-89b58da653f7.png" alt="Left to right layout." width="80%"/></p>

Gradient node color.

```console
dot -Tpng dot_images/string_scanner.gradient.dot -Gdpi=200 -Nfillcolor=steelblue2:steelblue4 -Nfontcolor=white -Ngradientangle=270 -o dot_images/string_scanner.gradient.png
```

<p align="center"><img src="https://user-images.githubusercontent.com/42989765/94977486-bb2c9500-04cd-11eb-80b9-5f23401cd2a4.png" alt="Gradient node color." width="60%"/></p>

## Convert to GML

Still can't get enough graph visualization goodness? Try this!

```console
lakos -i test/** /root/.pub-cache/hosted/pub.dartlang.org/test-1.15.3 | gv2gml -o dot_images/test.gml
```

`gv2gml` converts dot format into [GML format](https://en.wikipedia.org/wiki/Graph_Modelling_Language), which you can open in yEd, Gephi, Cytoscape, etc.

<p align="center"><img src="https://user-images.githubusercontent.com/42989765/93006268-f3fcce00-f50e-11ea-9f96-e6ce9c8cffbb.png" alt="GML file imported into yEd." width="100%"/></p>

## Global Metrics

Use `--metrics` to compute and show these.

**isAcyclic:** True if the library dependencies form a directed acyclic graph (DAG). False if the graph contains dependency cycles. True is better.

**firstCycle:** The first dependency cycle found if the graph is not acyclic. Available in the JSON output.

**numNodes:** Number of Dart libraries (nodes) in the graph.

**numEdges:** Number of edges (dependencies) in the graph.

**avgDegree:** The average number of incoming/outgoing edges per node. Average degree (directed graph) = numEdges / numNodes. This metric can compare graphs of different sizes. Similar to the ACD, the average degree can be interpreted as the average number of nodes that _will_ need to change when one node changes. Lower is better.

**numOrphans:** Number of Dart libraries that have no imports and are imported nowhere. (inDegree and outDegree are 0.)

**ccd:** The Cumulative Component Dependency (CCD) is the sum of all Component Dependencies. The CCD can be interpreted as the total "coupling" of the graph. Lower is better.

**acd:** The Average Component Dependency (ACD). ACD = CCD / numNodes. Similar to the avgDegree, the ACD can be interpreted as the average number of nodes that _may_ need to change when one node changes. Lower is better.

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
- Swift: SwiftAlyzer
