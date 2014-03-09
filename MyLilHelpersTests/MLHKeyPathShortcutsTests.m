//
//  MLHKeyPathShortcutsTests.m
//  MyLilHelpers
//
//  Created by Jonathon Mah on 2014-03-08.
//  Copyright (c) 2014 Jonathon Mah. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSObject+MLHKeyPathShortcuts.h"


@interface MLHKeyPathShortcutsTests : XCTestCase

@property (nonatomic, copy) NSDictionary *lastKVOChange;

@end


@interface MLHKPSObject : NSObject
@property (nonatomic) NSInteger num;
@property (nonatomic, readonly) NSInteger numPlusDefaults;
@end

static NSString *const MLHKPSObjectNumUserDefaultsKey = @"MLHKPSObjectNum";

static char testKVOContext;


@implementation MLHKeyPathShortcutsTests

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &testKVOContext) {
        self.lastKVOChange = change;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)tearDown
{
    [super tearDown];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MLHKPSObjectNumUserDefaultsKey];
}


#pragma mark - Tests

- (void)testGettingClassesContainer
{
    NSObject *anyObject = [NSObject new];
    XCTAssertNotNil(anyObject.$classes);
    XCTAssertNotNil([anyObject valueForKey:@"$classes"]);
    XCTAssertEqual([anyObject valueForKeyPath:@"$classes.NSNull.null"], [NSNull null]);
}

- (void)testGettingDefaults
{
    NSObject *anyObject = [NSObject new];
    XCTAssertEqual([anyObject valueForKey:@"$defaults"], [NSUserDefaults standardUserDefaults]);
    XCTAssertEqual([anyObject valueForKeyPath:@"$classes.NSUserDefaults.standardUserDefaults"], [anyObject valueForKey:@"$defaults"]);
}

- (void)testGettingApp
{
    NSObject *anyObject = [NSObject new];
#if __has_include(<UIKit/UIApplication.h>)
    XCTAssertEqual([anyObject valueForKey:@"$app"], [UIApplication sharedApplication]);
#elif __has_include(<AppKit/NSApplication.h>)
    XCTAssertEqual([anyObject valueForKey:@"$app"], NSApp);
#endif
}


- (void)testObservingDefaults
{
    MLHKPSObject *obj = [MLHKPSObject new];
    [obj addObserver:self forKeyPath:@"numPlusDefaults" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:&testKVOContext];

    obj.num = 1;
    XCTAssertEqual(obj.numPlusDefaults, 1);
    XCTAssertEqualObjects(self.lastKVOChange[NSKeyValueChangeOldKey], @0);
    XCTAssertEqualObjects(self.lastKVOChange[NSKeyValueChangeNewKey], @1);

    obj.num = 2;
    XCTAssertEqual(obj.numPlusDefaults, 2);
    XCTAssertEqualObjects(self.lastKVOChange[NSKeyValueChangeOldKey], @1);
    XCTAssertEqualObjects(self.lastKVOChange[NSKeyValueChangeNewKey], @2);

    [[NSUserDefaults standardUserDefaults] setInteger:10 forKey:MLHKPSObjectNumUserDefaultsKey];
    XCTAssertEqual(obj.numPlusDefaults, 12);
    XCTAssertEqualObjects(self.lastKVOChange[NSKeyValueChangeOldKey], @2);
    XCTAssertEqualObjects(self.lastKVOChange[NSKeyValueChangeNewKey], @12);

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MLHKPSObjectNumUserDefaultsKey];
    XCTAssertEqual(obj.numPlusDefaults, 2);
    XCTAssertEqualObjects(self.lastKVOChange[NSKeyValueChangeOldKey], @12);
    XCTAssertEqualObjects(self.lastKVOChange[NSKeyValueChangeNewKey], @2);

    [obj removeObserver:self forKeyPath:@"numPlusDefaults" context:&testKVOContext];
}

@end


@implementation MLHKPSObject
+ (NSSet *)keyPathsForValuesAffectingNumPlusDefaults
{ return [NSSet setWithObjects:@"num", [@"$defaults." stringByAppendingString:MLHKPSObjectNumUserDefaultsKey], nil]; }
- (NSInteger)numPlusDefaults
{ return self.num + [[NSUserDefaults standardUserDefaults] integerForKey:MLHKPSObjectNumUserDefaultsKey]; }
@end
