//
//  MLHDependentKeyPathsStaticTests.m
//  MyLilHelpers
//
//  Created by Jonathon Mah on 2014-03-01.
//  Copyright (c) 2014 Jonathon Mah. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MyLilHelpers.h"


@interface MLHDependentKeyPathsStaticTests : XCTestCase

@end


@interface KPASBase : NSObject
@property (nonatomic) id foo;
@property (nonatomic, readonly) id fooDerivative;
@property (nonatomic, readonly) id specialDerivative;
@property (nonatomic, readonly) id affectedOwnDerivative;
@end


@interface KPASSub : KPASBase
@end


@interface KPASSub2 : KPASSub
@end


@implementation KPASBase

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    BOOL affectOwnClass = [key isEqual:@"affectedOwnDerivative"];
    return MLHKeyPathsForValueAffectingKeyOverride(self, _definingClass, affectOwnClass, key, ^NSSet *(NSSet *superKeyPaths) {
        if ([key hasSuffix:@"Derivative"]) {
            return [superKeyPaths setByAddingObject:[key substringToIndex:(key.length - @"Derivative".length)]];
        } else {
            return superKeyPaths;
        }
    });
}

+ (NSSet *)keyPathsForValuesAffectingSpecialDerivative
{ return [NSSet setWithObjects:@"foo", @"notSpecial", nil]; }

+ (NSSet *)keyPathsForValuesAffectingAffectedOwnDerivative
{ return [NSSet setWithObject:@"baz"]; }

@end


@implementation KPASSub

+ (NSSet *)keyPathsForValuesAffectingFooDerivative
{ return [MLHSuperclassKeyPathsAffecting(_definingClass, @"fooDerivative") setByAddingObject:@"bar"]; }

@end


@implementation KPASSub2

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    // "Derivative" keys affect something completely different now...
    return MLHKeyPathsForValueAffectingKeyOverride(self, _definingClass, NO, key, ^NSSet *(NSSet *superKeyPaths) {
        if ([key hasSuffix:@"Derivative"]) {
            return [NSSet setWithObject:[[key substringToIndex:(key.length - @"Derivative".length)] stringByAppendingString:@"2"]];
        } else {
            return superKeyPaths;
        }
    });
}

+ (NSSet *)keyPathsForValuesAffectingSpecialDerivative
{ return [NSSet setWithObject:@"notSpecial"]; }

@end


@implementation MLHDependentKeyPathsStaticTests

- (void)testBase
{
    XCTAssertEqualObjects([KPASBase keyPathsForValuesAffectingValueForKey:@"foo"], [NSSet set]);
    XCTAssertEqualObjects([KPASBase keyPathsForValuesAffectingValueForKey:@"fooDerivative"], [NSSet setWithObject:@"foo"]);
    XCTAssertEqualObjects([KPASBase keyPathsForValuesAffectingValueForKey:@"specialDerivative"], ([NSSet setWithObjects:@"foo", @"notSpecial", nil]));
    XCTAssertEqualObjects([KPASBase keyPathsForValuesAffectingValueForKey:@"affectedOwnDerivative"], ([NSSet setWithObjects:@"baz", @"affectedOwn", nil]));
}

- (void)testSub
{
    XCTAssertEqualObjects([KPASSub keyPathsForValuesAffectingValueForKey:@"fooDerivative"], ([NSSet setWithObjects:@"foo", @"bar", nil]));
    XCTAssertEqualObjects([KPASSub keyPathsForValuesAffectingValueForKey:@"specialDerivative"], ([NSSet setWithObjects:@"foo", @"notSpecial", nil]));
    XCTAssertEqualObjects([KPASSub keyPathsForValuesAffectingValueForKey:@"affectedOwnDerivative"], ([NSSet setWithObjects:@"baz", @"affectedOwn", nil]));
}

- (void)testSub2
{
    XCTAssertEqualObjects([KPASSub2 keyPathsForValuesAffectingValueForKey:@"fooDerivative"], [NSSet setWithObject:@"foo2"]);
    XCTAssertEqualObjects([KPASSub2 keyPathsForValuesAffectingValueForKey:@"specialDerivative"], [NSSet setWithObject:@"notSpecial"]);
    XCTAssertEqualObjects([KPASSub2 keyPathsForValuesAffectingValueForKey:@"affectedOwnDerivative"], [NSSet setWithObject:@"affectedOwn2"]);
}

@end
