//
//  FinderTabSwitching.m
//  FinderTabSwitching
//
//  Created by wuhaotian on 6/19/13.
//  Copyright (c) 2013 wuhaotian. All rights reserved.
//

#import "FinderTabSwitching.h"
#import "JRSwizzle.h"

@implementation FinderTabSwitching

+ (NSString *)pluginVersion
{
    return [[[NSBundle bundleForClass:self] infoDictionary] objectForKey:@"CFBundleVersion"];
}

+ (void)load
{
    NSLog(@"Finder Tab Switching Loaded");
    [NSClassFromString(@"NSApplication") jr_swizzleMethod:@selector(sendEvent:) withMethod:@selector(FinderTabSwitching_sendEvent:) error:NULL];
}

@end


@implementation NSApplication(FinderTabSwitching)

- (void)FinderTabSwitching_sendEvent:(NSEvent *)event
{
    static NSArray *keyCode2TabIndex = nil;
    
    if (event.type == NSKeyDown
        && (event.modifierFlags & NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask) // only command modifier pressed
    {
        if (!keyCode2TabIndex)
        {
            keyCode2TabIndex = [[NSArray alloc] initWithObjects:@"18", @"19", @"20", @"21", @"23", @"22", @"26", @"28", @"25", nil];
        }
        
        NSUInteger tabIndex = [keyCode2TabIndex indexOfObject:[[NSNumber numberWithInt:event.keyCode] stringValue]];
        
        if (tabIndex != NSNotFound)
        {
            NSWindow *keyWindow = [[NSApplication sharedApplication] keyWindow];
            NSArray * views = [[keyWindow contentView] subviews];
            NSView * tabView = nil;
            if (views.count) {
                tabView = [[keyWindow contentView] subviews][0];
            }
            NSViewController * controller = keyWindow.windowController;
            NSLog(@"%@", keyWindow.windowController);
            if ([tabView respondsToSelector:@selector(selectTabViewItemAtIndex:)] && [controller respondsToSelector:@selector(tabCount)])
            {
                long long tabCount = [controller performSelector:@selector(tabCount) withObject:nil];
                tabIndex = tabCount >= (tabIndex + 1) ? tabIndex: tabCount - 1;
                
                [tabView performSelector:@selector(selectTabViewItemAtIndex:) withObject:(id)tabIndex];
                
                return; // prevent event dispatching
            }
        }
    }
    
    [self FinderTabSwitching_sendEvent:event];
}

@end

