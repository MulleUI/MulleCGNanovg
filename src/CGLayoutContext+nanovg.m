//
//  CGLayoutContext+nanovg.m
//  MulleCGNanovg
//
//  Copyright (c) 2026 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
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

   face = [font nameUTF8String];
   face = face ? face : self->_defaultFontName;

   nvgFontFace( _fontContext, face);
   _hasLoadedFont = YES;
}

@end
