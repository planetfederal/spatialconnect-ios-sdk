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

#import "SCDataStore.h"
#import "SCGeopackageGeometryExtensions.h"
#import "SCGeopackageHelper.h"
#import "SCStoreStatusEvent.h"
#import "SpatialConnect.h"
#import "SpatialConnectHelper.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <XCTest/XCTest.h>

@interface SCGeopackageLoadTest : XCTestCase
@property(nonatomic) SpatialConnect *sc;
@end

@implementation SCGeopackageLoadTest
@synthesize sc;

- (void)setUp {
  [super setUp];
  self.sc = [SpatialConnectHelper loadConfig];
}

- (void)tearDown {
  [super tearDown];
  [self.sc stopAllServices];
}

- (void)testGpkgDownload {
  XCTestExpectation *expect = [self expectationWithDescription:@"Download"];

  [[SCGeopackageHelper loadGPKGDataStore:self.sc]
      subscribeNext:^(SCDataStore *ds) {
        if (ds) {
          XCTAssertNotNil(ds.layerList, @"Layer list as array");
          XCTAssertNoThrow([sc stopAllServices]);
        } else {
          XCTAssert(NO, @"Store is nil");
        }
        [expect fulfill];
      }
      error:^(NSError *error) {
        XCTAssert(NO, @"Error retrieving store");
        [expect fulfill];
      }];

  [sc startAllServices];
  [self waitForExpectationsWithTimeout:12.0 handler:nil];
}

@end
