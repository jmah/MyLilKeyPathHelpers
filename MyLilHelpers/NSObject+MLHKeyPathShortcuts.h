//
//  NSObject+MLHKeyPathShortcuts.h
//  MyLilHelpers
//
//  Created by Jonathon Mah on 2014-03-08.
//  Copyright (c) 2014 Jonathon Mah. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<UIKit/UIApplication.h>)
#   import <UIKit/UIApplication.h>
#   define MLH_APP_CLASS UIApplication
#elif __has_include(<AppKit/NSApplication.h>)
#   import <AppKit/NSApplication.h>
#   define MLH_APP_CLASS NSApplication
#endif


@interface NSObject (MLHKeyPathShortcuts)

- (id)$classes;

- (NSUserDefaults *)$defaults;

#ifdef MLH_APP_CLASS
- (MLH_APP_CLASS *)$app;
#endif

@end
