#pragma once

// nanovg must come first so CGColor.h reuses struct NVGcolor instead of redefining it
#include <mulle-nanovg/nanovg.h>

// MulleCG public headers
#ifdef __has_include
# if __has_include( "MulleCG/include.h")
#  include "MulleCG/include.h"
# endif
#endif

// nanovg-specific private headers (GL + nanovg)
#include "nanovg-specific/include-private.h"
