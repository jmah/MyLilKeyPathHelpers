//
//  MLHDependentKeyPaths.m
//  MyLilKeyPathHelpers
//
//  Created by Jonathon Mah on 2014-03-01.
//  Copyright (c) 2014 Jonathon Mah. All rights reserved.
//

#import "MLHDependentKeyPaths.h"

#import <objc/message.h>
#import <objc/runtime.h>


static const char *dependentKeyPrefix = "keyPathsForValuesAffecting";
static const NSUInteger dependentKeyPrefixLength = 26; // without NUL


SEL MLHDependentKeySelectorForKey(NSString *key)
{
    NSUInteger lengthWithNul = [key lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1;
    if (lengthWithNul <= 1)
        return NULL;

    char str[dependentKeyPrefixLength + lengthWithNul];
    strncpy(str, dependentKeyPrefix, dependentKeyPrefixLength);
    if (![key getCString:(str + dependentKeyPrefixLength) maxLength:lengthWithNul encoding:NSUTF8StringEncoding])
        return NULL;

    str[dependentKeyPrefixLength] = (char)toupper(str[dependentKeyPrefixLength]);
    return sel_registerName(str);
}


NSSet *MLHSuperclassKeyPathsAffecting(Class definingClass, NSString *key)
{
    return [[definingClass superclass] keyPathsForValuesAffectingValueForKey:key];
}


NSSet *MLHOverrideKeyPathsForValueAffectingKey(Class self, Class definingClass, BOOL affectOwnKeys, NSString *key, NSSet *(^customizeBlock)(NSSet *))
{
    SEL _cmd = @selector(keyPathsForValuesAffectingValueForKey:);
    SEL dependentSel = MLHDependentKeySelectorForKey(key);

    Class overrideBase = affectOwnKeys ? definingClass : [definingClass superclass];
    BOOL dependentSelOverridden = (class_getMethodImplementation(object_getClass(self), dependentSel) !=
                                   class_getMethodImplementation(object_getClass(overrideBase), dependentSel));

    if (dependentSelOverridden) {
        // If a subclass of the defining class overrides +keyPathsForValueAffecting<Foo>, call it.
        return method_invoke(self, class_getClassMethod(self, dependentSel));
        // (Another option: Jump up to NSObject's implementation, which will repeat the key mangling and call.)
        //return method_invoke(self, class_getClassMethod([NSObject class], _cmd), key);
    } else {
        // Otherwise call super...
        NSSet *dependentKeyPaths = method_invoke(self, class_getClassMethod([definingClass superclass], _cmd), key);
        // and allow altering the result.
        if (customizeBlock) {
            dependentKeyPaths = customizeBlock(dependentKeyPaths);
        }
        return dependentKeyPaths;
    }
}
