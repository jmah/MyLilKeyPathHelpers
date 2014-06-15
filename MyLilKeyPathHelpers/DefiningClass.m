//
//  DefiningClass.m
//  MyLilKeyPathHelpers
//
//  Created by Jonathon Mah on 2014-02-24.
//  Copyright (c) 2014 Jonathon Mah. All rights reserved.
//

#import "DefiningClass.h"

#import <alloca.h>
#import <objc/runtime.h>


Class MyLilKeyPathHelpers_DefiningClassFromFunc(const char *func)
{
    // __func__ looks like this:
    //   "+[SomeClass classSel:]"
    //   "-[SomeClass instanceSel:]"
    //   "-[SomeClass(Category) sel:ec:tor:]"

    const char *classStart = func;
    while (*classStart != '[')
        if (*classStart++ == '\0')
            return Nil;
    classStart++; // step over open bracket

    const char *classAfter = classStart;
    while (*classAfter != ' ' && *classAfter != '(')
        if (*classAfter++ == '\0')
            return Nil;

    size_t classNameLength = classAfter - classStart;
    char *classBuffer = alloca(classNameLength + 1);
    classBuffer[classNameLength] = '\0';

    char *classBufferCursor = classBuffer;
    for (const char *funcCursor = classStart; funcCursor < classAfter; funcCursor++)
        *classBufferCursor++ = *funcCursor;

    return objc_getClass(classBuffer);
}
