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

#import "SCFormFeature.h"
#import "SCGeopackageHelper.h"
#import "SCPoint.h"
#import "SpatialConnectHelper.h"
#import <XCTest/XCTest.h>

@interface SCFormTest : XCTestCase
@property SpatialConnect *sc;
@end

@implementation SCFormTest

@synthesize sc;

- (void)setUp {
  [super setUp];
  self.sc = [SpatialConnectHelper loadRemoteConfig];
}

- (void)tearDown {
  [super tearDown];
  [self.sc stopAllServices];
  self.sc = nil;
}

- (void)testFormToDict {
  XCTestExpectation *expect = [self expectationWithDescription:@"Form ToDict"];
  RACSignal *bsStarted = [self.sc serviceStarted:[SCBackendService serviceId]];
  RACSignal *asAuthed =
      [[self.sc.authService loginStatus] filter:^BOOL(NSNumber *n) {
        return [n integerValue] == SCAUTH_AUTHENTICATED;
      }];

  [[[[bsStarted flattenMap:^RACStream *(id value) {
    [self.sc.authService authenticate:@"admin@something.com" password:@"admin"];
    return asAuthed;
  }] flattenMap:^RACStream *(id value) {
    return [self.sc.dataService.formStore.hasForms filter:^BOOL(NSNumber *o) {
      return [o boolValue];
    }];
  }] take:1] subscribeNext:^(id x) {
    NSArray *a = [self.sc.dataService.formStore formsDictionaryArray];

    XCTAssertNotNil(a);
    XCTAssertGreaterThan(a.count, 0);
    [a enumerateObjectsUsingBlock:^(NSDictionary *d, NSUInteger idx,
                                    BOOL *_Nonnull stop) {
      XCTAssertNotNil(d[@"form_key"]);
      XCTAssertNotNil(d[@"form_label"]);
      XCTAssertNotNil(d[@"version"]);
      XCTAssertNotNil(d[@"fields"]);
    }];

    [expect fulfill];
  }];
  [self.sc startAllServices];
  [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testFormSubmission {
  XCTestExpectation *expect = [self expectationWithDescription:@"Form Submit"];

  [[[[[sc serviceStarted:[SCBackendService serviceId]]
      flattenMap:^RACStream *(id value) {
        [sc.authService authenticate:@"admin@something.com" password:@"admin"];
        return [[sc.backendService configReceived] filter:^BOOL(NSNumber *n) {
          return [n boolValue] == YES;
        }];
      }] take:1] flattenMap:^RACStream *(id value) {
    SCSpatialFeature *f = [[SCSpatialFeature alloc] init];
    f.layerId = @"baseball_team";
    f.storeId = @"FORM_STORE";
    [f.properties setObject:@"Baltimore" forKey:@"team"];
    [f.properties setObject:[[NSDate date] description] forKey:@"why"];
    return [self.sc.dataService.formStore create:f];
  }] subscribeNext:^(id x) {
    [expect fulfill];
  }
      error:^(NSError *error) {
        [expect fulfill];
      }
      completed:^{
        [expect fulfill];
      }];

  [self.sc startAllServices];
  [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

@end
