GRAPHVIZ_SOURCE_URL = "https://graphviz.gitlab.io/pub/graphviz/stable/SOURCES/graphviz.tar.gz"
GRAPHVIZ_DIST = $(abspath ./build/graphviz-dist)

.PHONY: all clean

all: graphviz.js graphviz.wasm

clean:
	rm -rf build graphviz.js graphviz.wasm

graphviz.js: src/pre-module.js build/graphviz.js src/post-module.js
	(echo '/* graphviz' $$(\
		awk '/PACKAGE_VERSION/{print $$3}' build/graphviz-src/graphviz_version.h | \
		sed -e 's/"//g' \
	) ' */'; cat $^) > $@

graphviz.wasm: build/graphviz.js
	cp build/$@ $@

build/graphviz.js: src/viz.c build/.graphviz-dist
	emcc -Oz --memory-init-file 0 \
		-s ENVIRONMENT=worker -s MODULARIZE=0 -s FILESYSTEM=0 \
		-s NO_DYNAMIC_EXECUTION=1 -s EXPORTED_FUNCTIONS="['_vizRender', '_malloc', '_free']" \
		-s EXPORTED_RUNTIME_METHODS="['stackSave', 'stackAlloc', 'stackRestore', \
			'UTF8ToString', 'lengthBytesUTF8', 'stringToUTF8']" \
		-o $@ $< \
		-I$(GRAPHVIZ_DIST)/include -I$(GRAPHVIZ_DIST)/include/graphviz \
		-L$(GRAPHVIZ_DIST)/lib -L$(GRAPHVIZ_DIST)/lib/graphviz \
		-lgvplugin_core -lgvplugin_dot_layout -lcgraph -lgvc -lgvpr -lpathplan -lxdot -lcdt

build/.graphviz-dist: build/.graphviz-src
	mkdir -p build/graphviz-dist
	cd build/graphviz-src && ./configure
	cd build/graphviz-src/lib/gvpr && make  mkdefs CFLAGS="-w"
	mkdir -p build/graphviz-src/FEATURE
	cp hacks/FEATURE/sfio hacks/FEATURE/vmalloc build/graphviz-src/FEATURE
	cd build/graphviz-src && emconfigure ./configure \
		--without-sfdp --disable-ltdl --enable-static --disable-shared \
		--prefix=$(GRAPHVIZ_DIST) --libdir=$(GRAPHVIZ_DIST)/lib CFLAGS="-Oz -w"
	cd build/graphviz-src && emmake make  lib plugin
	cd build/graphviz-src/lib && emmake make  install
	cd build/graphviz-src/plugin && emmake make  install
	touch $@

build/.graphviz-src: build/graphviz.tar.gz
	mkdir -p build/graphviz-src
	tar -zxf $^ --strip-components 1 -C build/graphviz-src
	patch -si hacks/gvrender_core_json.c.patch \
		build/graphviz-src/plugin/core/gvrender_core_json.c
	patch -si hacks/late_double.patch \
		build/graphviz-src/lib/common/utils.c
	touch $@

build/graphviz.tar.gz:
	mkdir -p build
	curl --fail --location $(GRAPHVIZ_SOURCE_URL) -o $@
