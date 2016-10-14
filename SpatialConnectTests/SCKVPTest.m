/**
 * Copyright 2016 Boundless http://boundlessgeo.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License
 */

#import "SCTestString.h"
#import "SpatialConnectHelper.h"
#import <XCTest/XCTest.h>

@interface SCKVPTest : XCTestCase
@property(nonatomic) SpatialConnect *sc;
@property(nonatomic) SCKVPStore *kvp;
@end

@implementation SCKVPTest

@synthesize sc, kvp;

- (void)setUp {
  [super setUp];
  self.sc = [SpatialConnectHelper loadConfigAndStartServices];
  self.kvp = self.sc.kvpService.kvpStore;
}

- (void)tearDown {
  [super tearDown];
  [self.sc stopAllServices];
}

- (void)testFloat {
  [self.kvp putValue:@(67.3f) forKey:@"floatTest"];
  NSNumber *obj = (NSNumber *)[self.kvp valueForKey:@"floatTest"];
  XCTAssertEqual(obj.floatValue, 67.3f);
}

- (void)testDictionary {
  NSString *gjDataPath =
      [SpatialConnectHelper filePathFromSelfBundle:@"feature.json"];
  NSData *gjData = [NSData dataWithContentsOfFile:gjDataPath];
  NSDictionary *dict = @{
    @"one" : @(1),
    @"two" : @{@"check" : @"it"},
    @"three" : @"foo2",
    @"four" : @{@"five" : @"fiverrr"},
    @"five" : gjData
  };
  [self.kvp putDictionary:dict forKey:@"dictTest"];
  NSDictionary *d = [self.kvp dictionaryForKey:@"dictTest"];
  XCTAssertNotNil(d);
  XCTAssertEqual(1, [d[@"one"] intValue]);
  XCTAssert([@"it" isEqualToString:d[@"two"][@"check"]]);
  XCTAssert([@"foo2" isEqualToString:d[@"three"]]);
  XCTAssert([@"fiverrr" isEqualToString:d[@"four"][@"five"]]);
  NSData *data = d[@"five"];
  XCTAssert([data isEqualToData:gjData]);
}

- (void)testData {
  NSString *fp = [SpatialConnectHelper filePathFromSelfBundle:@"simple.json"];
  NSData *fileData = [NSData dataWithContentsOfFile:fp];
  [self.kvp putValue:fileData forKey:@"datatest"];
  NSData *obj = (NSData *)[self.kvp valueForKey:@"datatest"];
  NSString *str = [[NSString alloc] initWithBytes:[fileData bytes]
                                           length:fileData.length
                                         encoding:NSUTF8StringEncoding];
  NSString *str2 = [[NSString alloc] initWithBytes:[obj bytes]
                                            length:obj.length
                                          encoding:NSUTF8StringEncoding];
  XCTAssertEqual(obj.length, fileData.length);
  XCTAssertTrue([fileData isEqualToData:obj]);
  XCTAssertTrue([str isEqualToString:str2]);
}

- (void)testString {
  NSString *str = [SCTestString randomStringWithLength:1000];
  [self.kvp putValue:str forKey:@"stringTest"];
  NSString *obj = (NSString *)[self.kvp valueForKey:@"stringTest"];
  XCTAssertTrue([obj isEqualToString:str]);
}

- (void)testBoolean {
  [self.kvp putValue:[NSNumber numberWithBool:YES] forKey:@"booltest"];
  NSNumber *obj = (NSNumber *)[self.kvp valueForKey:@"booltest"];
  XCTAssertTrue(obj.boolValue);
}

- (void)testInt {
  [self.kvp putValue:@(67) forKey:@"intTest"];
  NSObject *obj = [self.kvp valueForKey:@"intTest"];
  XCTAssertNotNil(obj);
}

@end
