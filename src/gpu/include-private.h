#pragma once

// Pull in the nanovg-specific private headers (which include GL + nanovg)
#ifdef __has_include
# if __has_include( "../nanovg-specific/include-private.h")
#  include "../nanovg-specific/include-private.h"
# endif
#endif
