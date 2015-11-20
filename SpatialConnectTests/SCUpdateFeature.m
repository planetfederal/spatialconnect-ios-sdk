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

@interface SCUpdateFeature : XCTestCase
@property SpatialConnect *sc;
@end

@implementation SCUpdateFeature

- (void)setUp {
  [super setUp];
  _sc = [SpatialConnectHelper loadConfig];
}

- (void)tearDown {
  [super tearDown];
  _sc = nil;
}

- (void)testUpdateFeature {
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"update feature"];
  SCPoint *pt = [[SCPoint alloc] initWithCoordinateArray:@[ @-90, @38, @111 ]];
  [self.sc.manager.dataService.allStoresStartedSignal subscribeNext:^(id x) {
    NSArray *spatialStores = [self.sc.manager.dataService
        storesByProtocol:@protocol(SCSpatialStore)];
    XCTAssert(spatialStores.count, "Successfully fetched Spatial Stores");
    if (spatialStores.count) {

      id<SCSpatialStore> store = [spatialStores
          objectAtIndex:arc4random_uniform((int)spatialStores.count)];
      [[store create:pt] subscribeCompleted:^{
        [pt.properties
            setValue:[NSNumber numberWithInteger:(int)arc4random_uniform(1000)]
              forKey:@"randomNumber"];
        [[store update:pt] subscribeCompleted:^{
          XCTAssertTrue(YES, "Feature Updated Successfully");
          [expectation fulfill];
        }];
      }];
    } else {
      XCTAssert(NO, "There are no stores registered");
    }
  }];
  [self.sc startAllServices];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
