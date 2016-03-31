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

#import "GeopackageStore.h"
#import "SCGeopackageHelper.h"
#import "SCTestString.h"
#import "SpatialConnect.h"
#import "SpatialConnectHelper.h"
#import <XCTest/XCTest.h>

@interface SCGeopackageUpdateTest : XCTestCase
@property(nonatomic) SpatialConnect *sc;
@end

@implementation SCGeopackageUpdateTest

@synthesize sc;

- (void)setUp {
  [super setUp];
  self.sc = [SpatialConnectHelper loadConfig];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testGpkgFeatureUpdate {
  XCTestExpectation *expect = [self expectationWithDescription:@"Update"];

  [[SCGeopackageHelper loadGPKGDataStore:self.sc]
      subscribeNext:^(GeopackageStore *ds) {
        RACSignal *query = [[ds query:nil] take:1];
        RACSignal *complete = [[query materialize] filter:^BOOL(RACEvent *evt) {
          return RACEventTypeCompleted == evt.eventType;
        }];
        [[[query combineLatestWith:complete] flattenMap:^RACStream *(RACTuple *t) {
          SCSpatialFeature *f = (SCSpatialFeature*)t.first;
          NSString *key = [[f.properties allKeys] objectAtIndex:0];
          [f.properties setObject:[SCTestString randomStringWithLength:200]
                           forKey:key];
          return [ds update:f];
        }] subscribeError:^(NSError *error) {
          XCTAssert(NO, @"Error loading GPGK");
          [expect fulfill];
        }
            completed:^{
              XCTAssert(YES, @"Update successfully");
              [expect fulfill];
            }];
      }];

  [sc.manager startAllServices];
  [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

@end
