<img src="https://user-images.githubusercontent.com/42989765/90343870-55da1e80-dfc9-11ea-8bfb-682185c9ec4e.png" alt="Example dependency graph" width="100%"/>

`lakos` is a command line tool and library that can:

- Visualize Dart library dependencies in Graphviz dot.
- Detect dependency cycles.
- Identify orphans.
- Compute the Cumulative Component Dependency (CCD) and related metrics.

# Command Line Usage

```console
Usage: lakos [options] <root-directory>

-f, --format=<FORMAT>        Output format.
                             [dot (default), json]

-o, --output=<FILE>          Save output to a file instead of printing it.
                             (defaults to "STDOUT")

    --[no-]tree              Show directory structure as subgraphs.
                             (defaults to on)

    --[no-]metrics           Compute and show global metrics.
                             (defaults to on)

    --[no-]node-metrics      Show node metrics. Only works when --metrics is true.
                             --no-node-metrics is the default.

-i, --ignore=<GLOB>          Exclude files and directories with a glob pattern.
                             (defaults to "!**")

-l, --layout=<TB>            Graph layout direction. AKA "rankdir" in Graphviz.

          [BT]               bottom to top
          [LR]               left to right
          [RL]               right to left
          [TB] (default)     top to bottom

    --[no-]cycles-allowed    Runs normally but exits with a non-zero exit code
                             if a dependency cycle is detected.
                             Only works when --metrics is true.
                             Useful for CI builds.
                             --no-cycles-allowed is the default.
```

## Examples

Print dot graph for current directory (not very useful):

```console
lakos .
```

Pass output directly to Graphviz dot in one line (a lot more useful):

```console
lakos . | dot -Tpng -Gdpi=300 -o example.png
```

Save output to a dot file first and then generate an SVG using Graphviz dot:

```console
lakos -o example.dot .
dot -Tsvg example.dot -o example.svg
```

## Notes

- Exports are drawn with a dashed edge.
- Orphan nodes are bold.
- Only `import` and `export` directives are supported; `library` and `part` are not.
- Only libraries under the root-directory are shown; Dart core and external packages are not.

## Global Metrics

Use `--metrics` to compute and show these.

**isAcyclic:** True if the library dependencies form a directed acyclic graph (DAG). False if the graph contains dependency cycles. True is better.

**firstCycle:** The first dependency cycle found if the graph is not acyclic. Available in the JSON output.

**numNodes:** Number of Dart libraries (nodes) in the graph.

**numOrphans:** Number of Dart libraries that have no imports and are imported nowhere. (inDegree and outDegree are 0.)

**ccd:** The Cumulative Component Dependency (CCD) is the sum of all Component Dependencies. The CCD can be interpreted as the total "coupling" of the graph. Lower is better.

**acd:** The Average Component Dependency (ACD). ACD = CCD / numNodes. The ACD can be interpreted as the average number of nodes that will need to change when one node changes. Lower is better.

**acdp:** The ACD as a percentage of numNodes. ACDP = (ACD / numNodes) \* 100 = (CCD / numNodes^2) \* 100. The ACDP can be interpreted as the average percentage of nodes that will need to change when one node changes. The ACDP is my original research. Lower is better.

**nccd:** The Normalized Cumulative Component Dependency. This is the CCD divided by a CCD of a binary tree of the same size. It's the only metric here that can compare graphs of different sizes. If the NCCD is below 1.0, the graph is "horizontal". If the NCCD is above 1.0, the graph is "vertical". If the NCCD is above 2.0, the graph probably contains cycles. Lower is better.

**totalSloc:** Total Source Lines of Code for all nodes.

**avgSloc:** The average SLOC per node. The average SLOC should arguably be kept within some Goldilocks range: not too big and not too small.

## Node Metrics

Use `--node-metrics` to show these.

**cd:** The Component Dependency (CD) is the number of nodes a particular node depends on directly or transitively, including itself.

**inDegree:** The number of nodes that depend on this node. (Number of incoming edges.)

**outDegree:** The number of nodes this node depends on. (Number of outgoing edges.)

**instability:** A node metric by Robert C. Martin related to the Stable-Dependencies Principle: Depend in the direction of stability. Instability = outDegree / (inDegree + outDegree). This yields a value from 0 to 1, where 0 means 100% stable and 1 means 100% unstable. In general, node instability should decrease in the direction of dependency. In other words, lower level nodes should be more stable and more reusable than higher level nodes.

**sloc:** Source Lines of Code is the number of lines of code ignoring comments and blank lines. Note: my SLOC counter function doesn't deal correctly with comments inside multi-line strings or multi-line comments in the middle of code.

## Exit Codes

Use these in your CI builds, especially DependencyCycleDetected.

<ol start="0">
  <li>Ok</li>
  <li>InvalidOption</li>
  <li>NoRootDirectorySpecified</li>
  <li>BuildModelFailed</li>
  <li>WriteToFileFailed</li>
  <li>DependencyCycleDetected</li>
</ol>

## More Examples

Lakos run on itself, ignoring tests.

```console
lakos -o dot_images/lakos.no_test.dot -i test/** .
```

<img src="https://user-images.githubusercontent.com/42989765/90344186-119c4d80-dfcc-11ea-87dc-cff08f768cbc.png" alt="Lakos run on itself, ignoring tests." width="100%"/>

No tests, show node metrics.

```console
lakos -o dot_images/glob.no_test_node_metrics.dot -i test/** --node-metrics /root/.pub-cache/hosted/pub.dartlang.org/glob-1.2.0
```

<img src="https://user-images.githubusercontent.com/42989765/90344206-532cf880-dfcc-11ea-86a7-03e8cf4c37c0.png" alt="No tests, show node metrics." width="100%"/>

No tests, no tree, no metrics.

```console
lakos --no-tree --no-metrics -o dot_images/string_scanner.no_test_no_tree_no_metrics.dot -i test/** /root/.pub-cache/hosted/pub.dartlang.org/string_scanner-1.0.5
```

<img src="https://user-images.githubusercontent.com/42989765/90344305-67252a00-dfcd-11ea-898c-aa5bd2b302af.png" alt="No tests, no tree, no metrics." width="100%"/>

No tests, no metrics, left to right layout.

```console
lakos -o dot_images/test.no_test_no_metrics_lr.dot -i test/** --no-metrics -l LR /root/.pub-cache/hosted/pub.dartlang.org/test-1.15.3
```

<img src="https://user-images.githubusercontent.com/42989765/90344424-87091d80-dfce-11ea-9810-e2895d170366.png" alt="No tests, no metrics, left to right layout." width="100%"/>

A graph with circular dependencies.

```console
lakos -o dot_images/path.no_test.dot -i test/** /root/.pub-cache/hosted/pub.dartlang.org/path-1.7.0
```

<img src="https://user-images.githubusercontent.com/42989765/90344595-e9aee900-dfcf-11ea-9166-4f47e2313ce7.png" alt="A graph with circular dependencies." width="100%"/>

Example JSON output:

```console
lakos -f json -o dot_images/pub_cache.no_test.json -i test/** /root/.pub-cache/hosted/pub.dartlang.org/pub_cache-0.2.3
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
    "orphans": [],
    "ccd": 7,
    "acd": 2.33,
    "acdp": 77.78,
    "nccd": 1.4,
    "totalSloc": 271,
    "avgSloc": 90.33
  }
}
```

</details>

# Library Usage

In addition to the command line tool, `lakos` can also be used as a library.

Use `buildModel` to construct a `Model` object.

Use `convertModelToDirectedGraph` for further analysis with the `directed_graph` library.

See example/example.dart.

# Inspiration

`lakos` is named after John Lakos, author of _Large-Scale C++ Software Design_. This book presents:

- A graph-theoretic argument for keeping module dependencies acyclic.
- A set of "levelization techniques", such as Escalation and Demotion, to help avoid cyclic dependencies.
- A set of coupling metrics, such as the CCD, ACD, and the NCCD.
- An emphasis on physical design (files, folders) working in harmony with logical design (functions, classes).

# Similar Tools

- Dart: pubviz
- C/C++: cinclude2dot
- JavaScript/TypeScript: madge, dependency-cruiser
- C#: NDepend
- Java: Sonargraph, JArchitect
- Python: pydeps
- Haskell: graphmod
