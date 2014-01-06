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
    
    NSError *e = nil;
    
    if (![NSClassFromString(@"TApplication") jr_swizzleMethod:@selector(sendEvent:) withMethod:@selector(FinderTabSwitching_sendEvent:) error:&e])
    
        NSLog(@"%@", e);
    
    //if (![NSClassFromString(@"TApplicationController") jr_swizzleMethod:@selector(cmdCycleWindows:) withMethod:@selector(XRLog:) error:&e])
     //   NSLog(@"%@", e);
   
    if (![NSClassFromString(@"TApplication") jr_swizzleMethod:
    @selector(nextEventMatchingMask:untilDate:inMode:dequeue:)
          withMethod:@selector(FTS_nextEventMatchingMask:untilDate:inMode:dequeue:) error:&e])
        
        NSLog(@"%@", e);

}
@end

@implementation NSObject(FinderTabSwitching)

- (void)log_stack
{
    
    
    [[NSThread callStackSymbols] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *sourceString = obj;
    
        NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@" -[]+?.,"];
        NSMutableArray *array = [NSMutableArray arrayWithArray:[sourceString  componentsSeparatedByCharactersInSet:separatorSet]];
        [array removeObject:@""];
        
        NSLog(@"Stack = %@", [array objectAtIndex:0]);
        NSLog(@"Framework = %@", [array objectAtIndex:1]);
        NSLog(@"Memory address = %@", [array objectAtIndex:2]);
        NSLog(@"Class caller = %@", [array objectAtIndex:3]);
        NSLog(@"Function caller = %@", [array objectAtIndex:4]);
        if ([[array objectAtIndex:3] isEqualTo:@"NSApplicationMain"]) *stop = YES;
    }];
}

- (void)XRLog:(id)obj
{
    [self log_stack];
    [self XRLog:obj];
    
}

@end

@implementation NSApplication(FinderTabSwitching)


- (NSEvent *)FTS_nextEventMatchingMask:(NSUInteger)mask untilDate:(NSDate *)expiration inMode:(NSString *)mode dequeue:(BOOL)deqFlag
{
    NSEvent *event = [self FTS_nextEventMatchingMask:mask untilDate:expiration inMode:mode dequeue:deqFlag];
  
    if (event.type == NSKeyDown
        && (event.modifierFlags & NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask) // only command modifier pressed
    {
          NSString *source = [[NSThread callStackSymbols] objectAtIndex:1];
          if ([source rangeOfString:@"NSApplication"].location == NSNotFound) {
              [NSApp sendEvent:event];
          }
          return nil;
    }
  
    return event;
}

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

