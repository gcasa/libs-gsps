// File: MiniPostScriptVM.m
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface PSGraphicsState : NSObject

@property (nonatomic) NSPoint currentPoint;
@property (nonatomic, strong) NSBezierPath *path;
@property (nonatomic) CGFloat lineWidth;
@property (nonatomic, strong) NSColor *strokeColor;
@property (nonatomic, strong) NSColor *fillColor;
@property (nonatomic, strong) NSFont *font;
@property (nonatomic, strong) NSAffineTransform *transform;
@property (nonatomic, strong) NSBezierPath *clipPath;

@end

@implementation PSGraphicsState
- (instancetype)init
{
    if (self = [super init])
      {
	_currentPoint = NSZeroPoint;
	_path = [NSBezierPath bezierPath];
	_lineWidth = 1.0;
	_strokeColor = [NSColor blackColor];
	_fillColor = [NSColor blackColor];
	_font = [NSFont systemFontOfSize:12];
	_transform = [NSAffineTransform transform];
	_clipPath = nil;
      }

    return self;
}
@end

@interface PSInterpreter : NSObject

@property (nonatomic, strong) NSMutableArray *operandStack;
@property (nonatomic, strong) NSMutableArray *dictionaryStack;
@property (nonatomic, strong) NSMutableArray *graphicsStack;
@property (nonatomic, strong) PSGraphicsState *graphicsState;
@property (nonatomic, assign) BOOL exitFlag;
@property (nonatomic, strong) NSMutableArray *clipStack;
@property (nonatomic, strong) NSView *renderView;

- (void)executeToken:(NSString *)token;

@end

@implementation PSInterpreter

- (instancetype)init
{
  if (self = [super init])
    {
      _operandStack = [NSMutableArray array];
      _dictionaryStack = [NSMutableArray arrayWithObject:[NSMutableDictionary dictionary]];
      _graphicsStack = [NSMutableArray array];
      _graphicsState = [[PSGraphicsState alloc] init];
      _exitFlag = NO;
    }
  return self;
}

- (void)executeToken:(NSString *)token
{
  if (self.exitFlag) return;

  // handle tokens...
  if ([token isEqualToString:@"type"]) {
    id obj = self.operandStack.lastObject;
    if ([obj isKindOfClass:[NSNumber class]]) {
      [self.operandStack addObject:@"number"];
    } else if ([obj isKindOfClass:[NSString class]]) {
      NSString *str = (NSString *)obj;
      if ([str hasPrefix:@"/"]) {
	[self.operandStack addObject:@"name"];
      } else {
	[self.operandStack addObject:@"string"];
      }
    } else if ([obj isKindOfClass:[NSArray class]]) {
      [self.operandStack addObject:@"array"];
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
      [self.operandStack addObject:@"dict"];
    } else {
      [self.operandStack addObject:@"unknown"];
    }
  } else if ([token isEqualToString:@"checkstack"]) {
    if (self.operandStack.count < 1) {
      NSLog(@"Stack underflow error on: %@", token);
    }
  } else if ([token isEqualToString:@"true"]) {
    [self.operandStack addObject:@YES];
  } else if ([token isEqualToString:@"false"]) {
    [self.operandStack addObject:@NO];
  } else if ([token hasPrefix:@"("] && [token hasSuffix:@")"]) {
    NSString *string = [token substringWithRange:NSMakeRange(1, token.length - 2)];
    [self.operandStack addObject:string];
  } else if ([token hasPrefix:@"/"]) {
    [self.operandStack addObject:token];
  } else  if ([token isEqualToString:@"stack"] || [token isEqualToString:@"pstack"]) {
    NSLog(@"--- Stack ---");
    for (id obj in self.operandStack.reverseObjectEnumerator) {
      NSLog(@"%@", obj);
    }
  } else if ([token isEqualToString:@"sub"]) {
    NSNumber *b = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *a = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.operandStack addObject:@(a.doubleValue - b.doubleValue)];
  } else if ([token isEqualToString:@"mul"]) {
    NSNumber *b = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *a = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.operandStack addObject:@(a.doubleValue * b.doubleValue)];
  } else if ([token isEqualToString:@"div"]) {
    NSNumber *b = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *a = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.operandStack addObject:@(a.doubleValue / b.doubleValue)];
  } else if ([token isEqualToString:@"mod"]) {
    NSNumber *b = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *a = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.operandStack addObject:@(fmod(a.doubleValue, b.doubleValue))];
  } else if ([token isEqualToString:@"neg"]) {
    NSNumber *a = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.operandStack addObject:@(-a.doubleValue)];
  } else if ([token isEqualToString:@"abs"]) {
    NSNumber *a = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.operandStack addObject:@(fabs(a.doubleValue))];
  } else if ([token isEqualToString:@"eq"]) {
    NSNumber *b = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *a = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.operandStack addObject:@([a isEqualToNumber:b])];
  } else if ([token isEqualToString:@"ne"]) {
    NSNumber *b = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *a = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.operandStack addObject:@(![a isEqualToNumber:b])];
  } else if ([token isEqualToString:@"gt"]) {
    NSNumber *b = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *a = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.operandStack addObject:@(a.doubleValue > b.doubleValue)];
  } else if ([token isEqualToString:@"lt"]) {
    NSNumber *b = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *a = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.operandStack addObject:@(a.doubleValue < b.doubleValue)];
  } else if ([token isEqualToString:@"ge"]) {
    NSNumber *b = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *a = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.operandStack addObject:@(a.doubleValue >= b.doubleValue)];
  } else if ([token isEqualToString:@"le"]) {
    NSNumber *b = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *a = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.operandStack addObject:@(a.doubleValue <= b.doubleValue)];
  } else if ([token isEqualToString:@"array"]) {
    NSNumber *count = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:count.intValue];
    for (NSInteger i = 0; i < count.intValue; i++) {
      [arr addObject:[NSNull null]];
    }
    [self.operandStack addObject:arr];
  } else if ([token isEqualToString:@"aload"]) {
    NSMutableArray *arr = self.operandStack.lastObject; [self.operandStack removeLastObject];
    for (id obj in arr) {
      [self.operandStack addObject:obj];
    }
    [self.operandStack addObject:arr];
  } else if ([token isEqualToString:@"astore"]) {
    NSMutableArray *arr = self.operandStack.lastObject; [self.operandStack removeLastObject];
    for (NSInteger i = arr.count - 1; i >= 0; i--) {
      arr[i] = self.operandStack.lastObject;
      [self.operandStack removeLastObject];
    }
    [self.operandStack addObject:arr];
  } else if ([token isEqualToString:@"get"]) {
    NSNumber *index = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSArray *arr = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.operandStack addObject:arr[index.intValue]];
  } else if ([token isEqualToString:@"put"]) {
    NSNumber *index = self.operandStack.lastObject; [self.operandStack removeLastObject];
    id value = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSMutableArray *arr = self.operandStack.lastObject; [self.operandStack removeLastObject];
    arr[index.intValue] = value;
    [self.operandStack addObject:arr];
  } else if ([token isEqualToString:@"length"]) {
    NSArray *arr = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.operandStack addObject:@(arr.count)];
  } else if ([token isEqualToString:@"count"]) {
    [self.operandStack addObject:@(self.operandStack.count)];
  } else if ([token isEqualToString:@"dict"]) {
    [self.operandStack removeLastObject]; // size operand (ignored)
    [self.operandStack addObject:[NSMutableDictionary dictionary]];
  } else if ([token isEqualToString:@"begin"]) {
    id top = self.operandStack.lastObject;
    [self.operandStack removeLastObject];
    if ([top isKindOfClass:[NSMutableDictionary class]]) {
      [self.dictionaryStack addObject:top];
    }
  } else if ([token isEqualToString:@"end"]) {
    if (self.dictionaryStack.count > 1) {
      [self.dictionaryStack removeLastObject];
    }
  } else if ([token isEqualToString:@"def"]) {
    id value = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSString *key = self.operandStack.lastObject; [self.operandStack removeLastObject];
    if ([key hasPrefix:@"/"]) {
      key = [key substringFromIndex:1];
      NSMutableDictionary *topDict = self.dictionaryStack.lastObject;
      topDict[key] = value;
    }
  } else if ([token isEqualToString:@"load"]) {
    NSString *key = self.operandStack.lastObject; [self.operandStack removeLastObject];
    if ([key hasPrefix:@"/"]) {
      key = [key substringFromIndex:1];
    }
    for (NSDictionary *dict in [self.dictionaryStack reverseObjectEnumerator]) {
      if (dict[key]) {
	[self.operandStack addObject:dict[key]];
	break;
      }
    }
  } else if ([token isEqualToString:@"cliprestore"]) {
    if (self.clipStack.count > 0) {
      self.graphicsState.clipPath = [self.clipStack lastObject];
      [self.clipStack removeLastObject];
    }
  } else if ([token isEqualToString:@"clipsave"]) {
    if (self.graphicsState.clipPath) {
      [self.clipStack addObject:[self.graphicsState.clipPath copy]];
    } else {
      [self.clipStack addObject:[NSBezierPath bezierPath]];
    }
  } else if ([token isEqualToString:@"flattenpath"]) {
    [self.graphicsState.path setFlatness:1.0];
    // No actual decomposition needed in NSBezierPath: assumed flat render
  } else if ([token isEqualToString:@"reversepath"]) {
    NSBezierPath *reversed = [NSBezierPath bezierPath];
    for (NSInteger i = self.graphicsState.path.elementCount - 1; i >= 0; i--) {
      NSBezierPathElement element = [self.graphicsState.path elementAtIndex:i associatedPoints:NULL];
      // For brevity, we're just reversing move/line points; curves skipped
      if (element == NSMoveToBezierPathElement || element == NSLineToBezierPathElement) {
	NSPoint pt;
	[self.graphicsState.path elementAtIndex:i associatedPoints:&pt];
	if (element == NSMoveToBezierPathElement) {
	  [reversed moveToPoint:pt];
	} else {
	  [reversed lineToPoint:pt];
	}
      }
    }
    self.graphicsState.path = reversed;
  } else if ([token isEqualToString:@"pathforall"]) {
    for (NSInteger i = 0; i < self.graphicsState.path.elementCount; i++) {
      NSPoint pts[3];
      NSBezierPathElement type = [self.graphicsState.path elementAtIndex:i associatedPoints:pts];
      switch (type) {
      case NSMoveToBezierPathElement:
	NSLog(@"moveto %f %f", pts[0].x, pts[0].y);
	break;
      case NSLineToBezierPathElement:
	NSLog(@"lineto %f %f", pts[0].x, pts[0].y);
	break;
      case NSCurveToBezierPathElement:
	NSLog(@"curveto %f %f %f %f %f %f", pts[0].x, pts[0].y, pts[1].x, pts[1].y, pts[2].x, pts[2].y);
	break;
      case NSClosePathBezierPathElement:
	NSLog(@"closepath");
	break;
      }
    }
  } else if ([token isEqualToString:@"pathbbox"]) {
    NSRect bounds = self.graphicsState.path.bounds;
    [self.operandStack addObject:@(NSMinX(bounds))];
    [self.operandStack addObject:@(NSMinY(bounds))];
    [self.operandStack addObject:@(NSMaxX(bounds))];
    [self.operandStack addObject:@(NSMaxY(bounds))];
  } else if ([token isEqualToString:@"eofill"]) {
    [self.graphicsState.fillColor setFill];
    [self.graphicsState.path setWindingRule:NSEvenOddWindingRule];
    [self.graphicsState.path fill];
  } else if ([token isEqualToString:@"eoclip"]) {
    if (!self.graphicsState.clipPath) {
      self.graphicsState.clipPath = [self.graphicsState.path copy];
    } else {
      [self.graphicsState.clipPath appendBezierPath:self.graphicsState.path];
    }
    [self.graphicsState.clipPath setWindingRule:NSEvenOddWindingRule];
    [self.graphicsState.clipPath addClip];
  } else if ([token isEqualToString:@"showpage"]) {
    if (self.renderView) {
      [self.renderView setNeedsDisplay:YES];
    }
  } else if ([token isEqualToString:@"arc"]) {
    NSNumber *angle2 = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *angle1 = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *radius = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *y = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *x = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.graphicsState.path appendBezierPathWithArcWithCenter:NSMakePoint(x.doubleValue, y.doubleValue)
							radius:radius.doubleValue
						    startAngle:angle1.doubleValue
						      endAngle:angle2.doubleValue
						     clockwise:NO];
  } else if ([token isEqualToString:@"curveto"]) {
    NSNumber *y3 = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *x3 = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *y2 = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *x2 = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *y1 = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *x1 = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.graphicsState.path curveToPoint:NSMakePoint(x3.doubleValue, y3.doubleValue)
			    controlPoint1:NSMakePoint(x1.doubleValue, y1.doubleValue)
			    controlPoint2:NSMakePoint(x2.doubleValue, y2.doubleValue)];
  } else if ([token isEqualToString:@"rectfill"]) {
    NSNumber *height = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *width = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *y = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *x = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSRect rect = NSMakeRect(x.doubleValue, y.doubleValue, width.doubleValue, height.doubleValue);
    [self.graphicsState.fillColor setFill];
    [NSBezierPath fillRect:rect];
  } else if ([token isEqualToString:@"rectstroke"]) {
    NSNumber *height = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *width = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *y = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *x = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSRect rect = NSMakeRect(x.doubleValue, y.doubleValue, width.doubleValue, height.doubleValue);
    [self.graphicsState.strokeColor setStroke];
    NSBezierPath *rpath = [NSBezierPath bezierPathWithRect:rect];
    [rpath setLineWidth:self.graphicsState.lineWidth];
    [rpath stroke];
  } else if ([token isEqualToString:@"imagegray"]) {
    NSData *data = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *height = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *width = self.operandStack.lastObject; [self.operandStack removeLastObject];

    NSUInteger pixelCount = width.intValue * height.intValue;
    NSMutableData *rgbaData = [NSMutableData dataWithLength:pixelCount * 4];
    const uint8_t *gray = data.bytes;
    uint8_t *rgba = (uint8_t *)rgbaData.mutableBytes;

    for (NSUInteger i = 0; i < pixelCount; i++) {
      uint8_t v = gray[i];
      rgba[i * 4 + 0] = v;
      rgba[i * 4 + 1] = v;
      rgba[i * 4 + 2] = v;
      rgba[i * 4 + 3] = 255;
    }

    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc]
				 initWithBitmapDataPlanes:NULL
					       pixelsWide:width.intValue
					       pixelsHigh:height.intValue
					    bitsPerSample:8
					  samplesPerPixel:4
						 hasAlpha:YES
						 isPlanar:NO
					   colorSpaceName:NSCalibratedRGBColorSpace
					      bytesPerRow:width.intValue * 4
					     bitsPerPixel:32];

    memcpy(bitmap.bitmapData, rgbaData.bytes, rgbaData.length);

    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(width.floatValue, height.floatValue)];
    [image addRepresentation:bitmap];

    NSPoint drawPoint = self.graphicsState.currentPoint;
    [image drawAtPoint:drawPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];

  } else if ([token isEqualToString:@"imagemask"]) {
    NSData *mask = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *height = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *width = self.operandStack.lastObject; [self.operandStack removeLastObject];

    NSUInteger pixelCount = width.intValue * height.intValue;
    NSMutableData *rgbaData = [NSMutableData dataWithLength:pixelCount * 4];
    const uint8_t *maskData = mask.bytes;
    uint8_t *rgba = (uint8_t *)rgbaData.mutableBytes;

    for (NSUInteger i = 0; i < pixelCount; i++) {
      uint8_t v = maskData[i];
      rgba[i * 4 + 0] = 0;
      rgba[i * 4 + 1] = 0;
      rgba[i * 4 + 2] = 0;
      rgba[i * 4 + 3] = v;
    }

    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc]
				 initWithBitmapDataPlanes:NULL
					       pixelsWide:width.intValue
					       pixelsHigh:height.intValue
					    bitsPerSample:8
					  samplesPerPixel:4
						 hasAlpha:YES
						 isPlanar:NO
					   colorSpaceName:NSCalibratedRGBColorSpace
					      bytesPerRow:width.intValue * 4
					     bitsPerPixel:32];

    memcpy(bitmap.bitmapData, rgbaData.bytes, rgbaData.length);

    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(width.floatValue, height.floatValue)];
    [image addRepresentation:bitmap];

    NSPoint drawPoint = self.graphicsState.currentPoint;
    [image drawAtPoint:drawPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
  } else if ([token isEqualToString:@"image"]) {
    NSData *data = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *height = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *width = self.operandStack.lastObject; [self.operandStack removeLastObject];

    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc]
				 initWithBitmapDataPlanes:NULL
					       pixelsWide:width.intValue
					       pixelsHigh:height.intValue
					    bitsPerSample:8
					  samplesPerPixel:4
						 hasAlpha:YES
						 isPlanar:NO
					   colorSpaceName:NSCalibratedRGBColorSpace
					      bytesPerRow:width.intValue * 4
					     bitsPerPixel:32];

    memcpy(bitmap.bitmapData, [data bytes], MIN([data length], bitmap.bytesPerRow * height.intValue));

    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(width.floatValue, height.floatValue)];
    [image addRepresentation:bitmap];

    NSPoint drawPoint = self.graphicsState.currentPoint;
    [image drawAtPoint:drawPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
   } else if ([token isEqualToString:@"gsave"]) {
    PSGraphicsState *copy = [[PSGraphicsState alloc] init];
    copy.currentPoint = self.graphicsState.currentPoint;
    copy.path = [self.graphicsState.path copy];
    copy.lineWidth = self.graphicsState.lineWidth;
    copy.strokeColor = self.graphicsState.strokeColor;
    copy.fillColor = self.graphicsState.fillColor;
    copy.font = self.graphicsState.font;
    copy.transform = [self.graphicsState.transform copy];
    copy.clipPath = [self.graphicsState.clipPath copy];
    [self.graphicsStack addObject:copy];
  } else if ([token isEqualToString:@"grestore"]) {
    if (self.graphicsStack.count > 0) {
      self.graphicsState = [self.graphicsStack lastObject];
      [self.graphicsStack removeLastObject];
    }
  } else if ([token isEqualToString:@"currentmatrix"]) {
    [self.operandStack addObject:[self.graphicsState.transform copy]];
  } else if ([token isEqualToString:@"setmatrix"]) {
    NSAffineTransform *matrix = self.operandStack.lastObject; [self.operandStack removeLastObject];
    self.graphicsState.transform = matrix;
  } else if ([token isEqualToString:@"initmatrix"]) {
    self.graphicsState.transform = [NSAffineTransform transform];
  } else if ([token isEqualToString:@"clip"]) {
    if (!self.graphicsState.clipPath) {
      self.graphicsState.clipPath = [self.graphicsState.path copy];
    } else {
      [self.graphicsState.clipPath appendBezierPath:self.graphicsState.path];
    }
  } else if ([token isEqualToString:@"eoclip"]) {
    if (!self.graphicsState.clipPath) {
      self.graphicsState.clipPath = [self.graphicsState.path copy];
    } else {
      [self.graphicsState.clipPath appendBezierPath:self.graphicsState.path];
    }
  } else if ([token isEqualToString:@"initclip"]) {
    self.graphicsState.clipPath = nil;
  } else if ([token isEqualToString:@"translate"]) {
    NSNumber *ty = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *tx = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.graphicsState.transform translateXBy:tx.doubleValue yBy:ty.doubleValue];
  } else if ([token isEqualToString:@"scale"]) {
    NSNumber *sy = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *sx = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.graphicsState.transform scaleXBy:sx.doubleValue yBy:sy.doubleValue];
  } else if ([token isEqualToString:@"rotate"]) {
    NSNumber *angle = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.graphicsState.transform rotateByDegrees:angle.doubleValue];
  } else if ([token isEqualToString:@"concat"]) {
    NSAffineTransform *newTransform = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.graphicsState.transform appendTransform:newTransform];
  } else if ([token isEqualToString:@"newpath"]) {
    self.graphicsState.path = [NSBezierPath bezierPath];
  } else if ([token isEqualToString:@"moveto"]) {
    NSNumber *y = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *x = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSPoint pt = [self.graphicsState.transform transformPoint:NSMakePoint(x.doubleValue, y.doubleValue)];
    self.graphicsState.currentPoint = pt;
    [self.graphicsState.path moveToPoint:pt];
  } else if ([token isEqualToString:@"lineto"]) {
    NSNumber *y = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *x = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSPoint pt = [self.graphicsState.transform transformPoint:NSMakePoint(x.doubleValue, y.doubleValue)];
    self.graphicsState.currentPoint = pt;
    [self.graphicsState.path lineToPoint:pt];
  } else if ([token isEqualToString:@"closepath"]) {
    [self.graphicsState.path closePath];
  } else if ([token isEqualToString:@"stroke"]) {
    [self.graphicsState.strokeColor setStroke];
    [self.graphicsState.path setLineWidth:self.graphicsState.lineWidth];
    if (self.graphicsState.clipPath) {
      [NSGraphicsContext saveGraphicsState];
      [self.graphicsState.clipPath setWindingRule:NSEvenOddWindingRule];
      [self.graphicsState.clipPath addClip];
      [self.graphicsState.path stroke];
      [NSGraphicsContext restoreGraphicsState];
    } else {
      [self.graphicsState.path stroke];
    }
  } else if ([token isEqualToString:@"fill"]) {
    [self.graphicsState.fillColor setFill];
    if (self.graphicsState.clipPath) {
      [NSGraphicsContext saveGraphicsState];
      [self.graphicsState.clipPath setWindingRule:NSEvenOddWindingRule];
      [self.graphicsState.clipPath addClip];
      [self.graphicsState.path fill];
      [NSGraphicsContext restoreGraphicsState];
    } else {
      [self.graphicsState.path fill];
    }
  } else if ([token isEqualToString:@"setlinewidth"]) {
    NSNumber *width = self.operandStack.lastObject; [self.operandStack removeLastObject];
    self.graphicsState.lineWidth = width.doubleValue;
  } else if ([token isEqualToString:@"setrgbcolor"]) {
    NSNumber *b = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *g = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *r = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSColor *color = [NSColor colorWithCalibratedRed:r.doubleValue green:g.doubleValue blue:b.doubleValue alpha:1.0];
    self.graphicsState.strokeColor = color;
    self.graphicsState.fillColor = color;
  } else if ([token isEqualToString:@"scalefont"]) {
    NSNumber *scale = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSFontDescriptor *desc = [self.graphicsState.font fontDescriptor];
    self.graphicsState.font = [NSFont fontWithDescriptor:desc size:scale.doubleValue];
  } else if ([token isEqualToString:@"setfont"]) {
    NSString *fontName = self.operandStack.lastObject; [self.operandStack removeLastObject];
    self.graphicsState.font = [NSFont fontWithName:fontName size:12] ?: [NSFont systemFontOfSize:12];
  } else if ([token isEqualToString:@"show"]) {
    NSString *text = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSDictionary *attrs = @{ NSFontAttributeName: self.graphicsState.font, NSForegroundColorAttributeName: self.graphicsState.strokeColor };
    [text drawAtPoint:self.graphicsState.currentPoint withAttributes:attrs];
  } else if ([token isEqualToString:@"add"]) {
    NSNumber *b = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *a = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.operandStack addObject:@([a doubleValue] + [b doubleValue])];
  } else if ([token isEqualToString:@"sub"]) {
    NSNumber *b = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *a = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.operandStack addObject:@([a doubleValue] - [b doubleValue])];
  } else if ([token isEqualToString:@"mul"]) {
    NSNumber *b = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *a = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.operandStack addObject:@([a doubleValue] * [b doubleValue])];
  } else if ([token isEqualToString:@"div"]) {
    NSNumber *b = self.operandStack.lastObject; [self.operandStack removeLastObject];
    NSNumber *a = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.operandStack addObject:@([a doubleValue] / [b doubleValue])];
  } else if ([token isEqualToString:@"dup"]) {
    id top = self.operandStack.lastObject;
    [self.operandStack addObject:top];
  } else if ([token isEqualToString:@"exch"]) {
    id b = self.operandStack.lastObject; [self.operandStack removeLastObject];
    id a = self.operandStack.lastObject; [self.operandStack removeLastObject];
    [self.operandStack addObject:b];
    [self.operandStack addObject:a];
  } else if ([token isEqualToString:@"pop"]) {
    [self.operandStack removeLastObject];
  } else if ([token isEqualToString:@"clear"]) {
    [self.operandStack removeAllObjects];
  } else if ([token isEqualToString:@"stack"]) {
    NSLog(@"Stack: %@", self.operandStack);
  } else if ([token isEqualToString:@"exit"]) {
    self.exitFlag = YES;
  } else if ([token isEqualToString:@"if"]) {
    id proc = [self.operandStack lastObject]; [self.operandStack removeLastObject];
    NSNumber *cond = [self.operandStack lastObject]; [self.operandStack removeLastObject];
    if ([cond boolValue] && [proc isKindOfClass:[NSArray class]]) {
      for (NSString *tok in proc) {
	[self executeToken:tok];
      }
    }
  } else if ([token isEqualToString:@"ifelse"]) {
    id elseProc = [self.operandStack lastObject]; [self.operandStack removeLastObject];
    id thenProc = [self.operandStack lastObject]; [self.operandStack removeLastObject];
    NSNumber *cond = [self.operandStack lastObject]; [self.operandStack removeLastObject];
    NSArray *proc = [cond boolValue] ? thenProc : elseProc;
    if ([proc isKindOfClass:[NSArray class]]) {
      for (NSString *tok in proc) {
	[self executeToken:tok];
      }
    }
  } else if ([token isEqualToString:@"for"]) {
    id proc = [self.operandStack lastObject]; [self.operandStack removeLastObject];
    NSNumber *inc = [self.operandStack lastObject]; [self.operandStack removeLastObject];
    NSNumber *limit = [self.operandStack lastObject]; [self.operandStack removeLastObject];
    NSNumber *start = [self.operandStack lastObject]; [self.operandStack removeLastObject];
    for (double i = [start doubleValue]; (inc.doubleValue > 0) ? i <= limit.doubleValue : i >= limit.doubleValue; i += inc.doubleValue) {
      if (self.exitFlag) break;
      [self.operandStack addObject:@(i)];
      for (NSString *tok in proc) {
	[self executeToken:tok];
	if (self.exitFlag) break;
      }
      [self.operandStack removeLastObject];
    }
    self.exitFlag = NO;
  } else if ([token isEqualToString:@"repeat"]) {
    id proc = [self.operandStack lastObject]; [self.operandStack removeLastObject];
    NSNumber *count = [self.operandStack lastObject]; [self.operandStack removeLastObject];
    for (NSInteger i = 0; i < count.integerValue; i++) {
      if (self.exitFlag) break;
      for (NSString *tok in proc) {
	[self executeToken:tok];
	if (self.exitFlag) break;
      }
    }
    self.exitFlag = NO;
  } else if ([token isEqualToString:@"loop"]) {
    id proc = [self.operandStack lastObject];
    while (!self.exitFlag) {
      for (NSString *tok in proc) {
	[self executeToken:tok];
	if (self.exitFlag) break;
      }
    }
    self.exitFlag = NO;
  } else if ([token isEqualToString:@"def"]) {
    id proc = [self.operandStack lastObject]; [self.operandStack removeLastObject];
    NSString *name = self.operandStack.lastObject; [self.operandStack removeLastObject];
    if ([name hasPrefix:@"/"]) {
      name = [name substringFromIndex:1];
      NSMutableDictionary *topDict = self.dictionaryStack.lastObject;
      topDict[name] = proc;
    }
  } else {
    NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
    NSNumber *num = [fmt numberFromString:token];
    if (num) {
      [self.operandStack addObject:num];
    } else if ([token hasPrefix:@"["] && [token hasSuffix:@"]"]) {
      NSString *inner = [token substringWithRange:NSMakeRange(1, token.length - 2)];
      NSArray *tokens = [inner componentsSeparatedByString:@" "];
      [self.operandStack addObject:tokens];
    } else {
      for (NSDictionary *dict in [self.dictionaryStack reverseObjectEnumerator]) {
	id val = dict[token];
	if (val) {
	  if ([val isKindOfClass:[NSArray class]]) {
	    for (NSString *tok in val) {
	      [self executeToken:tok];
	    }
	  } else {
	    [self.operandStack addObject:val];
	  }
	  return;
	}
      }
      [self.operandStack addObject:token];
    }
  }
}

@end

@interface PSRenderView : NSView
@property (nonatomic, strong) PSInterpreter *interpreter;
@end

@implementation PSRenderView
- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [self.interpreter executeToken:@"stroke"];
}
@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
	NSApplication *app = [NSApplication sharedApplication];
	NSRect frame = NSMakeRect(0, 0, 400, 400);
	NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
						       styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable)
							 backing:NSBackingStoreBuffered
							   defer:NO];
	[window setTitle:@"PostScript Renderer"];
	[window center];

	PSInterpreter *interpreter = [[PSInterpreter alloc] init];
	PSRenderView *view = [[PSRenderView alloc] initWithFrame:frame];
	view.interpreter = interpreter;
	interpreter.renderView = view;

	NSArray *program = @[@"newpath", @"100", @"100", @"moveto", @"200", @"200", @"lineto", @"300", @"100", @"lineto", @"closepath",
			      @"0.2", @"0.4", @"0.6", @"setrgbcolor", @"setlinewidth", @"4", @"stroke", @"100", @"50", @"moveto",
			      @"Helvetica", @"setfont", @"24", @"scalefont", @"Hello, PostScript!", @"show"];
	for (NSString *token in program) {
	    [interpreter executeToken:token];
	}

	[window setContentView:view];
	[window makeKeyAndOrderFront:nil];
	[app run];
    }
    return 0;
}
