//
// Copyright (c) 2023 Nat!, Mulle kybernetiK
//
#import "import-private.h"

#import "CGLayoutContext+nanovg.h"
#import "CGContext+GPUFuture.h"
#import "CGContext+nanovg.h"
#import "CGLayoutContext+CGFont.h"

#include "nanowrap-private.h"

extern mulle_thread_mutex_t   CGLayoutContextFreeTypeLock;


@implementation CGLayoutContext( nanovg)


- (void) _initFontNanovg
{
   NVGparams   params;

   memset( &params, 0, sizeof( params));
   params.contextType = NVG_FONT_CONTEXT;
   params.cStates     = 32;

   mulle_thread_mutex_do( CGLayoutContextFreeTypeLock)
   {
      _fontContext = nvgCreateInternal( &params);
   }
   assert( _fontContext);
}


- (void) _initFontBackend
{
   _fontFunctions = CGNanoVGFontFunctionTable;
   // CGContext pre-sets _fontContext before calling super init — just use it
   if( _fontContext)
      return;

   // standalone CGLayoutContext — create our own font-only nanovg context
   [self _initFontNanovg];
   _ownsFontContext = YES;
}


- (void) _doneFontBackend
{
   if( _fontContext && _ownsFontContext)
   {
      mulle_thread_mutex_do( CGLayoutContextFreeTypeLock)
      {
         nvgDeleteInternal( _fontContext);
      }
   }
   _fontContext     = NULL;
   _ownsFontContext = NO;
}


// just for a stupid compiler warning


- (CGFont *) fontWithCData:(struct mulle_data) data
        fontNameUTF8String:(char *) name
{
   CGFont    *font;
   CGFontID  fontID;

   assert( name);

   font = mulle_map_get( &_fontMap, name);
   if( font)
      return( font);

   fontID = mvgCreateFontMem( _fontContext, name, data.bytes, (int) data.length, 0);
   if( fontID == -1)
      return( nil);

   font = [CGFont fontWithNameUTF8String:name
                                  fontID:fontID];

   mulle_map_insert( &_fontMap, name, font);
   return( font);
}


- (CGFont *) fontWithContentsOfFileWithFileRepresentationString:(char *) filename
                                             fontNameUTF8String:(char *) name
{
   CGFont     *font;
   CGFontID   fontID;

   assert( filename);
   assert( name);

   font = mulle_map_get( &_fontMap, name);
   if( font)
      return( font);

   fontID = mvgCreateFont( _fontContext, name, filename);
   if( fontID == -1)
      return( nil);

   font = [CGFont fontWithNameUTF8String:name
                                  fontID:fontID];
   mulle_map_insert( &_fontMap, name, font);
   return( font);
}


- (void) useFont:(CGFont *) font
{
   char     *face;

   // TODO: maybe boobytrappe mvgFontFace to make it unusable as one must
   //       use [font nameUTF8String] to get the proper string...
   assert( self->_defaultFontName);
   face = font ? [font nameUTF8String] : self->_defaultFontName;

   nvgFontFace( _fontContext, face);
   _hasLoadedFont = YES;
}

@end
