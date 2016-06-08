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
#import "SCGeometry.h"

@interface SpatialConnectAutoConfigTest : XCTestCase {
  SpatialConnect *sc;
}
@end

@implementation SpatialConnectAutoConfigTest

- (void)setUp {
  [super setUp];
  sc = [SpatialConnectHelper loadRemoteConfig];
}

- (void)tearDown {
  [super tearDown];
  [sc stopAllServices];
}

- (void)testAutoConfig {
  XCTestExpectation *expect = [self expectationWithDescription:@"AutoConf"];
  NSMutableArray *arr = [NSMutableArray new];
  RACMulticastConnection *s = [sc.dataService storeEvents];
  RACSignal *starts = [[s.signal filter:^BOOL(SCStoreStatusEvent *e) {
    if (e.status == SC_DATASTORE_EVT_STARTED) {
      return YES;
    }
    return NO;
  }] take:1];
  [starts subscribeNext:^(SCStoreStatusEvent *e) {
    RACSignal *result = [sc.dataService queryAllStores:nil];
    [[result take:5] subscribeNext:^(SCSpatialFeature *geom) {
      [arr addObject:geom];
    } error:^(NSError *error) {
      XCTFail(@"Error Querying stores");
    } completed:^(void) {
      XCTAssert(arr.count > 0, @"Pass");
      [expect fulfill];
    }];
  }];
  [s connect];
  [sc startAllServices];
  [self waitForExpectationsWithTimeout:12.0 handler:nil];
}

@end
