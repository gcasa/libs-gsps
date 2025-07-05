/*                                                                                                                                                                                                                                     
  Copyright (C) 2013 Free Software Foundation, Inc.                                                                                                                                                                                   

  Author:  Gregory Casamento <greg.casamento@gmail.com>                                                                                                                                                                    
  Date: 2025
  This file is part of the GNUstep GUI Library.

  This library is free software; you can redistribute it and/or                                                                                                                                                                       
  modify it under the terms of the GNU Lesser General Public                                                                                                                                                                          
  License as published by the Free Software Foundation; either                                                                                                                                                                        
  version 2 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of                                                                                                                                                                   
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.
                                                                                                                                                                                                                                          
  You should have received a copy of the GNU Lesser General Public
  License along with this library; see the file COPYING.LIB. 
  If not, see <http://www.gnu.org/licenses/> or write to the
  Free Software Foundation, 51 Franklin Street, Fifth Floor,
  Boston, MA 02110-1301, USA.
*/

#import <GSPS/PSGraphicsState.h>
#import <GSPS/PSInterpreter.h>

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
