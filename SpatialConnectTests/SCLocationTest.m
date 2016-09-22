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
  sc = nil;
}

- (void)testLocation {
  XCTestExpectation *expect = [self expectationWithDescription:@"Location"];
  SCPoint *p =
      [[SCPoint alloc] initWithCoordinateArray:@[ @(-32), @(arc4random()) ]];
  [[[[[sc serviceStarted:[SCBackendService serviceId]]
      flattenMap:^RACStream *(id value) {
        [sc.authService authenticate:@"admin@something.com" password:@"admin"];
        return sc.backendService.configReceived;
      }] filter:^BOOL(NSNumber *cr) {
    return [cr boolValue];
  }] take:1] subscribeNext:^(id x) {
    SCLocationStore *lStore = sc.dataService.locationStore;
    [p.properties setObject:@([[NSDate new] timeIntervalSince1970])
                     forKey:@"timestamp"];
    [p.properties setObject:@"GPS" forKey:@"accuracy"];
    [[lStore create:p] subscribeCompleted:^{
      [expect fulfill];
    }];
  }];
  [sc startAllServices];
  [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

@end
