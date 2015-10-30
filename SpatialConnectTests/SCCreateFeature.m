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

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "SpatialConnectHelper.h"
#import "SCPoint.h"
#import "SCSpatialStore.h"

@interface SCCreateFeature : XCTestCase
@property SpatialConnect *sc;
@end

@implementation SCCreateFeature

- (void)setUp {
  [super setUp];
  _sc = [SpatialConnectHelper loadConfigAndStartServices];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each
  // test method in the class.
  [super tearDown];
  _sc = nil;
}

- (void)testPointCreate {
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"create feature"];
  SCPoint *pt = [[SCPoint alloc] initWithCoordinateArray:@[ @-90, @38, @111 ]];
  NSArray *spatialStores =
      [self.sc.manager.dataService storesByProtocol:@protocol(SCSpatialStore)];
  XCTAssert(spatialStores.count, "Successfully fetched Spatial Stores");
  if (spatialStores.count) {
    id<SCSpatialStore> store = (id<SCSpatialStore>)[spatialStores firstObject];
    [[store createFeature:pt] subscribeError:^(NSError *error) {
      XCTAssertTrue(NO, @"Error:%@", [error description]);
      [expectation fulfill];
    } completed:^{
      XCTAssertTrue(YES);
      [expectation fulfill];
    }];
  }
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
