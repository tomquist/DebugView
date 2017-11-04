# DebugView
 
This playground visualizes functional programming with sequences using [Graphviz](http://www.graphviz.org/). You get a visualization of what happens to each element in each call.
 
## Prerequisites
 
Graphviz is required for rendering of the graph. Install it, e.g. using [Homebrew](https://brew.sh/):
 
 	brew install graphviz
 
## Supported operations
 
Currently the following operations are supported:
 * map
 * flatMap
 * filter
 * reduce
 * sorted
 * first(where:)
 * first
 * dropFirst
 * drop(while:)
 * prefix(while:)
 * reversed

## Demo

![Demo](https://github.com/tomquist/DebugView/raw/master/Demo.gif)