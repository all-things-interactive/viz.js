#include <gvc.h>
#include <stdlib.h>
#include <emscripten.h>

extern int Y_invert;

// plugin/core/gvplugin_core.c
extern gvplugin_installed_t gvdevice_dot_types[];
extern gvplugin_installed_t gvrender_dot_types[];
extern gvplugin_installed_t gvdevice_json_types[];
extern gvplugin_installed_t gvrender_json_types[];

static gvplugin_api_t apis[] = {
    {API_device, gvdevice_dot_types},
    {API_device, gvdevice_json_types},

    {API_render, gvrender_dot_types},
    {API_render, gvrender_json_types},

    {(api_t)0, 0},
};

static gvplugin_library_t gvplugin_core_LTX_library = { "core", apis };

extern gvplugin_library_t gvplugin_dot_layout_LTX_library;

static char *g_error = NULL;

static int vizErrorf(char *buf) {
  // the buffer is reused for next error message, don't free
  g_error = buf;
  return 0;
}

struct viz_result {
  char *result;
  unsigned int result_length;
  char *error;
};

int vizRender(
  struct viz_result *viz_result,
  const char *engine, const char *format,
  const char *input,
  size_t input_length,
  int opt_y_invert
) {

  static GVC_t *context;
  Agraph_t *graph;
  int rc;

  if (!context) {
    context = gvContext();
    gvAddLibrary(context, &gvplugin_core_LTX_library);
    gvAddLibrary(context, &gvplugin_dot_layout_LTX_library);

    agseterr(AGERR);
    agseterrf(vizErrorf);
  }

  viz_result->result = NULL;
  Y_invert = opt_y_invert;

  if (!(graph = agmemread(input))) {
    rc = -1;
    goto cleanup;
  }

  if ((rc = gvLayout(context, graph, engine)) != 0) goto cleanup_graph;

  rc = gvRenderData(
    context, graph, format,
    &viz_result->result, &viz_result->result_length);

  gvFreeLayout(context, graph);
cleanup_graph:
  agclose(graph);
cleanup:
  viz_result->error = g_error;
  return rc;
}
