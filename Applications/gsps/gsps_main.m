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
#import <GSPS/PSRenderView.h>

int main(int argc, const char * argv[])
{
    @autoreleasepool
      {
        if (argc < 2)
	  {
            puts("Usage: gsps <path-to-ps-file>\n");
            return 1;
	  }
	else
	  {
	    NSApplication *app = [NSApplication sharedApplication];
	    NSRect frame = NSMakeRect(0, 0, 400, 400);
	    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
							   styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable)
							     backing:NSBackingStoreBuffered
							       defer:NO];
	    
	    
	    NSString *filePath = [NSString stringWithUTF8String:argv[1]];
	    PSInterpreter *interpreter = [[PSInterpreter alloc] init];
	    PSRenderView *view = [[PSRenderView alloc] initWithFrame:frame];
	    view.interpreter = interpreter;
	    interpreter.renderView = view;
	    
	    [interpreter interpretFileAtPath:filePath];

	    [window setContentView:view];
	    [window makeKeyAndOrderFront:nil];
	    [app run];
	  }
      }
    
    return 0;
}
