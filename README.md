# Viz.js on a diet

Viz.js fork. Only ships `dot` layout engine and supports `JSON` output format.
Compiled to WebAssembly for WebWorker environment.  Omitting support for other
environments and not including filesystem emulation makes the generated
JavaScript glue ridiculously thin.

API-wize, it is incompatible with vanilla `viz.js`. Usage:

```JavaScript
require('graphviz.js').render('digraph{a->b}', function(error, resultString) {
  ...
});
```

## Building

Running `make` will produce `graphviz.js` and `graphviz.wasm`. You have to ship both.
Please install [Emscripten SDK](https://emscripten.org/docs/getting_started/downloads.html#sdk-download-and-install) first.

## Improvements to vanilla Vis.jz

No longer necessary to recreate a renderer instance after a failed
call.  And there's no such thing as a renderer instance anymore.
