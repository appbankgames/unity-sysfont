/*
 * Copyright (c) 2012 Mario Freitas (imkira@gmail.com)
 * 
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <CoreGraphics/CoreGraphics.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <CoreText/CoreText.h>

extern EAGLContext* _context;

#elif TARGET_OS_MAC
#import <ApplicationServices/ApplicationServices.h>
#include <OpenGL/gl.h>
#else
#error Unknown platform
#endif

#define UNITY_SYSFONT_UPDATE_QUEUE_CAPACITY 32

int nextPowerOfTwo(int n);

int nextPowerOfTwo(int n)
{
  --n;
  n |= n >> 1;
  n |= n >> 2;
  n |= n >> 4;
  n |= n >> 8;
  n |= n >> 16;
  ++n;
  return (n <= 0) ? 1 : n;
}

@interface UnitySysFontTextureUpdate : NSObject
{
  NSString *text;
  NSString *fontName;
  int fontSize;
  BOOL isBold;
  BOOL isItalic;
  int alignment;
  int maxWidthPixels;
  int maxHeightPixels;
  int textureID;
  
	int lineBreakMode;
	BOOL isStrokeEnabled;
	float strokeWidth;
	BOOL isShadowEnabled;
	CGPoint shadowOffset;
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	UIColor *fillColor;
	UIColor *strokeColor;
	UIColor *shadowColor;
#elif TARGET_OS_MAC
	NSColor *fillColor;
	NSColor *strokeColor;
	NSColor *shadowColor;
#endif
	float lineSpacing;
	float offset;

  BOOL ready;

  NSMutableAttributedString *attributedString;

  @public int textWidth;
  @public int textHeight;
  @public int textureWidth;
  @public int textureHeight;
}

- (NSNumber *)textureID;
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
- (UIFont *)font;
#elif TARGET_OS_MAC
- (NSFont *)font;
#endif
- (void)prepare;
- (void)render;
- (void)bindTextureWithFormat:(GLenum)format bitmapData:(void *)data;

@property (nonatomic, assign, getter=isReady) BOOL ready;
@end

@implementation UnitySysFontTextureUpdate

@synthesize ready;

- (id)initWithText:(const char *)_text fontName:(const char *)_fontName
fontSize:(int)_fontSize isBold:(BOOL)_isBold isItalic:(BOOL)_isItalic
alignment:(int)_alignment maxWidthPixels:(int)_maxWidthPixels
maxHeightPixels:(int)_maxHeightPixels textureID:(int)_textureID
{
  self = [super init];

  if (self != nil)
  {
    text = [[NSString stringWithUTF8String:((_text == NULL) ? "" : _text)]
      retain];
    fontName = [[NSString stringWithUTF8String:((_fontName == NULL) ? "" :
        _fontName)] retain];
    fontSize = _fontSize;
    isBold = _isBold;
    isItalic = _isItalic;
    alignment = _alignment;
    maxWidthPixels = _maxWidthPixels;
    maxHeightPixels = _maxHeightPixels;
    textureID = _textureID;
	  lineBreakMode = 0;
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	  fillColor = [UIColor whiteColor];
#elif TARGET_OS_MAC
	  fillColor = [NSColor whiteColor];
#endif
	  isStrokeEnabled = NO;
	  strokeWidth = 0.0f;
	  strokeColor = nil;
	  isShadowEnabled = NO;
	  shadowOffset = CGPointMake(0.0f, 0.0f);
	  shadowColor = nil;
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	  lineSpacing = fontSize / 4.0f;
#elif TARGET_OS_MAC
	  lineSpacing = 0.0f;
#endif
	  offset = 0.0f;
	  
    ready = NO;
    [self prepare];
  }

  return self;
}


- (id)initWithText:(const char *)_text fontName:(const char *)_fontName
		  fontSize:(int)_fontSize isBold:(BOOL)_isBold isItalic:(BOOL)_isItalic
		 alignment:(int)_alignment maxWidthPixels:(int)_maxWidthPixels maxHeightPixels:(int)_maxHeightPixels
	 lineBreakMode:(int)_lineBreakMode
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	   fillColor:(UIColor *)_fillColor
   isStrokeEnabled:(BOOL)_isStrokeEnabled strokeWidth:(float)_strokeWidth strokeColor:(UIColor *)_strokeColor
   isShadowEnabled:(BOOL)_isShadowEnabled shadowOffset:(CGPoint)_shadowOffset shadowColor:(UIColor *)_shadowColor
#elif TARGET_OS_MAC
	   fillColor:(NSColor *)_fillColor
   isStrokeEnabled:(BOOL)_isStrokeEnabled strokeWidth:(float)_strokeWidth strokeColor:(NSColor *)_strokeColor
   isShadowEnabled:(BOOL)_isShadowEnabled shadowOffset:(CGPoint)_shadowOffset shadowColor:(NSColor *)_shadowColor
#endif
			offset:(float)_offset
		 textureID:(int)_textureID
{
  self = [super init];
  
  if (self != nil)
  {
    text = [[NSString stringWithUTF8String:((_text == NULL) ? "" : _text)]
        retain];
    fontName = [[NSString stringWithUTF8String:((_fontName == NULL) ? "" :
                          _fontName)] retain];
    fontSize = _fontSize;
    isBold = _isBold;
    isItalic = _isItalic;
    alignment = _alignment;
    maxWidthPixels = _maxWidthPixels;
    maxHeightPixels = _maxHeightPixels;
    textureID = _textureID;
	  lineBreakMode = _lineBreakMode;
	  fillColor = _fillColor;
	  isStrokeEnabled = _isStrokeEnabled;
	  strokeWidth = _strokeWidth;
	  strokeColor = _strokeColor;
	  isShadowEnabled = _isShadowEnabled;
	  shadowOffset = (isShadowEnabled? _shadowOffset: CGPointMake(0.0f, 0.0f));
	  shadowColor = _shadowColor;
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	  lineSpacing = fontSize / 4.0f;
#elif TARGET_OS_MAC
	  lineSpacing = 0.0f;
#endif
	  offset = _offset;
	  
    ready = NO;
    [self prepare];
  }
  
  return self;
}

- (void)dealloc
{
  [attributedString release];
  [text release];
  [fontName release];
  [super dealloc];
}

- (NSNumber *)textureID
{
  return [NSNumber numberWithInt:textureID];
}

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
- (UIFont *)font
{
  UIFont *font = nil;

  if (fontSize <= 0)
  {
    fontSize = (int)[UIFont systemFontSize];
  }

  if ([fontName length] > (NSUInteger)0)
  {
    font = [UIFont fontWithName:fontName size:fontSize];
  }
  
  if (font == nil)
  {
    if (isBold == YES)
    {
      font = [UIFont boldSystemFontOfSize:fontSize];
    }
    else if (isItalic == YES)
    {
      font = [UIFont italicSystemFontOfSize:fontSize];
    }
    else
    {
      font = [UIFont systemFontOfSize:fontSize];
    }
  }
  return font;
}
#elif TARGET_OS_MAC
- (NSFont *)font
{
  NSFont *font = nil;

  if (fontSize <= 0)
  {
    fontSize = (int)[NSFont systemFontSize];
  }

  if ([fontName length] > (NSUInteger)0)
  {
    font = [NSFont fontWithName:fontName size:fontSize];
  }

  if (font == nil)
  {
    if (isBold == YES)
    {
      font = [NSFont boldSystemFontOfSize:fontSize];
    }
    else
    {
      font = [NSFont systemFontOfSize:fontSize];
    }
  }

  return font;
}
#endif

- (void)prepare
{
  CGSize maxSize = CGSizeMake(maxWidthPixels, maxHeightPixels);
  CGSize boundsSize;

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	CTFontRef ctFont = CTFontCreateWithName((CFStringRef)fontName, fontSize, NULL);
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									   (id)ctFont, (id)kCTFontAttributeName, nil];

	attributedString = [[NSMutableAttributedString alloc]
						initWithString:text attributes:attributes];
	
	CTLineBreakMode ctLineBreakMode = (CTLineBreakMode)lineBreakMode;
	CTTextAlignment textAlignMent = kCTLeftTextAlignment;
	if(alignment == 1)
	{
		textAlignMent = kCTCenterTextAlignment;
	}
	else if(alignment == 2)
	{
		textAlignMent = kCTRightTextAlignment;
	}
	
	CTParagraphStyleSetting paragraphStyleSettings[] = {
		{ kCTParagraphStyleSpecifierLineBreakMode, sizeof(CTLineBreakMode), (const void *)&ctLineBreakMode },
		{ kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), (const void *)&textAlignMent },
		{ kCTParagraphStyleSpecifierMinimumLineSpacing, sizeof(CGFloat), &lineSpacing },
		{ kCTParagraphStyleSpecifierMaximumLineSpacing, sizeof(CGFloat), &lineSpacing },
	};
	
	CFRange range = CFRangeMake(0, attributedString.length);
	CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(paragraphStyleSettings, sizeof(paragraphStyleSettings) / sizeof(paragraphStyleSettings[0]));
	CFAttributedStringSetAttribute((CFMutableAttributedStringRef)attributedString, range, kCTParagraphStyleAttributeName, paragraphStyle);
	CFRelease(paragraphStyle);
	CFRelease(ctFont);
	
  boundsSize = [text sizeWithFont:[self font] constrainedToSize:maxSize
    lineBreakMode:(UILineBreakMode)lineBreakMode];
#elif TARGET_OS_MAC

  NSTextAlignment _alignment = NSLeftTextAlignment;

  if (alignment == 1)
  {
    _alignment = NSCenterTextAlignment;
  }
  else if (alignment == 2)
  {
    _alignment = NSRightTextAlignment;
  }

  NSMutableParagraphStyle *parStyle = [[NSMutableParagraphStyle alloc] init];
  [parStyle setAlignment:_alignment];
  [parStyle setLineBreakMode:(NSLineBreakMode)lineBreakMode];
	[parStyle setMaximumLineHeight:lineSpacing];
	[parStyle setMinimumLineHeight:lineSpacing];

  NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
    [self font], NSFontAttributeName,
    [NSColor whiteColor], NSForegroundColorAttributeName,
    [NSColor clearColor], NSBackgroundColorAttributeName,
    parStyle, NSParagraphStyleAttributeName, nil];

  attributedString = [[NSMutableAttributedString alloc] 
    initWithString:text attributes:attributes];

  boundsSize = NSSizeToCGSize([attributedString
      boundingRectWithSize:NSSizeFromCGSize(maxSize)
      options:NSStringDrawingUsesLineFragmentOrigin].size);
#endif

	if(isStrokeEnabled)
	{
		boundsSize = CGSizeMake(boundsSize.width + strokeWidth * 2.0f, boundsSize.height + strokeWidth * 2.0f);
	}
	
	if(isShadowEnabled)
	{
		boundsSize = CGSizeMake(boundsSize.width + fabsf(shadowOffset.x), boundsSize.height + fabsf(shadowOffset.y));
	}

  textWidth = (int)ceilf(boundsSize.width);
  if (textWidth > maxWidthPixels)
  {
    textWidth = maxWidthPixels;
  }
  else if (textWidth <= 0)
  {
    textWidth = 1;
  }
  textHeight = (int)ceilf(boundsSize.height);
  if (textHeight > maxHeightPixels)
  {
    textHeight = maxHeightPixels;
  }
  else if (textHeight <= 0)
  {
    textHeight = 1;
  }

  textureWidth = nextPowerOfTwo(textWidth);
  textureHeight = nextPowerOfTwo(textHeight);
}

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
- (void)render
{
  void *bitmapData = calloc(textureHeight, textureWidth * 4);
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate(bitmapData, textureWidth,
											   textureHeight, 8, textureWidth * 4, colorSpace, kCGImageAlphaPremultipliedLast);
	CGColorSpaceRelease(colorSpace);

  if (context == NULL)
  {
    free(bitmapData);
    return;
  }

  UIGraphicsPushContext(context);

  CGContextSetAlpha(context, 1.f);

  CGRect drawRect = CGRectMake(0.f, (float)(textureHeight - textHeight) + offset,
      textWidth, textHeight - offset);
	
	if(isStrokeEnabled)
	{
		drawRect = CGRectOffset(drawRect, (alignment == 0)? strokeWidth: (alignment == 2)? -strokeWidth: 0, strokeWidth);
	}
	
  CGContextSaveGState(context);
  CGContextTranslateCTM(context, 0.0f, drawRect.size.height + drawRect.origin.y * 2);
  CGContextScaleCTM(context, 1.0f, -1.0f);
  
	CGContextSetLineJoin(context, kCGLineJoinRound);
	
	CFRange cfRange = CFRangeMake(0, attributedString.length);
	NSRange nsRange = NSMakeRange(cfRange.location, cfRange.length);
	CTFramesetterRef framesetter;
	CGPathRef path;
	CTFrameRef textFrame;
	
	if(isShadowEnabled)
	{
		// Draw shadow
		if(isStrokeEnabled)
		{
			[attributedString addAttribute:(id)kCTStrokeWidthAttributeName value:[NSNumber numberWithFloat:strokeWidth * 2.0f / (CGFloat)fontSize * 100.0f] range:nsRange];
			[attributedString addAttribute:(id)kCTStrokeColorAttributeName value:(id)shadowColor.CGColor range:nsRange];
		}
		[attributedString addAttribute:(id)kCTForegroundColorAttributeName value:(id)shadowColor.CGColor range:nsRange];
		
		framesetter = CTFramesetterCreateWithAttributedString((CFMutableAttributedStringRef)attributedString);
		path = [[UIBezierPath bezierPathWithRect:CGRectOffset(drawRect, shadowOffset.x, shadowOffset.y)] CGPath];
		textFrame = CTFramesetterCreateFrame(framesetter, cfRange, path, NULL);
		CTFrameDraw(textFrame, context);
		CFRelease(textFrame);
		CFRelease(framesetter);
	}
	
	if(isStrokeEnabled)
	{
		// Draw stroke
		[attributedString addAttribute:(id)kCTStrokeWidthAttributeName value:[NSNumber numberWithFloat:strokeWidth * 2.0f / (CGFloat)fontSize * 100.0f] range:nsRange];
		[attributedString addAttribute:(id)kCTStrokeColorAttributeName value:(id)strokeColor.CGColor range:nsRange];
		
		framesetter = CTFramesetterCreateWithAttributedString((CFMutableAttributedStringRef)attributedString);
		path = [[UIBezierPath bezierPathWithRect:drawRect] CGPath];
		textFrame = CTFramesetterCreateFrame(framesetter, cfRange, path, NULL);
		CTFrameDraw(textFrame, context);
		CFRelease(textFrame);
		CFRelease(framesetter);
	}
	
	// Draw text
	[attributedString removeAttribute:(id)kCTStrokeWidthAttributeName range:nsRange];
	[attributedString removeAttribute:(id)kCTStrokeColorAttributeName range:nsRange];
	[attributedString addAttribute:(id)kCTForegroundColorAttributeName value:(id)fillColor.CGColor range:nsRange];
	
	framesetter = CTFramesetterCreateWithAttributedString((CFMutableAttributedStringRef)attributedString);
	path = [[UIBezierPath bezierPathWithRect:drawRect] CGPath];
	textFrame = CTFramesetterCreateFrame(framesetter, cfRange, path, NULL);
	CTFrameDraw(textFrame, context);
	CFRelease(textFrame);
	CFRelease(framesetter);
	
  CGContextRestoreGState(context);

  UIGraphicsPopContext();

	[self bindTextureWithFormat:GL_RGBA bitmapData:bitmapData];

  CGContextRelease(context); 
  free(bitmapData);
}
#elif TARGET_OS_MAC
- (void)render
{
  NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc]
    initWithBitmapDataPlanes:NULL pixelsWide:textureWidth
							  pixelsHigh:textureHeight bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES
							  isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bitmapFormat:0
							  bytesPerRow:textureWidth * 4 bitsPerPixel:0];

  if (bitmap == nil)
  {
    return;
  }

  NSGraphicsContext *context = [NSGraphicsContext
    graphicsContextWithBitmapImageRep:bitmap];
  [NSGraphicsContext saveGraphicsState];
  [NSGraphicsContext setCurrentContext:context];

  NSAffineTransform *transform = [NSAffineTransform transform];
  [transform translateXBy:0.f yBy:textureHeight];
  [transform scaleXBy:1.f yBy:-1.f];
  [transform concat];

  NSRect textureRect = NSMakeRect(0.f, 0.f, textureWidth, textureHeight);
  NSRect drawRect = NSMakeRect(0.f, 0.f, textWidth, textHeight);

	if(isStrokeEnabled)
	{
		drawRect = NSOffsetRect(drawRect, (alignment == 0)? strokeWidth: (alignment == 2)? -strokeWidth: 0, -strokeWidth);
	}
	
  [[NSColor clearColor] setFill];
  NSRectFill(textureRect);

  [[NSColor whiteColor] set];
	
	NSRange nsRange = NSMakeRange(0, [attributedString length]);
	if(isShadowEnabled)
	{
		// Draw shadow
		if(isStrokeEnabled)
		{
			[attributedString addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat:strokeWidth * 2.0f / (CGFloat)fontSize * 100.0f] range:nsRange];
			[attributedString addAttribute:NSStrokeColorAttributeName value:shadowColor range:nsRange];
		}
		[attributedString addAttribute:NSForegroundColorAttributeName value:shadowColor range:nsRange];
		[attributedString drawWithRect:NSOffsetRect(drawRect, shadowOffset.x, shadowOffset.y)
							   options:NSStringDrawingUsesLineFragmentOrigin];
	}
	
	if(isStrokeEnabled)
	{
		// Draw stroke
		[attributedString addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat:strokeWidth * 2.0f / (CGFloat)fontSize * 100.0f] range:nsRange];
		[attributedString addAttribute:NSStrokeColorAttributeName value:strokeColor range:nsRange];
		[attributedString drawWithRect:drawRect
							   options:NSStringDrawingUsesLineFragmentOrigin];
	}
	
	// Draw text
	[attributedString removeAttribute:NSStrokeWidthAttributeName range:nsRange];
	[attributedString removeAttribute:NSStrokeColorAttributeName range:nsRange];
	[attributedString addAttribute:NSForegroundColorAttributeName value:fillColor range:nsRange];
  [attributedString drawWithRect:drawRect
    options:NSStringDrawingUsesLineFragmentOrigin];

  [NSGraphicsContext restoreGraphicsState];

	[self bindTextureWithFormat:GL_RGBA bitmapData:[bitmap bitmapData]];

  [bitmap release];
}
#endif

- (void)bindTextureWithFormat:(GLenum)format bitmapData:(void *)data
{
  glBindTexture(GL_TEXTURE_2D, textureID);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, textureWidth, textureHeight, 0,
				 format, GL_UNSIGNED_BYTE, data);
}
@end

@interface UnitySysFontTextureManager : NSObject
{
  NSMutableDictionary *updateQueue;
}

+ (UnitySysFontTextureManager *)sharedInstance;
- (id)initWithCapacity:(NSUInteger)numItems;
- (UnitySysFontTextureUpdate *)updateHavingTextureID:(int)textureID;
- (void)queueUpdate:(UnitySysFontTextureUpdate *)update;
- (void)dequeueUpdate:(NSNumber *)textureID;
@end

@implementation UnitySysFontTextureManager 
static UnitySysFontTextureManager *sharedInstance;

+ (void)initialize
{
  static BOOL initialized = NO;

  if (!initialized)
  {
    initialized = YES;
    sharedInstance = [[UnitySysFontTextureManager alloc]
      initWithCapacity:UNITY_SYSFONT_UPDATE_QUEUE_CAPACITY];
  }
}

+ (UnitySysFontTextureManager *)sharedInstance
{
  return sharedInstance;
}

- (id)initWithCapacity:(NSUInteger)numItems
{
  self = [super init];

  if (self != nil)
  {
    updateQueue = [[NSMutableDictionary alloc] initWithCapacity:numItems];
  }

  return self;
}

- (void)dealloc
{
  [updateQueue release];
  [super dealloc];
}

- (UnitySysFontTextureUpdate *)updateHavingTextureID:(int)textureID
{
  return [updateQueue objectForKey:[NSNumber numberWithInt:textureID]];
}

- (void)queueUpdate:(UnitySysFontTextureUpdate *)update
{
  NSNumber *textureID = [update textureID];
  [self dequeueUpdate:textureID];
  [updateQueue setObject:update forKey:textureID];
}

- (void)dequeueUpdate:(NSNumber *)textureID
{
  UnitySysFontTextureUpdate *existingUpdate;
  existingUpdate = [updateQueue objectForKey:textureID];
  if (existingUpdate != nil)
  {
    [updateQueue removeObjectForKey:textureID];
    [existingUpdate release];
  }
}

- (void)processQueue
{
  if ([updateQueue count] > (NSUInteger)0)
  {
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    EAGLContext *oldContext = [EAGLContext currentContext];
    // change to Unity's default OpenGL context
    if (oldContext != _context)
    {
      [EAGLContext setCurrentContext:_context];
    }
#endif
    for (NSNumber *textureID in [updateQueue allKeys])
    {
      UnitySysFontTextureUpdate *update = [updateQueue objectForKey:textureID];
      if ([update isReady])
      {
        [update render];
        [updateQueue removeObjectForKey:textureID];
        [update release];
      }
    }
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    // revert to non-default OpenGL context?
    if (oldContext != _context)
    {
      [EAGLContext setCurrentContext:oldContext];
    }
#endif
  }
}
@end

extern "C"
{
  void _SysFontQueueTexture(const char *text, const char *fontName,
      int fontSize, BOOL isBold, BOOL isItalic, int alignment,
      int maxWidthPixels, int maxHeightPixels, int textureID);

  void _SysFontQueueTextureWithOptions(const char *text, const char *fontName,
									   int fontSize, BOOL isBold, BOOL isItalic, int alignment,
									   int maxWidthPixels, int maxHeightPixels, int lineBreakMode,
									   float fillColorR, float fillColorG, float fillColorB, float fillColorA,
									   BOOL isStrokeEnabled, float strokeWidth, float strokeColorR, float strokeColorG, float strokeColorB, float strokeColorA,
									   BOOL isShadowEnabled, float shadowOffsetX, float shadowOffsetY, float shadowColorR, float shadowColorG, float shadowColorB, float shadowColorA,
									   float offset, int textureID);
  
  int _SysFontGetTextureWidth(int textureID);

  int _SysFontGetTextureHeight(int textureID);

  int _SysFontGetTextWidth(int textureID);

  int _SysFontGetTextHeight(int textureID);

  void _SysFontUpdateQueuedTexture(int textureID);

  void _SysFontRender();

  void _SysFontDequeueTexture(int textureID);

  void UnityRenderEvent(int eventID);
}

void _SysFontQueueTexture(const char *text, const char *fontName,
    int fontSize, BOOL isBold, BOOL isItalic, int alignment,
    int maxWidthPixels, int maxHeightPixels, int textureID)
{
  UnitySysFontTextureManager *instance;
  UnitySysFontTextureUpdate *update;

  update = [[UnitySysFontTextureUpdate alloc] initWithText:text
    fontName:fontName fontSize:fontSize isBold:isBold isItalic:isItalic
    alignment:alignment maxWidthPixels:maxWidthPixels
    maxHeightPixels:maxHeightPixels textureID:textureID];

  instance = [UnitySysFontTextureManager sharedInstance];
  @synchronized(instance)
  {
    [instance queueUpdate:update];
  }
}


void _SysFontQueueTextureWithOptions(const char *text, const char *fontName,
									 int fontSize, BOOL isBold, BOOL isItalic, int alignment,
									 int maxWidthPixels, int maxHeightPixels, int lineBreakMode,
									 float fillColorR, float fillColorG, float fillColorB, float fillColorA,
									 BOOL isStrokeEnabled, float strokeWidth, float strokeColorR, float strokeColorG, float strokeColorB, float strokeColorA,
									 BOOL isShadowEnabled, float shadowOffsetX, float shadowOffsetY, float shadowColorR, float shadowColorG, float shadowColorB, float shadowColorA,
									 float offset, int textureID)
{
  UnitySysFontTextureManager *instance;
  UnitySysFontTextureUpdate *update;
  
  update = [[UnitySysFontTextureUpdate alloc] initWithText:text
												  fontName:fontName fontSize:fontSize isBold:isBold isItalic:isItalic
												 alignment:alignment maxWidthPixels:maxWidthPixels
										   maxHeightPixels:maxHeightPixels lineBreakMode:lineBreakMode
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
												 fillColor:[UIColor colorWithRed:fillColorR green:fillColorG blue:fillColorB alpha:fillColorA]
										   isStrokeEnabled:isStrokeEnabled strokeWidth:strokeWidth strokeColor:[UIColor colorWithRed:strokeColorR green:strokeColorG blue:strokeColorB alpha:strokeColorA]
										   isShadowEnabled:isShadowEnabled shadowOffset:CGPointMake(shadowOffsetX, shadowOffsetY) shadowColor:[UIColor colorWithRed:shadowColorR green:shadowColorG blue:shadowColorB alpha:shadowColorA]
#elif TARGET_OS_MAC
												 fillColor:[NSColor colorWithCalibratedRed:fillColorR green:fillColorG blue:fillColorB alpha:fillColorA]
										   isStrokeEnabled:isStrokeEnabled strokeWidth:strokeWidth strokeColor:[NSColor colorWithCalibratedRed:strokeColorR green:strokeColorG blue:strokeColorB alpha:strokeColorA]
										   isShadowEnabled:isShadowEnabled shadowOffset:CGPointMake(shadowOffsetX, shadowOffsetY) shadowColor:[NSColor colorWithCalibratedRed:shadowColorR green:shadowColorG blue:shadowColorB alpha:shadowColorA]
#endif
													offset:offset textureID:textureID];
  
  instance = [UnitySysFontTextureManager sharedInstance];
  @synchronized(instance)
  {
    [instance queueUpdate:update];
  }
}


int _SysFontGetTextureWidth(int textureID)
{
  UnitySysFontTextureManager *instance;
  UnitySysFontTextureUpdate *update;
  instance = [UnitySysFontTextureManager sharedInstance];
  @synchronized(instance)
  {
    update = [instance updateHavingTextureID:textureID];
    if (update == nil)
    {
      return -1;
    }
    return update->textureWidth;
  }
}

int _SysFontGetTextureHeight(int textureID)
{
  UnitySysFontTextureManager *instance;
  UnitySysFontTextureUpdate *update;
  instance = [UnitySysFontTextureManager sharedInstance];
  @synchronized(instance)
  {
    update = [instance updateHavingTextureID:textureID];
    if (update == nil)
    {
      return -1;
    }
    return update->textureHeight;
  }
}

int _SysFontGetTextWidth(int textureID)
{
  UnitySysFontTextureManager *instance;
  UnitySysFontTextureUpdate *update;
  instance = [UnitySysFontTextureManager sharedInstance];
  @synchronized(instance)
  {
    update = [instance updateHavingTextureID:textureID];
    if (update == nil)
    {
      return -1;
    }
    return update->textWidth;
  }
}

int _SysFontGetTextHeight(int textureID)
{
  UnitySysFontTextureManager *instance;
  UnitySysFontTextureUpdate *update;
  instance = [UnitySysFontTextureManager sharedInstance];
  @synchronized(instance)
  {
    update = [instance updateHavingTextureID:textureID];
    if (update == nil)
    {
      return -1;
    }
    return update->textHeight;
  }
}

void _SysFontUpdateQueuedTexture(int textureID)
{
  UnitySysFontTextureManager *instance;
  UnitySysFontTextureUpdate *update;
  instance = [UnitySysFontTextureManager sharedInstance];
  @synchronized(instance)
  {
    update = [instance updateHavingTextureID:textureID];
    if (update != nil)
    {
      [update setReady:YES];
    }
  }
}

void _SysFontRender()
{
  UnitySysFontTextureManager *instance;
  instance = [UnitySysFontTextureManager sharedInstance];
  @synchronized(instance)
  {
    [instance processQueue];
  }
}

void _SysFontDequeueTexture(int textureID)
{
  UnitySysFontTextureManager *instance;
  instance = [UnitySysFontTextureManager sharedInstance];
  @synchronized(instance)
  {
    [instance dequeueUpdate:[NSNumber numberWithInt:textureID]];
  }
}

void UnityRenderEvent(int eventID)
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  _SysFontRender();
  [pool drain];
}
