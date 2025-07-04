#import "PSGraphicsState.h"

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

