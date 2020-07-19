# Lakos

A Dart tool for [modular programming](https://en.wikipedia.org/wiki/Modular_programming).

- Visualize Dart library dependencies in Graphviz `dot`.
- Detect dependency cycles between libraries.
- Identify orphan libraries.
- Compute the Normalized Cumulative Component Dependency (NCCD) metric.

## Inspiration

The tool is named after John Lakos, author of Large-Scale C++ Software Design. In this book, Mr. Lakos presents:

- A graph-theoretic argument for keeping library dependencies acyclic.
- A set of "levelization techniques", such as Escalation and Demotion, to help avoid cyclic dependencies.
- A set of coupling metrics, such as the CCD, ACD, and the NCCD.
- An emphasis on physical design (files, folders, libraries) working in harmony with logical design (types, functions, classes).

## Similar Tools

- cinclude2dot (C/C++)
