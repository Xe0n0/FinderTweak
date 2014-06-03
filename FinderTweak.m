//
//  FinderTweak.m
//  FinderTweak
//
//  Created by wuhaotian on 6/19/13.
//  Copyright (c) 2013 wuhaotian. All rights reserved.
//

#import "FinderTweak.h"
#import "JRSwizzle.h"

@implementation FinderTweak

+ (NSString *)pluginVersion
{
    return [[[NSBundle bundleForClass:self] infoDictionary] objectForKey:@"CFBundleVersion"];
}

+ (void)load
{
    NSLog(@"Finder Tweak Loaded");
    
    NSError *e = nil;
    
    if (![NSClassFromString(@"TApplication") jr_swizzleMethod:@selector(sendEvent:) withMethod:@selector(FinderTabSwitching_sendEvent:) error:&e])
        NSLog(@"%@", e);
  
  if (![NSClassFromString(@"TGlobalWindowController") jr_swizzleClassMethod:
        @selector(selectOrCreateWindowWithOptions:inTarget:) withClassMethod:@selector(FTSelectOrCreateWindowWithOptions:inTarget:) error:&e])
        NSLog(@"%@", e);
  
  if (![NSClassFromString(@"TGlobalWindowController") jr_swizzleMethod:
        @selector(shouldUseMergeAllWindowsAnimation) withMethod:
        @selector(FTShouldUseMergeAllWindowsAnimation) error:&e])
        NSLog(@"%@", e);
  
    if (![NSClassFromString(@"TApplication") jr_swizzleMethod:
    @selector(nextEventMatchingMask:untilDate:inMode:dequeue:)
          withMethod:@selector(FTS_nextEventMatchingMask:untilDate:inMode:dequeue:) error:&e])
        
        NSLog(@"%@", e);
}
@end
//only for debug

@implementation NSView(FinderTweak)

- (void)logViewHierarchy:(NSInteger )level
{
  NSLog(@"%ld: %@", (long)level, self);
  for (NSView *subview in self.subviews)
  {
    [subview logViewHierarchy:level + 1];
  }
}

- (id)searchForSelect:(SEL)selector maxLevel:(long long)level {
  
  if ([self respondsToSelector:selector]) {
    return self;
  }
  else if (level > 0) {
  
    NSView *view;
    for (NSView *subview in self.subviews)
    {
      if ((view = [subview searchForSelect:selector maxLevel:level - 1]))
        return view;
    }
    
  }
  
  return nil;
}

- (void)logSuper:(long)level {
  NSLog(@"%ld: %@", level, self);
  if ([self superview]) {
    [[self superview] logSuper:level - 1];
  }
  else
    NSLog(@"%@",  [self window]);
}

@end

@implementation NSObject(FinderTweak)

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

- (void)XRLog2:(id)obj arg2:(id)arg2
{
  [self log_stack];
  [self XRLog2:obj arg2:arg2];
}

- (void)XRLog
{
  [self log_stack];
  [self XRLog];
}

- (void)XRLog1:(id)obj
{
  
    [self log_stack];
    [self XRLog1:obj];
    
}

@end


@implementation NSResponder (FinderTweak)

- (BOOL)FTShouldUseMergeAllWindowsAnimation
{
  return NO;
}

+ (id)FTSelectOrCreateWindowWithOptions:(id)arg1 inTarget:(const void *)arg2
{
  //id obj = [self globalWindowController];
  id browser = [self frontmostBrowserWindowController];
  if ([browser respondsToSelector:@selector(selectOrCreateTabWithTarget:windowOptions:addAfterActiveTab:)])
      [browser selectOrCreateTabWithTarget:arg2 windowOptions:arg1 addAfterActiveTab:YES];
  return [self FTSelectOrCreateWindowWithOptions:arg1 inTarget:arg2];
}

@end

@implementation NSApplication(FinderTweak)


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
  if (event.type == NSKeyDown) {
    
  }
    
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
            __block NSView * tabView = nil;
            NSWindow *keyWindow = [[NSApplication sharedApplication] keyWindow];
          
            [[[keyWindow contentView] subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
              
                if ([obj respondsToSelector:@selector(selectTabViewItemAtIndex:)]) {
                  tabView = obj;
                }
            }];
          
          if (tabView == nil) {
            tabView = [[[[keyWindow contentView] superview] subviews][1] searchForSelect:@selector(selectTabViewItemAtIndex:) maxLevel:3];
          }
          
          
            NSViewController * controller = keyWindow.windowController;
          
            if (tabView != nil && [controller respondsToSelector:@selector(tabCount)])
            {
                long long tabCount = [controller performSelector:@selector(tabCount) withObject:nil];
                tabIndex = tabCount >= (tabIndex + 1) ? tabIndex: tabCount - 1;
                
                [tabView performSelector:@selector(selectTabViewItemAtIndex:) withObject:(id)tabIndex];
                
            }
            return;
        }
    }
    
    [self FinderTabSwitching_sendEvent:event];
}

@end

