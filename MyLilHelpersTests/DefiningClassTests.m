//
//  DefiningClassTests.m
//  MyLilHelpersTests
//
//  Created by Jonathon Mah on 2014-02-23.
//  Copyright (c) 2014 Jonathon Mah. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MyLilHelpers.h"


@interface DefiningClassTests : XCTestCase

@end


@interface DefiningBase : NSObject
+ (Class)definedByBase;
- (Class)definedByBase;
- (Class)definedByBaseAndOverriddenBySubOne;
- (Class)definedByBaseAndOverriddenBySubTwoCategory;
@end

@interface DefiningSubOne : DefiningBase
@end

@interface DefiningSubTwo : DefiningSubOne
@end


@implementation DefiningClassTests

- (void)testDefiningClass
{
    DefiningBase *base = [DefiningBase new];
    XCTAssert([base class] == [DefiningBase class]);
    XCTAssert([[base class] definedByBase] == [DefiningBase class]);
    XCTAssert([base definedByBase] == [DefiningBase class]);
    XCTAssert([base definedByBaseAndOverriddenBySubOne] == [DefiningBase class]);
    XCTAssert([base definedByBaseAndOverriddenBySubTwoCategory] == [DefiningBase class]);

    DefiningBase *subOne = [DefiningSubOne new];
    XCTAssert([subOne class] == [DefiningSubOne class]);
    XCTAssert([[subOne class] definedByBase] == [DefiningBase class]);
    XCTAssert([subOne definedByBase] == [DefiningBase class]);
    XCTAssert([subOne definedByBaseAndOverriddenBySubOne] == [DefiningSubOne class]);
    XCTAssert([subOne definedByBaseAndOverriddenBySubTwoCategory] == [DefiningBase class]);

    DefiningBase *subTwo = [DefiningSubTwo new];
    XCTAssert([subTwo class] == [DefiningSubTwo class]);
    XCTAssert([[subTwo class] definedByBase] == [DefiningBase class]);
    XCTAssert([subTwo definedByBase] == [DefiningBase class]);
    XCTAssert([subTwo definedByBaseAndOverriddenBySubOne] == [DefiningSubOne class]);
    XCTAssert([subTwo definedByBaseAndOverriddenBySubTwoCategory] == [DefiningSubTwo class]);
}

@end


@implementation DefiningBase
+ (Class)definedByBase
{ return _definingClass; }

- (Class)definedByBase
{ return _definingClass; }

- (Class)definedByBaseAndOverriddenBySubOne
{ return _definingClass; }

- (Class)definedByBaseAndOverriddenBySubTwoCategory
{ return _definingClass; }
@end

@implementation DefiningSubOne
- (Class)definedByBaseAndOverriddenBySubOne
{ return _definingClass; }
@end

@implementation DefiningSubTwo
@end

@interface DefiningSubTwo (Category)
@end

@implementation DefiningSubTwo (Category)
- (Class)definedByBaseAndOverriddenBySubTwoCategory
{ return _definingClass; }
@end


// Context checking

#if 0 // This should result in a compiler error
static void fn(id self, SEL _cmd) {
    _definingClass;
}
#endif

#if 0 // This should result in a compiler error without ALLOW_DEFINING_CLASS_IN_ROOT_CLASSES=1
OBJC_ROOT_CLASS
@interface DefiningRoot
+ (Class)definedByRoot;
@end

@implementation DefiningRoot
+ (Class)definedByRoot
{ return _definingClass; }
@end
#endif
