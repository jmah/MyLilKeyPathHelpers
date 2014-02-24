//
//  DefiningClass.h
//  MyLilHelpers
//
//  Created by Jonathon Mah on 2014-02-24.
//  Copyright (c) 2014 Jonathon Mah. All rights reserved.
//

#import <Foundation/NSObjCRuntime.h>


Class MyLilHelpers_DefiningClassFromFunc(const char *func);

// Check we're in an Objective-C method context by messaging super
#if ALLOW_DEFINING_CLASS_IN_ROOT_CLASSES
#define _definingClass  MyLilHelpers_DefiningClassFromFunc(__func__)
#else
// Attempt to check that use is in an Objective-C method context by messaging super.
// This will be an error for root classes, so #define ALLOW_DEFINING_CLASS_IN_ROOT_CLASSES 1 to skip.
#define _definingClass  __builtin_choose_expr(0, [super class], MyLilHelpers_DefiningClassFromFunc(__func__))
#endif
