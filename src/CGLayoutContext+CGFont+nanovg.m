//
//  CGLayoutContext+CGFont+nanovg.m
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


// Font data
unsigned char   NotoSans_ttf[] =
#include "_NotoSans-VariableFont_wdth,wght.ttf.inc"
;
#define s_NotoSans_ttf   (sizeof( NotoSans_ttf) - 1)

unsigned char   NotoSans_Italic_ttf[] =
#include "_NotoSans-Italic-VariableFont_wdth,wght.ttf.inc"
;
#define s_NotoSans_Italic_ttf   (sizeof( NotoSans_Italic_ttf) - 1)

unsigned char   Noto_Symbols_ttf[] =
#include "_NotoSansSymbols-VariableFont_wght.ttf.inc"
;
#define s_Noto_Symbols_ttf   (sizeof( Noto_Symbols_ttf) - 1)

unsigned char   Noto_Symbols2_ttf[] =
#include "_NotoSansSymbols2-Regular.ttf.inc"
;
#define s_Noto_Symbols2_ttf   (sizeof( Noto_Symbols2_ttf) - 1)

unsigned char   Noto_Emoji_ttf[] =
#include "_NotoEmoji-VariableFont_wght.ttf.inc"
;
#define s_Noto_Emoji_ttf   (sizeof( Noto_Emoji_ttf) - 1)

unsigned char   entypo_ttf[] =
#include "_entypo.ttf.inc"
;
#define s_entypo_ttf   (sizeof( entypo_ttf) - 1)

unsigned char   NotoSansMono_Regular_ttf[] =
#include "_NotoSansMono-Regular.ttf.inc"
;
#define s_NotoSansMono_Regular_ttf   (sizeof( NotoSansMono_Regular_ttf) - 1)

#define sans_font_ttf             NotoSans_ttf
#define s_sans_font_ttf           s_NotoSans_ttf
#define sans_bold_font_ttf        NotoSans_ttf
#define s_sans_bold_font_ttf      s_NotoSans_ttf
#define sans_italic_font_ttf      NotoSans_Italic_ttf
#define s_sans_italic_font_ttf    s_NotoSans_Italic_ttf
#define symbols_font_ttf          Noto_Symbols_ttf
#define s_symbols_font_ttf        s_Noto_Symbols_ttf
#define symbols2_font_ttf         Noto_Symbols2_ttf
#define s_symbols2_font_ttf       s_Noto_Symbols2_ttf
#define emoji_font_ttf            Noto_Emoji_ttf
#define s_emoji_font_ttf          s_Noto_Emoji_ttf
#define icons_font_ttf            entypo_ttf
#define s_icons_font_ttf          s_entypo_ttf
#define mono_font_ttf             NotoSansMono_Regular_ttf
#define s_mono_font_ttf           s_NotoSansMono_Regular_ttf

static struct
{
   char                *name;
   struct mulle_data   data;
}
font_by_name[] =
{
   { .name = "sans",        { .bytes = sans_font_ttf,        .length = s_sans_font_ttf }},
   { .name = "sans-bold",   { .bytes = sans_bold_font_ttf,   .length = s_sans_bold_font_ttf }},
   { .name = "sans-italic", { .bytes = sans_italic_font_ttf, .length = s_sans_italic_font_ttf }},
   { .name = "mono",        { .bytes = mono_font_ttf,        .length = s_mono_font_ttf }},
   { .name = "symbols",     { .bytes = symbols_font_ttf,     .length = s_symbols_font_ttf }},
   { .name = "symbols2",    { .bytes = symbols2_font_ttf,    .length = s_symbols2_font_ttf }},
   { .name = "icons",       { .bytes = icons_font_ttf,       .length = s_icons_font_ttf }},
};


@implementation CGLayoutContext ( CGFontNanoVG)

@dependency CGLayoutContext( CGFont);

- (CGFont *) fallbackFont
{
   CGFont   *font;
   CGFontID fontID;

   font = mulle_map_get( &_fontMap, "fallback");
   if( font)
      return( font);

   fontID = CGContextCreateFontMem( self,
                                    "fallback",
                                    emoji_font_ttf,
                                    (int) s_emoji_font_ttf,
                                    0);
   font = [CGFont fontWithNameUTF8String:"fallback"
                                   fontID:fontID];
   mulle_map_insert( &_fontMap, "fallback", font);
   return( font);
}


- (CGFont *) fontWithNameUTF8String:(char *) s
{
   CGFont       *font;
   CGFont       *fallbackFont;
   CGFontID     fontID;
   NSUInteger   i, n;

   if( ! s)
   {
      s = _defaultFontName;
      if( ! s)
      {
         mulle_fprintf( stderr, "fontWithNameUTF8String: no name and no _defaultFontName\n");
         assert( 0);
         return( nil);
      }
   }

   font = mulle_map_get( &_fontMap, s);
   if( font)
      return( font);

   fontID = -1;
   n      = sizeof( font_by_name) / sizeof( font_by_name[ 0]);

   for( i = 0; i < n; i++)
   {
      if( ! strcmp( font_by_name[ i].name, s))
      {
         fontID = CGContextCreateFontMem( self,
                                          s,
                                          font_by_name[ i].data.bytes,
                                          (int) font_by_name[ i].data.length,
                                          0);
         break;
      }
   }

   if( fontID == -1)
   {
      fprintf( stderr, "fontWithNameUTF8String: \"%s\" not found in font_by_name (n=%lu)\n", s, (unsigned long) n);
      return( nil);
   }

   fallbackFont = [self fallbackFont];
   if( fallbackFont)
      CGContextAddFallbackFontId( self, fontID, [fallbackFont fontID]);

   font = [CGFont fontWithNameUTF8String:s
                                   fontID:fontID];
   assert( font);
   mulle_map_insert( &_fontMap, s, font);
   return( font);
}


- (void *) internalFontHandleOfFont:(CGFont *) font
{
   if( ! font)
      return( NULL);
   return( CGContextGetFontHandle( self, [font fontID]));
}


- (void *) internalFontHandle
{
   return( CGContextGetFontHandle( self, -1));
}

@end
