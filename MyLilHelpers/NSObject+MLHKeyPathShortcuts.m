//
//  NSObject+MLHKeyPathShortcuts.m
//  MyLilHelpers
//
//  Created by Jonathon Mah on 2014-03-08.
//  Copyright (c) 2014 Jonathon Mah. All rights reserved.
//

#import "NSObject+MLHKeyPathShortcuts.h"


@interface MLHClassesContainer : NSObject
@end


@implementation NSObject (MLHKeyPathShortcuts)

- (id)$classes
{
    static dispatch_once_t onceToken;
    static MLHClassesContainer *classesContainer;
    dispatch_once(&onceToken, ^{
        classesContainer = [MLHClassesContainer new];
    });
    return classesContainer;
}

- (NSUserDefaults *)$defaults
{ return [NSUserDefaults standardUserDefaults]; }

#ifdef MLH_APP_CLASS
- (MLH_APP_CLASS *)$app
{ return [MLH_APP_CLASS sharedApplication]; }
#endif

@end


@implementation MLHClassesContainer

- (id)valueForKey:(NSString *)key
{ return NSClassFromString(key); }

@end
