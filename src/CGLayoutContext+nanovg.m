//
// Copyright (c) 2023 Nat!, Mulle kybernetiK
//
#import "CGLayoutContext+nanovg.h"

#import "import-private.h"

#include "nanowrap-private.h"

#import <MulleCG/CGContext+DebugPrivate.h>
#import "CGContext+GPU.h"
#import "CGContext+nanovg.h"
#import "CGContext+Drawing.h"
#import "CGLayoutContext+CGFont.h"
#import "_MulleCGBackend.h"


@implementation CGLayoutContext( nanovg)

- (void) _initBackend
{
   // if _cgBackend.context is clear, then we are a not a subclass so we
   // init as a real CGLayoutContext,
   if( ! _cgBackend.context)
   {
      _backendFlags |= NVG_FONT_ONLY;
#ifdef DEBUG
      _backendFlags |= NVG_DEBUG;
#endif
      [self _initNanovg];
   }
}


- (void) _doneBackend
{
   [self _doneNanovg];
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

   fontID = mvgCreateFontMem( _cgBackend.context, name, data.bytes, (int) data.length, 0);
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

   fontID = mvgCreateFont( _cgBackend.context, name, filename);
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

   nvgFontFace( _cgBackend.context, face);
   _hasLoadedFont = YES;
}

@end
