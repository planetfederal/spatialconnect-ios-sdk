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

@interface SCDeleteFeature : XCTestCase
@property SpatialConnect *sc;
@end

@implementation SCDeleteFeature

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

- (void)testDeleteFeature {
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"create feature"];
  SCPoint *pt = [[SCPoint alloc] initWithCoordinateArray:@[ @-90, @38, @111 ]];
  NSArray *spatialStores =
      [self.sc.manager.dataService storesByProtocol:@protocol(SCSpatialStore)];
  if (spatialStores.count == 0) {
    XCTAssert(spatialStores.count, "Successfully fetched Spatial Stores");
  }
  if (spatialStores.count) {
    id<SCSpatialStore> store = (id<SCSpatialStore>)[spatialStores firstObject];

    RACSignal *create = [store create:pt];
    [create subscribeError:^(NSError *error) {
      XCTAssertTrue(NO, @"Error deleting feature");
    } completed:^{
      [[store delete:pt.key] subscribeError:^(NSError *error) {
        NSLog(@"%@", error.description);
        [expectation fulfill];
      } completed:^{
        XCTAssertTrue(YES, "Feature Deleted Successfully");
        [expectation fulfill];
      }];
    }];

  } else {
    XCTAssert(NO, "There are no stores registered");
  }
  [self waitForExpectationsWithTimeout:15.0 handler:nil];
}

@end
