//
// CGBackend+nanovg.h
// MulleCGNanovg
//
// Convenience accessors for the nanovg backend.
//
#ifndef cgbackend_nanovg_h__
#define cgbackend_nanovg_h__

#include <MulleCG/CGBackend.h>
#include <MulleCG/CGFunctionTable.h>

// Cast _cgBackend.functions to the full type
static inline struct CGFunctionTable *
   CGBackendGetFunctions( struct CGBackend *backend)
{
   return( &backend->functions);
}

#endif
