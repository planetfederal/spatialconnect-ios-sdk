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
#import "SpatialConnect.h"
#import "SpatialConnectHelper.h"
#import "SCGeopackageHelper.h"
#import "GeopackageStore.h"
#import "SCPoint.h"

@interface SCGeopackageCreateTest : XCTestCase
@property(nonatomic) SpatialConnect *sc;
@end

@implementation SCGeopackageCreateTest
@synthesize sc;
- (void)setUp {
  [super setUp];
  self.sc = [SpatialConnectHelper loadConfigAndStartServices];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testGpkgFeatureCreate {
  XCTestExpectation *expect = [self expectationWithDescription:@"Create"];
  [[[SCGeopackageHelper loadGPKGDataStore:self.sc]
      flattenMap:^RACStream *(GeopackageStore *ds) {
        SCPoint *p =
            [[SCPoint alloc] initWithCoordinateArray:@[ @(32.3), @(43.1) ]];
        return [ds createFeature:p];
      }] subscribeError:^(NSError *error) {
    NSLog(@"%@", error.description);
    XCTAssert(NO, @"Error creating point");
    [expect fulfill];
  } completed:^{
    XCTAssert(YES, @"Point created");
    [expect fulfill];
  }];
  [self.sc startAllServices];
  [self waitForExpectationsWithTimeout:120.0 handler:nil];
}

@end
