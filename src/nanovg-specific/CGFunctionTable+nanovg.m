//
// CGFunctionTable+nanovg.c
// MulleCGNanoVG
//
// nanovg backend vtable. Each entry wraps the corresponding mvg* inline
#import "import-private.h"
#include "microvg/nanowrap-private.h"
// by casting void *vg to NVGcontext *.
//
#include <MulleCG/CGFunctionTable.h>
#include "CGPath+nanovg.h"

#define VG   ((NVGcontext *) vg)

static void        _beginFrame( void *vg, CGSize s, CGFloat r)                                          { mvgBeginFrame( VG, s, r); }
static void        _cancelFrame( void *vg)                                                               { mvgCancelFrame( VG); }
static void        _endFrame( void *vg)                                                                  { mvgEndFrame( VG); }

static void        _save( void *vg)                                                                      { mvgSave( VG); }
static void        _restore( void *vg)                                                                   { mvgRestore( VG); }
static void        _reset( void *vg)                                                                     { mvgReset( VG); }

static void        _globalCompositeOperation( void *vg, NSInteger op)                                   { mvgGlobalCompositeOperation( VG, op); }
static void        _globalCompositeBlendFunc( void *vg, NSUInteger sf, NSUInteger df)                   { mvgGlobalCompositeBlendFunc( VG, sf, df); }
static void        _globalCompositeBlendFuncSeparate( void *vg, NSUInteger sr, NSUInteger dr, NSUInteger sa, NSUInteger da) { mvgGlobalCompositeBlendFuncSeparate( VG, sr, dr, sa, da); }

static void        _resetTransform( void *vg)                                                            { mvgResetTransform( VG); }
static void        _transform( void *vg, CGAffineTransform *x)                                          { mvgTransform( VG, x); }
static CGAffineTransform _currentTransform( void *vg)                                                   { return mvgCurrentTransform( VG); }
static void        _translate( void *vg, CGPoint p)                                                     { mvgTranslate( VG, p); }
static void        _rotate( void *vg, CARotation r)                                                     { mvgRotate( VG, r); }
static void        _scale( void *vg, CGVector v)                                                        { mvgScale( VG, v); }
static void        _skewX( void *vg, CAAngle a)                                                         { mvgSkewX( VG, a); }
static void        _skewY( void *vg, CAAngle a)                                                         { mvgSkewY( VG, a); }

static CGTextureID _createImage( void *vg, char *f, NSUInteger fl)                                      { return mvgCreateImage( VG, f, fl); }
static CGTextureID _createImageMem( void *vg, NSInteger fl, void *d, size_t n)                          { return mvgCreateImageMem( VG, fl, d, n); }
static CGTextureID _createImageRGBA( void *vg, NSInteger w, NSInteger h, NSUInteger fl, void *d)        { return mvgCreateImageRGBA( VG, w, h, fl, d); }
static void        _updateImage( void *vg, CGTextureID img, void *d)                                    { mvgUpdateImage( VG, img, d); }
static CGPixelSize _imageSize( void *vg, CGTextureID img)                                               { return mvgImageSize( VG, img); }
static void        _deleteImage( void *vg, CGTextureID img)                                             { mvgDeleteImage( VG, img); }

static void        _scissor( void *vg, CGRect r)                                                        { mvgScissor( VG, r); }
static void        _intersectScissor( void *vg, CGRect r)                                               { mvgIntersectScissor( VG, r); }
static void        _resetScissor( void *vg)                                                             { mvgResetScissor( VG); }

static void        _shapeAntiAlias( void *vg, BOOL e)                                                   { mvgShapeAntiAlias( VG, e); }
static void        _bezierTessellation( void *vg, CGTessellation m)                                     { mvgBezierTessellation( VG, m); }
static void        _strokeColor( void *vg, CGColor c)                                                   { mvgStrokeColor( VG, c); }
static void        _fillColor( void *vg, CGColor c)                                                     { mvgFillColor( VG, c); }
static void        _miterLimit( void *vg, CGFloat l)                                                    { mvgMiterLimit( VG, l); }
static void        _strokeWidth( void *vg, CGFloat s)                                                   { mvgStrokeWidth( VG, s); }
static void        _lineCap( void *vg, NSInteger c)                                                     { mvgLineCap( VG, c); }
static void        _lineJoin( void *vg, NSInteger j)                                                    { mvgLineJoin( VG, j); }
static void        _globalAlpha( void *vg, CGFloat a)                                                   { mvgGlobalAlpha( VG, a); }

static void        _beginPath( void *vg)                                                                 { mvgBeginPath( VG); }
static void        _moveTo( void *vg, CGPoint p)                                                        { mvgMoveTo( VG, p); }
static void        _lineTo( void *vg, CGPoint p)                                                        { mvgLineTo( VG, p); }
static void        _bezierTo( void *vg, CGPoint c1, CGPoint c2, CGPoint p)                              { mvgBezierTo( VG, c1, c2, p); }
static void        _quadTo( void *vg, CGPoint c, CGPoint p)                                             { mvgQuadTo( VG, c, p); }
static void        _arcTo( void *vg, CGPoint t1, CGPoint t2, CGFloat r)                                 { mvgArcTo( VG, t1, t2, r); }
static void        _closePath( void *vg)                                                                 { mvgClosePath( VG); }
static void        _pathWinding( void *vg, CGPathFillStyle s)                                           { mvgPathWinding( VG, s); }

static void        _rect( void *vg, CGRect r)                                                           { mvgRect( VG, r); }
static void        _roundedRect( void *vg, CGRect r, CGFloat rad)                                       { mvgRoundedRect( VG, r, rad); }
static void        _roundedRectVarying( void *vg, CGRect r, struct MulleCornerInsets i)                 { mvgRoundedRectVarying( VG, r, i); }
static void        _ellipse( void *vg, CGPoint c, CGFloat rx, CGFloat ry)                               { mvgEllipse( VG, c, rx, ry); }
static void        _arc( void *vg, CACircle c, CAAngle a, CARotation rot)                               { mvgArc( VG, c, a, rot); }
static void        _arcRadians( void *vg, CACircle c, CGFloat r1, CGFloat r2, CARotationDirection dir)  { nvgArc( VG, CACircleGetCenter(c).x, CACircleGetCenter(c).y, CACircleGetRadius(c), r1, r2, dir); }
static void        _fill( void *vg)                                                                      { mvgFill( VG); }
static void        _stroke( void *vg)                                                                    { mvgStroke( VG); }
static void        _addCGPath( void *vg, struct CGPath *path)                                           { mvgAddCGPath( VG, (CGPath *) path); }

static void   _setFillLinearGradient( void *vg, CGPoint s, CGPoint e, CGColor sc, CGColor ec)            { mvgFillPaint( VG, mvgLinearGradient( VG, s, sc, e, ec)); }
static void   _setStrokeLinearGradient( void *vg, CGPoint s, CGPoint e, CGColor sc, CGColor ec)          { mvgStrokePaint( VG, mvgLinearGradient( VG, s, sc, e, ec)); }
static void   _setFillBoxGradient( void *vg, CGRect r, CGFloat cr, CGColor c, CGFloat f, CGColor fc)    { mvgFillPaint( VG, mvgBoxGradient( VG, r, cr, c, f, fc)); }
static void   _setStrokeBoxGradient( void *vg, CGRect r, CGFloat cr, CGColor c, CGFloat f, CGColor fc)  { mvgStrokePaint( VG, mvgBoxGradient( VG, r, cr, c, f, fc)); }
static void   _setFillRadialGradient( void *vg, CACircle ci, CGColor oc, CGFloat ir, CGColor ic)        { mvgFillPaint( VG, mvgRadialGradient( VG, ci, oc, ir, ic)); }
static void   _setStrokeRadialGradient( void *vg, CACircle ci, CGColor oc, CGFloat ir, CGColor ic)      { mvgStrokePaint( VG, mvgRadialGradient( VG, ci, oc, ir, ic)); }
static void   _setFillImagePattern( void *vg, CGTextureID t, CGRect r, CARotation rot, CGFloat a)       { mvgFillPaint( VG, mvgImagePattern( VG, t, r, rot, a)); }
static void   _setStrokeImagePattern( void *vg, CGTextureID t, CGRect r, CARotation rot, CGFloat a)     { mvgStrokePaint( VG, mvgImagePattern( VG, t, r, rot, a)); }

static CGFontID    _createFont( void *vg, char *name, char *file)                                       { return mvgCreateFont( VG, name, file); }
static CGFontID    _createFontMem( void *vg, char *name, void *d, size_t len, BOOL free)                { return mvgCreateFontMem( VG, name, d, len, free); }
static CGFontID    _findFont( void *vg, char *name)                                                     { return mvgFindFont( VG, name); }
static CGFontID    _addFallbackFontId( void *vg, CGFontID base, CGFontID fb)                            { return mvgAddFallbackFontId( VG, base, fb); }
static CGFontID    _addFallbackFont( void *vg, char *base, char *fb)                                    { return mvgAddFallbackFont( VG, base, fb); }
static void        _resetFallbackFontsId( void *vg, NSInteger base)                                     { mvgResetFallbackFontsId( VG, base); }
static void        _resetFallbackFonts( void *vg, char *base)                                           { mvgResetFallbackFonts( VG, base); }

static CGFloat     _fontSize( void *vg, CGFloat s)                                                      { return mvgFontSize( VG, s); }
static void        _fontBlur( void *vg, CGFloat b)                                                      { mvgFontBlur( VG, b); }
static void        _textLetterSpacing( void *vg, CGFloat s)                                             { mvgTextLetterSpacing( VG, s); }
static void        _textLineHeight( void *vg, CGFloat h)                                                { mvgTextLineHeight( VG, h); }
static void        _textAlign( void *vg, CGCombinedTextAlign a)                                         { mvgTextAlign( VG, a); }
static void        _fontFaceId( void *vg, CGFontID id)                                                  { mvgFontFaceId( VG, id); }
static void        _fontFace( void *vg, char *name)                                                     { mvgFontFace( VG, name); }
static void        _textColor( void *vg, CGColor c)                                                     { mvgTextColor( VG, c); }
static void        _textBackgroundColor( void *vg, CGColor c)                                           { mvgTextBackgroundColor( VG, c); }
static void        _clearType( void *vg, BOOL e)                                                        { mvgClearType( VG, e); }

static CGFloat     _text( void *vg, CGPoint p, char *s, size_t len)                                     { return mvgText( VG, p, s, len); }
static void        _textBox( void *vg, CGPoint p, CGFloat w, char *s, size_t len)                       { mvgTextBox( VG, p, w, s, len); }
static CGTextBoundsInfo _textBounds( void *vg, CGPoint p, char *s, size_t len)                          { return mvgTextBounds( VG, p, s, len); }
static CGRect      _textVisualBounds( void *vg, CGPoint p, char *s, size_t len)                         { return mvgTextVisualBounds( VG, p, s, len); }
static void        _textBoxBounds( void *vg, CGPoint p, char *s, size_t len, CGFloat w, CGRect *bbox)   { mvgTextBoxBounds( VG, p, s, len, w, bbox); }
static NSUInteger  _textGlyphPositions( void *vg, CGPoint p, char *s, size_t len, struct UIGlyphPosition *pos, NSInteger max) { return mvgTextGlyphPositions( VG, p, s, len, pos, max); }
static NSUInteger  _textBreakLines( void *vg, char *s, size_t len, CGFloat w, struct UITextRow *rows, NSUInteger max, size_t sz) { return mvgTextBreakLines( VG, s, len, w, rows, max, sz); }
static CGTextMetrics _textMetrics( void *vg)                                                             { CGTextMetrics m; nvgTextMetrics( VG, &m.ascender, &m.descender, &m.lineHeight); m.ascender = fabsf(m.ascender); m.descender = fabsf(m.descender); return m; }
static void          *_getFontHandle( void *vg, int font)                                                { return nvgGetFontHandle( VG, font); }
static void          _trace( void *vg, FILE *fp)                                                         { nvgTrace( VG, fp); }

#undef VG

CGFunctionTable   CGNanoVGFunctionTable =
{
   .beginFrame                    = _beginFrame,
   .cancelFrame                   = _cancelFrame,
   .endFrame                      = _endFrame,

   .save                          = _save,
   .restore                       = _restore,
   .reset                         = _reset,

   .globalCompositeOperation      = _globalCompositeOperation,
   .globalCompositeBlendFunc      = _globalCompositeBlendFunc,
   .globalCompositeBlendFuncSeparate = _globalCompositeBlendFuncSeparate,

   .resetTransform                = _resetTransform,
   .transform                     = _transform,
   .currentTransform              = _currentTransform,
   .translate                     = _translate,
   .rotate                        = _rotate,
   .scale                         = _scale,
   .skewX                         = _skewX,
   .skewY                         = _skewY,

   .createImage                   = _createImage,
   .createImageMem                = _createImageMem,
   .createImageRGBA               = _createImageRGBA,
   .updateImage                   = _updateImage,
   .imageSize                     = _imageSize,
   .deleteImage                   = _deleteImage,

   .scissor                       = _scissor,
   .intersectScissor              = _intersectScissor,
   .resetScissor                  = _resetScissor,

   .shapeAntiAlias                = _shapeAntiAlias,
   .bezierTessellation            = _bezierTessellation,
   .strokeColor                   = _strokeColor,
   .fillColor                     = _fillColor,
   .miterLimit                    = _miterLimit,
   .strokeWidth                   = _strokeWidth,
   .lineCap                       = _lineCap,
   .lineJoin                      = _lineJoin,
   .globalAlpha                   = _globalAlpha,

   .beginPath                     = _beginPath,
   .moveTo                        = _moveTo,
   .lineTo                        = _lineTo,
   .bezierTo                      = _bezierTo,
   .quadTo                        = _quadTo,
   .arcTo                         = _arcTo,
   .closePath                     = _closePath,
   .pathWinding                   = _pathWinding,

   .rect                          = _rect,
   .roundedRect                   = _roundedRect,
   .roundedRectVarying            = _roundedRectVarying,
   .ellipse                       = _ellipse,
   .arc                           = _arc,
   .arcRadians                    = _arcRadians,
   .fill                          = _fill,
   .stroke                        = _stroke,
   .addCGPath                     = _addCGPath,

   .setFillLinearGradient         = _setFillLinearGradient,
   .setStrokeLinearGradient       = _setStrokeLinearGradient,
   .setFillBoxGradient            = _setFillBoxGradient,
   .setStrokeBoxGradient          = _setStrokeBoxGradient,
   .setFillRadialGradient         = _setFillRadialGradient,
   .setStrokeRadialGradient       = _setStrokeRadialGradient,
   .setFillImagePattern           = _setFillImagePattern,
   .setStrokeImagePattern         = _setStrokeImagePattern,

   .createFont                    = _createFont,
   .createFontMem                 = _createFontMem,
   .findFont                      = _findFont,
   .addFallbackFontId             = _addFallbackFontId,
   .addFallbackFont               = _addFallbackFont,
   .resetFallbackFontsId          = _resetFallbackFontsId,
   .resetFallbackFonts            = _resetFallbackFonts,

   .fontSize                      = _fontSize,
   .fontBlur                      = _fontBlur,
   .textLetterSpacing             = _textLetterSpacing,
   .textLineHeight                = _textLineHeight,
   .textAlign                     = _textAlign,
   .fontFaceId                    = _fontFaceId,
   .fontFace                      = _fontFace,
   .textColor                     = _textColor,
   .textBackgroundColor           = _textBackgroundColor,
   .clearType                     = _clearType,

   .text                          = _text,
   .textBox                       = _textBox,
   .textBounds                    = _textBounds,
   .textVisualBounds              = _textVisualBounds,
   .textBoxBounds                 = _textBoxBounds,
   .textGlyphPositions            = _textGlyphPositions,
   .textBreakLines                = _textBreakLines,
   .textMetrics                   = _textMetrics,
   .getFontHandle                 = _getFontHandle,
   .trace                         = _trace,
};
