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
#import "SCPoint.h"
#import "Scmessage.pbobjc.h"
#import "SpatialConnect.h"
#import "SpatialConnectHelper.h"
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface SCLocationTest : XCTestCase {
  SpatialConnect *sc;
}
@end

@implementation SCLocationTest

- (void)setUp {
  [super setUp];
  sc = [SpatialConnectHelper loadRemoteConfig];
}

- (void)tearDown {
  [super tearDown];
  [sc stopAllServices];
}

- (void)testLocation {
  XCTestExpectation *expect = [self expectationWithDescription:@"Location"];
  [sc startAllServices];
  SCPoint *p = [[SCPoint alloc] initWithCoordinateArray:@[ @(-32), @(32) ]];
  SCLocationStore *lStore = sc.dataService.locationStore;
  [p.properties setObject:@([[NSDate new] timeIntervalSince1970])
                   forKey:@"timestamp"];
  [p.properties setObject:@"GPS" forKey:@"accuracy"];
  [[lStore create:p] subscribeCompleted:^{
    [expect fulfill];
  }];
  [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

@end
