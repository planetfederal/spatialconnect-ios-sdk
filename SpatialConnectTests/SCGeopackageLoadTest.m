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
#import "SCStoreStatusEvent.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "SCGeopackageGeometryExtensions.h"
#import "SCGeopackageHelper.h"
#import "SCDataStore.h"

@interface SCGeopackageTest : XCTestCase
@property(nonatomic) SpatialConnect *sc;
@end

@implementation SCGeopackageTest
@synthesize sc;

- (void)setUp {
  [super setUp];
  self.sc = [SpatialConnectHelper loadConfig];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testGpkgDownload {
  XCTestExpectation *expect = [self expectationWithDescription:@"Download"];

  [[SCGeopackageHelper
      loadGPKGDataStore:self.sc] subscribeNext:^(SCDataStore *ds) {
    if (ds) {
      XCTAssertNotNil(ds.defaultLayerName, @"Layer Name shall be set");
      XCTAssertNotNil(ds.layerList, @"Layer list as array");
      XCTAssertNoThrow([sc.manager stopAllServices]);
    } else {
      XCTAssert(NO, @"Store is nil");
    }
    [expect fulfill];
  } error:^(NSError *error) {
    XCTAssert(NO, @"Error retrieving store");
    [expect fulfill];
  }];

  [sc.manager startAllServices];
  [self waitForExpectationsWithTimeout:120.0 handler:nil];
}

@end
