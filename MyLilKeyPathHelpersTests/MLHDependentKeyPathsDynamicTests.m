//
//  MLHDependentKeyPathsDynamicTests.m
//  MyLilKeyPathHelpers
//
//  Created by Jonathon Mah on 2014-03-01.
//  Copyright (c) 2014 Jonathon Mah. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MyLilKeyPathHelpers.h"
#import <objc/runtime.h>
#import <objc/message.h>


@interface MLHDependentKeyPathsDynamicTests : XCTestCase

@end


/*
 * This tests several variations of dependent key paths configurations:
 *
 * - Subclass doing nothing
 * - Subclass adding a dependent key path to super's set
 * - Subclass replacing super's set
 * - Subclass returning an empty set
 *
 * Each of these variations can be implemented by overriding +keyPathsForValuesAffectingFoo,
 * or overriding +keyPathsForValuesAffectingKey: and testing the argument against @"foo".
 *
 * To explore all these combinations, there is first some machinery to dynamically implement this
 * behavior. -testDynamicDependentMethodMachinery tests this.
 *
 * This is followed by code to enumerate these possibilities and create an "expected" set, based
 * on the combinations set on the class hierarchy.
 */

static NSUInteger nextKeyCounter;
static NSString *keyForCounter(NSUInteger i) {
    return [NSString stringWithFormat:@"key%lu", i];
}

@interface KPADBase : NSObject
+ (void)setDirectMethodDependents:(NSSet *)deps forKey:(NSString *)key class:(Class)cls replacesSuperDependents:(BOOL)replaces;
+ (void)setMuxMethodDependents:(NSSet *)deps forKey:(NSString *)key class:(Class)cls replacesSuperDependents:(BOOL)replaces;
@end

@interface KPADSubOne : KPADBase
@end

@interface KPADSubTwo : KPADSubOne
@end


@implementation MLHDependentKeyPathsDynamicTests

- (void)testDynamicDependentMethodMachinery
{
    NSSet *fooSet = [NSSet setWithObject:@"foo"];
    NSSet *barSet = [NSSet setWithObject:@"bar"];
    NSSet *fooBarSet = [fooSet setByAddingObjectsFromSet:barSet];


    NSString *baseOnly = keyForCounter(++nextKeyCounter);
    XCTAssert(class_getClassMethod([KPADBase class], MLHDependentKeySelectorForKey(baseOnly)) == NULL);
    [KPADBase setDirectMethodDependents:fooSet forKey:baseOnly class:[KPADBase class] replacesSuperDependents:YES];
    XCTAssert(class_getClassMethod([KPADBase class], MLHDependentKeySelectorForKey(baseOnly)) != NULL);

    XCTAssertEqualObjects([KPADBase performSelector:MLHDependentKeySelectorForKey(baseOnly)], fooSet);
    XCTAssertEqualObjects([KPADBase keyPathsForValuesAffectingValueForKey:baseOnly], fooSet);
    XCTAssertEqualObjects([KPADSubOne performSelector:MLHDependentKeySelectorForKey(baseOnly)], fooSet);
    XCTAssertEqualObjects([KPADSubTwo performSelector:MLHDependentKeySelectorForKey(baseOnly)], fooSet);


    NSString *baseAndReplace = keyForCounter(++nextKeyCounter);
    [KPADBase setDirectMethodDependents:fooSet forKey:baseAndReplace class:[KPADBase class] replacesSuperDependents:YES];
    [KPADBase setDirectMethodDependents:barSet forKey:baseAndReplace class:[KPADSubOne class] replacesSuperDependents:YES];
    XCTAssertEqualObjects([KPADBase performSelector:MLHDependentKeySelectorForKey(baseAndReplace)], fooSet);
    XCTAssertEqualObjects([KPADSubOne performSelector:MLHDependentKeySelectorForKey(baseAndReplace)], barSet);
    XCTAssertEqualObjects([KPADSubTwo performSelector:MLHDependentKeySelectorForKey(baseAndReplace)], barSet);


    NSString *baseAndAdd = keyForCounter(++nextKeyCounter);
    [KPADBase setDirectMethodDependents:fooSet forKey:baseAndAdd class:[KPADBase class] replacesSuperDependents:YES];
    [KPADBase setDirectMethodDependents:barSet forKey:baseAndAdd class:[KPADSubOne class] replacesSuperDependents:NO];
    XCTAssertEqualObjects([KPADBase performSelector:MLHDependentKeySelectorForKey(baseAndAdd)], fooSet);
    XCTAssertEqualObjects([KPADSubOne performSelector:MLHDependentKeySelectorForKey(baseAndAdd)], fooBarSet);
    XCTAssertEqualObjects([KPADSubTwo performSelector:MLHDependentKeySelectorForKey(baseAndAdd)], fooBarSet);


    NSString *muxOneOnly = keyForCounter(++nextKeyCounter);
    [KPADBase setMuxMethodDependents:fooSet forKey:muxOneOnly class:[KPADSubOne class] replacesSuperDependents:NO];
    XCTAssertFalse([KPADBase respondsToSelector:MLHDependentKeySelectorForKey(muxOneOnly)]);
    XCTAssertFalse([KPADSubOne respondsToSelector:MLHDependentKeySelectorForKey(muxOneOnly)]);
    XCTAssertEqualObjects([KPADBase keyPathsForValuesAffectingValueForKey:muxOneOnly], [NSSet set]);
    XCTAssertEqualObjects([KPADSubOne keyPathsForValuesAffectingValueForKey:muxOneOnly], fooSet);
    XCTAssertEqualObjects([KPADSubTwo keyPathsForValuesAffectingValueForKey:muxOneOnly], fooSet);
}


NS_ENUM(NSInteger, KeyPathDependencyType) {
    KPDTNone = 0,
    KPDTAddDirectKey = 0x01,
    KPDTClearDirectKey = 0x02,
    KPDTReplaceDirectKey = 0x03,
    KPDTAddMuxKey = 0x11,
    KPDTClearMuxKey = 0x12,
    KPDTReplaceMuxKey = 0x13,
};

static void modifyExpectedForDependencyType(NSMutableSet *expectedSet, Class cls, enum KeyPathDependencyType type) {
    if (type == KPDTNone)
        return;

    BOOL add = (type & 0x01) != 0;
    BOOL clear = (type & 0x02) != 0;
    if (clear) {
        [expectedSet removeAllObjects];
    }
    if (add) {
        [expectedSet addObject:NSStringFromClass(cls)];
    }
}

static void modifyClassForDependencyType(Class cls, NSString *key, enum KeyPathDependencyType type) {
    if (type == KPDTNone)
        return;

    BOOL add = (type & 0x01) != 0;
    BOOL clear = (type & 0x02) != 0;
    BOOL mux = (type & 0x10) != 0;
    NSSet *dependent = add ? [NSSet setWithObject:NSStringFromClass(cls)] : [NSSet set];
    if (mux) {
        [KPADBase setMuxMethodDependents:dependent forKey:key class:cls replacesSuperDependents:clear];
    } else {
        [KPADBase setDirectMethodDependents:dependent forKey:key class:cls replacesSuperDependents:clear];
    }
}

static NSString *charForDependencyType(enum KeyPathDependencyType type) {
    switch (type) {
        case KPDTNone: return @"-";
        case KPDTAddDirectKey: return @"A";
        case KPDTClearDirectKey: return @"X";
        case KPDTReplaceDirectKey: return @"R";
        case KPDTAddMuxKey: return @"a";
        case KPDTClearMuxKey: return @"x";
        case KPDTReplaceMuxKey: return @"r";
    }
}


- (void)testOverrideCombinations
{
    NSArray *dependencyTypes = @[@(KPDTNone), @(KPDTAddDirectKey), @(KPDTClearDirectKey), @(KPDTReplaceDirectKey), @(KPDTAddMuxKey), @(KPDTClearMuxKey), @(KPDTReplaceMuxKey)];

    for (NSNumber *baseTypeNum in dependencyTypes) {
        for (NSNumber *subOneTypeNum in dependencyTypes) {
            for (NSNumber *subTwoTypeNum in dependencyTypes) {

                NSString *key = keyForCounter(++nextKeyCounter);

                NSMutableString *typeCode = [NSMutableString new];
                for (NSNumber *type in @[baseTypeNum, subOneTypeNum, subTwoTypeNum])
                    [typeCode appendString:charForDependencyType(type.integerValue)];

                enum KeyPathDependencyType baseType = baseTypeNum.integerValue;
                enum KeyPathDependencyType subOneType = subOneTypeNum.integerValue;
                enum KeyPathDependencyType subTwoType = subTwoTypeNum.integerValue;

                modifyClassForDependencyType([KPADBase class], key, baseType);
                modifyClassForDependencyType([KPADSubOne class], key, subOneType);
                modifyClassForDependencyType([KPADSubTwo class], key, subTwoType);

                NSMutableSet *expected = [NSMutableSet new];
                modifyExpectedForDependencyType(expected, [KPADBase class], baseType);
                XCTAssertEqualObjects([KPADBase keyPathsForValuesAffectingValueForKey:key], expected, @"Failed with %@", typeCode);

                modifyExpectedForDependencyType(expected, [KPADSubOne class], subOneType);
                XCTAssertEqualObjects([KPADSubOne keyPathsForValuesAffectingValueForKey:key], expected, @"Failed with %@", typeCode);

                modifyExpectedForDependencyType(expected, [KPADSubTwo class], subTwoType);
                XCTAssertEqualObjects([KPADSubTwo keyPathsForValuesAffectingValueForKey:key], expected, @"Failed with %@", typeCode);
            }
        }
    }
}

@end


@implementation KPADBase

static NSMapTable *muxModifiersByKeyByClass;

typedef NSSet *(^KeyModifier_t)(NSSet *);

+ (KeyModifier_t)muxModifierForKey:(NSString *)key class:(Class)cls
{ return (KeyModifier_t)[[muxModifiersByKeyByClass objectForKey:cls] objectForKey:key] ? : ^(NSSet *s) { return s; }; }

+ (void)setDirectMethodDependents:(NSSet *)deps forKey:(NSString *)key class:(Class)cls replacesSuperDependents:(BOOL)replaces
{
    SEL targetSel = MLHDependentKeySelectorForKey(key);
    IMP imp = NULL;
    if (replaces) {
        imp = imp_implementationWithBlock(^(id blockSelf) {
            return deps;
        });
    } else {
        imp = imp_implementationWithBlock(^(id blockSelf) {
            return [[[cls superclass] keyPathsForValuesAffectingValueForKey:key] setByAddingObjectsFromSet:deps];
        });
    }

    class_addMethod(object_getClass(cls), targetSel, imp, "@@:");
}

+ (void)setMuxMethodDependents:(NSSet *)deps forKey:(NSString *)key class:(Class)cls replacesSuperDependents:(BOOL)replaces
{
    if (!muxModifiersByKeyByClass) {
        muxModifiersByKeyByClass = [NSMapTable strongToStrongObjectsMapTable];
    }
    NSMapTable *modifiersByKey = [muxModifiersByKeyByClass objectForKey:cls];
    if (!modifiersByKey) {
        [muxModifiersByKeyByClass setObject:(modifiersByKey = [NSMapTable mapTableWithStrongToStrongObjects]) forKey:cls];
    }

    KeyModifier_t modifier = ^(NSSet *baseKeys) {
        if (replaces) {
            return deps ? : [NSSet set];
        } else {
            return [baseKeys setByAddingObjectsFromSet:deps];
        }
    };

    [modifiersByKey setObject:[modifier copy] forKey:key];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{ return MLHOverrideKeyPathsForValueAffectingKey(self, _definingClass, NO, key, [self muxModifierForKey:key class:_definingClass]); }

@end

@implementation KPADSubOne
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{ return MLHOverrideKeyPathsForValueAffectingKey(self, _definingClass, NO, key, [self muxModifierForKey:key class:_definingClass]); }
@end

@implementation KPADSubTwo
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{ return MLHOverrideKeyPathsForValueAffectingKey(self, _definingClass, NO, key, [self muxModifierForKey:key class:_definingClass]); }
@end
