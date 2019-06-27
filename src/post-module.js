  return Module;
};

function render(input, options, callback) {
  if (!options) {
    options = {};
  } else if (callback===undefined && typeof options==='function') {
    callback = options;
    options = {};
  }
  if (typeof callback!=='function') callback(); // fail early
  doRender(input, options, callback);
}

var pending = [];
function doRender(input, options, callback) {
  pending.push([input, options, callback]);
}

var instance = new Module({
  onRuntimeInitialized: function () {
    doRender = function(input, o, callback) {
      var stack = instance.stackSave();
      var inputPtr = 0;
      try {
        input = input + '';
        var engine = (o.engine===undefined ? 'dot' : o.engine) + '';
        var format = (o.format===undefined ? 'json' : o.format) + '';
        var yInvert = o.yInvert===undefined ? 1 : +!!o.yInvert;

        var vizResultPtr = instance.stackAlloc(12);
        var enginePtr = instance.stackAlloc((engine.length<<2)+1);
        var formatPtr = instance.stackAlloc((format.length<<2)+1);
        var inputSize = instance.lengthBytesUTF8(input)+1;

        if (!(inputPtr = instance._malloc(inputSize)))
          throw new Error('Input too big');

        instance.stringToUTF8(engine, enginePtr, (engine.length<<2)+1);
        instance.stringToUTF8(format, formatPtr, (format.length<<2)+1);

        var rc = instance._vizRender(
          vizResultPtr, enginePtr, formatPtr,
          inputPtr, instance.stringToUTF8(input, inputPtr, inputSize),
          yInvert);

        var resultPtr = instance.HEAPU32[vizResultPtr>>2];
        var result = instance.UTF8ToString(
          resultPtr, instance.HEAPU32[(vizResultPtr>>2)+1]);
        var errorPtr = instance.HEAPU32[(vizResultPtr>>2)+2];

        instance.stackRestore(stack);
        if (resultPtr) instance._free(resultPtr);
        instance._free(inputPtr); inputPtr = 0;

        if (rc !== 0)
          throw new Error(instance.UTF8ToString(errorPtr));

        callback(null, result);

      } catch (error) {
        instance.stackRestore(stack);
        if (inputPtr) instance._free(inputPtr);
        callback(error);
      }
    };
    pending.splice(0).forEach(function(a) {
      doRender(a[0], a[1], a[2]);
    });
  }
});

if (typeof exports === 'object' && typeof module !== 'undefined') {
  module.exports = { render: render };
} else if (typeof define === 'function' && define.amd) {
  define(function() { return { render: render }; });
}

})(typeof self !== 'undefined' ? self : this);
