//
//  DefiningClass.h
//  MyLilHelpers
//
//  Created by Jonathon Mah on 2014-02-24.
//  Copyright (c) 2014 Jonathon Mah. All rights reserved.
//

#import <Foundation/NSObjCRuntime.h>


Class MyLilHelpers_DefiningClassFromFunc(const char *func);

#if DEFINING_CLASS_ALLOW_USE_IN_ROOT_CLASS
#   define DEFINING_CLASS_USE_SUPER_CHECK 1
#endif


#if DEFINING_CLASS_USE_SUPER_CHECK

// Attempt to check that use is in an Objective-C method context by messaging super.
// This will be an error for root classes, so #define ALLOW_DEFINING_CLASS_IN_ROOT_CLASSES 1 to skip.
#define _definingClass  __builtin_choose_expr(0, [super class], MyLilHelpers_DefiningClassFromFunc(__func__))

#else

#define _definingClass  MyLilHelpers_DefiningClassFromFunc(__func__)

#endif
