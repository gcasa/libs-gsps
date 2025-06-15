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
@property (nonatomic) NSAffineTransform *transform;
@end

@implementation PSGraphicsState
- (instancetype)init {
    if (self = [super init]) {
        _currentPoint = NSZeroPoint;
        _path = [NSBezierPath bezierPath];
        _lineWidth = 1.0;
        _strokeColor = [NSColor blackColor];
        _fillColor = [NSColor blackColor];
        _font = [NSFont systemFontOfSize:12];
        _transform = [NSAffineTransform transform];
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
@property (nonatomic, strong) NSView *renderView;
- (void)executeToken:(NSString *)token;
@end

@implementation PSInterpreter

- (instancetype)init {
    if (self = [super init]) {
        _operandStack = [NSMutableArray array];
        _dictionaryStack = [NSMutableArray arrayWithObject:[NSMutableDictionary dictionary]];
        _graphicsStack = [NSMutableArray array];
        _graphicsState = [[PSGraphicsState alloc] init];
        _exitFlag = NO;
    }
    return self;
}

- (void)executeToken:(NSString *)token {
    if (self.exitFlag) return;

    if ([token isEqualToString:@"gsave"]) {
        PSGraphicsState *copy = [[PSGraphicsState alloc] init];
        copy.currentPoint = self.graphicsState.currentPoint;
        copy.path = [self.graphicsState.path copy];
        copy.lineWidth = self.graphicsState.lineWidth;
        copy.strokeColor = self.graphicsState.strokeColor;
        copy.fillColor = self.graphicsState.fillColor;
        copy.font = self.graphicsState.font;
        copy.transform = [self.graphicsState.transform copy];
        [self.graphicsStack addObject:copy];
    } else if ([token isEqualToString:@"grestore"]) {
        if (self.graphicsStack.count > 0) {
            self.graphicsState = [self.graphicsStack lastObject];
            [self.graphicsStack removeLastObject];
        }
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
        [self.graphicsState.path stroke];
    } else if ([token isEqualToString:@"fill"]) {
        [self.graphicsState.fillColor setFill];
        [self.graphicsState.path fill];
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
        NSFont *scaledFont = [[self.graphicsState.font fontDescriptor] fontDescriptorWithSize:scale.doubleValue];
        self.graphicsState.font = [NSFont fontWithDescriptor:scaledFont size:scale.doubleValue];
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
        } else if ([token hasPrefix:@"["] && [token hasSuffix:@"]") {
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
