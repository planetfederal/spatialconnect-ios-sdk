/*****************************************************************************
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 ******************************************************************************/

#import <XCTest/XCTest.h>
#import "SCFilterBetween.h"
#import "SCFilterGreaterThan.h"
#import "SCFilterGreaterThanEqual.h"
#import "SCFilterIn.h"
#import "SCFilterLessThan.h"
#import "SCFilterLessThanEqual.h"
#import "SCFilterLike.h"
#import "SCFilterNotBetween.h"
#import "SCFilterNotEqual.h"
#import "SCFilterNotIn.h"
#import "SCFilterNotLike.h"
#import "SCGeoFilterContains.h"
#import "SCGeoFilterDisjoint.h"
#import "SCFilterEqual.h"

@interface FilterTests : XCTestCase

@end

@implementation FilterTests

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testFilterBetween {
  SCFilterBetween *filter =
      [[SCFilterBetween alloc] initWithUpper:@1.0 lower:@0.0 andKeyPath:nil];
  XCTAssertTrue([filter compareLHS:@0.5], @"0.5 is between 1 and 0");
  XCTAssertFalse([filter compareLHS:@-1], @"-1 is not between 1 and 0");
  NSNumber *n = [NSNumber numberWithUnsignedInt:arc4random()];
  NSNumber *n2 = [NSNumber numberWithUnsignedInt:arc4random()];
  SCFilterBetween *filter2;
  if ([n compare:n2] == NSOrderedAscending) {
    filter2 = [[SCFilterBetween alloc] initWithUpper:n2 lower:n andKeyPath:nil];
  } else {
    filter2 = [[SCFilterBetween alloc] initWithUpper:n lower:n2 andKeyPath:nil];
  }

  NSNumber *upper = (NSNumber *)filter2.upper;
  NSNumber *lower = (NSNumber *)filter2.lower;
  float mid = (upper.floatValue + lower.floatValue) / 2.0f;
  NSNumber *v = [NSNumber numberWithFloat:mid];
  XCTAssertTrue([filter2 compareLHS:v],
                @"Check that midpoint float returns the proper value Upper:%@ "
                @"Lower:%@ Check:%@",
                upper, lower, v);
}

- (void)testFilterNotBetween {
  SCFilterNotBetween *filter =
      [[SCFilterNotBetween alloc] initWithUpper:@(1) lower:@(0) andKeyPath:nil];
  XCTAssertFalse([filter compareLHS:@(0.5)], @"0.5 is between 1 and 0");
  XCTAssertTrue([filter compareLHS:@(-1)], @"-1 is not between 1 and 0");
  XCTAssertTrue([filter compareLHS:@(2)]);
  NSNumber *n = [NSNumber numberWithInt:arc4random()];
  NSNumber *n2 = [NSNumber numberWithInt:arc4random()];
  SCFilterNotBetween *filter2;
  if ([n compare:n2] == NSOrderedDescending) {
    filter2 =
        [[SCFilterNotBetween alloc] initWithUpper:n lower:n2 andKeyPath:nil];
  } else {
    filter2 =
        [[SCFilterNotBetween alloc] initWithUpper:n2 lower:n andKeyPath:nil];
  }
  NSNumber *upper = (NSNumber *)filter2.upper;
  NSNumber *lower = (NSNumber *)filter2.lower;
  float mid = (upper.floatValue + lower.floatValue) / 2.0f;
  NSNumber *v = [NSNumber numberWithFloat:mid];
  XCTAssertFalse([filter2 compareLHS:v],
                 @"Check that midpoint float returns the proper value Upper:%@ "
                 @"Lower:%@ Check:%@",
                 upper, lower, v);
}

- (void)testFilterGreaterThan {
  NSString *vStr = @"foo";
  SCFilterGreaterThan *filterStr =
      [[SCFilterGreaterThan alloc] initWithValue:vStr];
  NSNumber *vNum = @(23);
  SCFilterGreaterThan *filterNum =
      [[SCFilterGreaterThan alloc] initWithValue:vNum];
  NSString *str = @"foo2";
  NSString *str2 = @"hoo";
  NSNumber *n1 = @(20);
  NSNumber *n2 = @(25);
  XCTAssertTrue([filterStr compareLHS:str], @"%@ comes before %@", vStr, str);
  XCTAssertTrue([filterStr compareLHS:str2], @"%@ comes after %@", vStr, str2);
  XCTAssertFalse([filterNum compareLHS:n1], @"%@ is greater than %@", vNum, n1);
  XCTAssertTrue([filterNum compareLHS:n2], @"%@ is less than %@", vNum, n2);
}

- (void)testFilterGreaterThanEqual {
  NSString *vStr = @"foo";
  SCFilterGreaterThanEqual *filterStr =
      [[SCFilterGreaterThanEqual alloc] initWithValue:vStr];
  NSNumber *vNum = @(23);
  SCFilterGreaterThanEqual *filterNum =
      [[SCFilterGreaterThanEqual alloc] initWithValue:vNum];
  NSString *str = @"foo2";
  NSString *str2 = @"hoo";
  NSString *str3 = [vStr copy];
  NSNumber *n1 = @(20);
  NSNumber *n2 = @(25);
  NSNumber *n3 = [vNum copy];
  XCTAssertTrue([filterStr compareLHS:str], @"%@ comes before %@", vStr, str);
  XCTAssertTrue([filterStr compareLHS:str2], @"%@ comes after %@", vStr, str2);
  XCTAssertTrue([filterStr compareLHS:str3], @"%@ should Equal %@", vStr, str3);
  XCTAssertFalse([filterNum compareLHS:n1], @"%@ is greater than %@", vNum, n1);
  XCTAssertTrue([filterNum compareLHS:n2], @"%@ is less than %@", vNum, n2);
  XCTAssertTrue([filterNum compareLHS:n3], @"%@ is equal to %@", vNum, n3);
}

- (void)testFilterIn {
  SCFilterIn *filter =
      [[SCFilterIn alloc] initWithArray:@[ @"a", @(23), @"b", @(47) ]];
  XCTAssertTrue([filter compareLHS:@"a"]);
  XCTAssertFalse([filter compareLHS:@"ab"]);
  XCTAssertTrue([filter compareLHS:@(47)]);
  XCTAssertFalse([filter compareLHS:@(49)]);
}

- (void)testFilterNotIn {
  SCFilterNotIn *filter =
      [[SCFilterNotIn alloc] initWithArray:@[ @"a", @(23), @"b", @(47) ]];
  XCTAssertFalse([filter compareLHS:@"a"]);
  XCTAssertTrue([filter compareLHS:@"ab"]);
  XCTAssertFalse([filter compareLHS:@(47)]);
  XCTAssertTrue([filter compareLHS:@(49)]);
}

- (void)testFilterLessThan {
  NSString *vStr = @"foo";
  SCFilterLessThan *filterStr = [[SCFilterLessThan alloc] initWithValue:vStr];
  u_int32_t a = arc4random();
  NSNumber *vNum = [NSNumber numberWithUnsignedInt:a];
  SCFilterLessThan *filterNum = [[SCFilterLessThan alloc] initWithValue:vNum];
  NSString *booStr = @"boo";
  NSString *hooStr = @"hoo";
  u_int32_t l = arc4random();
  NSNumber *low = [NSNumber numberWithLong:(vNum.integerValue - l)];
  u_int32_t h = arc4random();
  NSNumber *hi = [NSNumber numberWithLong:(vNum.integerValue + h)];
  XCTAssertTrue([filterStr compareLHS:booStr], @"%@ comes before %@", vStr,
                booStr);
  XCTAssertFalse([filterStr compareLHS:hooStr], @"%@ comes after %@", vStr,
                 hooStr);
  XCTAssertTrue([filterNum compareLHS:low], @"%@ is less than %@", low, vNum);
  XCTAssertFalse([filterNum compareLHS:hi], @"%@ is greater than %@", hi, vNum);
}

- (void)testFilterLessThanEqual {
  NSString *vStr = @"foo";
  SCFilterGreaterThanEqual *filterStr =
      [[SCFilterGreaterThanEqual alloc] initWithValue:vStr];
  NSNumber *vNum = @(23);
  SCFilterGreaterThanEqual *filterNum =
      [[SCFilterGreaterThanEqual alloc] initWithValue:vNum];
  NSString *str = @"foo2";
  NSString *str2 = @"hoo";
  NSString *str3 = [vStr copy];
  NSNumber *n1 = @(20);
  NSNumber *n2 = @(25);
  NSNumber *n3 = [vNum copy];
  XCTAssertTrue([filterStr compareLHS:str], @"%@ comes before %@", vStr, str);
  XCTAssertTrue([filterStr compareLHS:str2], @"%@ comes after %@", vStr, str2);
  XCTAssertTrue([filterStr compareLHS:str3], @"%@ should Equal %@", vStr, str3);
  XCTAssertFalse([filterNum compareLHS:n1], @"%@ is greater than %@", vNum, n1);
  XCTAssertTrue([filterNum compareLHS:n2], @"%@ is less than %@", vNum, n2);
  XCTAssertTrue([filterNum compareLHS:n3], @"%@ is equal to %@", vNum, n3);
}

- (void)testFilterLike {
  NSString *needle1 = @"foo";
  NSString *needle2 = @"bar";
  NSString *haystack = @"foobar";
  SCFilterLike *filter = [[SCFilterLike alloc] initWithValue:haystack];
  XCTAssertTrue([filter compareLHS:needle1], @"%@ is the prefix of %@", needle1,
                haystack);
  XCTAssertTrue([filter compareLHS:needle2], @"%@ is the suffix of %@", needle2,
                haystack);
  NSString *uuidNeedle = [[NSUUID UUID] UUIDString];
  NSString *uuidHaystack = [[NSUUID UUID] UUIDString];
  SCFilterLike *uFilter = [[SCFilterLike alloc] initWithValue:uuidHaystack];
  XCTAssertFalse([uFilter compareLHS:uuidNeedle], @"%@ is not substring in %@",
                 uuidNeedle, uuidHaystack);
  XCTAssertThrows([uFilter compareLHS:@(56)],
                  @"Comparing separate types should fail");
}

- (void)testFilterEqual {
  NSString *a = [[NSUUID UUID] UUIDString];
  NSString *b = [a copy];
  SCFilterEqual *filter = [[SCFilterEqual alloc] initWithValue:a];
  XCTAssertTrue([filter compareLHS:b]);
  XCTAssertFalse([filter compareLHS:@(555)]);
  XCTAssertFalse([filter compareLHS:@"afsdf"]);
}

- (void)testFilterNotEqual {
  NSString *a = [[NSUUID UUID] UUIDString];
  NSString *b = [a copy];
  SCFilterNotEqual *filter = [[SCFilterNotEqual alloc] initWithValue:a];
  XCTAssertFalse([filter compareLHS:b]);
  XCTAssertTrue([filter compareLHS:@(555)]);
  XCTAssertTrue([filter compareLHS:@"afsdf"]);
}

- (void)testFilterNotLike {
  NSString *needle1 = @"foo";
  NSString *needle2 = @"bar";
  NSString *haystack = @"foobar";
  SCFilterNotLike *filter = [[SCFilterNotLike alloc] initWithValue:haystack];
  XCTAssertFalse([filter compareLHS:needle1], @"%@ is the prefix of %@",
                 needle1, haystack);
  XCTAssertFalse([filter compareLHS:needle2], @"%@ is the suffix of %@",
                 needle2, haystack);
  NSString *uuidNeedle = [[NSUUID UUID] UUIDString];
  NSString *uuidHaystack = [[NSUUID UUID] UUIDString];
  SCFilterNotLike *uFilter =
      [[SCFilterNotLike alloc] initWithValue:uuidHaystack];
  XCTAssertTrue([uFilter compareLHS:uuidNeedle], @"%@ is not substring in %@",
                uuidNeedle, uuidHaystack);
  XCTAssertThrows([uFilter compareLHS:@(56)],
                  @"Comparing separate types should fail");
}

@end
