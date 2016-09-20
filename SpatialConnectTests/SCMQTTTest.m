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

#import "JSONKit.h"
#import "SCNotification.h"
#import "SCPoint.h"
#import "Scmessage.pbobjc.h"
#import "SpatialConnect.h"
#import "SpatialConnectHelper.h"
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface SCMQTTTest : XCTestCase {
  SpatialConnect *sc;
}
@end

@implementation SCMQTTTest

- (void)setUp {
  [super setUp];
  sc = [SpatialConnectHelper loadRemoteConfig];
}

- (void)tearDown {
  [super tearDown];
  [sc stopAllServices];
  sc = nil;
}

- (void)testMQTT {
  XCTestExpectation *expect = [self expectationWithDescription:@"MQTT"];

  [[[[sc serviceStarted:[SCBackendService serviceId]]
      flattenMap:^RACStream *(id value) {
        [sc.authService authenticate:@"admin@something.com" password:@"admin"];
        return [[sc.backendService configReceived] filter:^BOOL(NSNumber *n) {
          return [n boolValue] == YES;
        }];
      }] take:1] subscribeNext:^(id x) {
    SCMessage *msg = [[SCMessage alloc] init];
    msg.action = 456;
    [[sc.backendService publishReplyTo:msg onTopic:@"/ping"]
        subscribeNext:^(id x) {
          [expect fulfill];
        }
        error:^(NSError *error) {
          [expect fulfill];
        }
        completed:^{
          [expect fulfill];
        }];
  }];

  [sc startAllServices];
  [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testTrackingNotification {
  XCTestExpectation *expect = [self expectationWithDescription:@"MQTT"];
  [[sc serviceStarted:[SCBackendService serviceId]] subscribeNext:^(id x) {
    SCMessage *msg = [[SCMessage alloc] init];
    msg.correlationId = 234;
    SCPoint *p = [[SCPoint alloc] initWithCoordinateArray:@[
      @(-122.0396089553833),
      @(37.33529260332278)
    ]];
    msg.payload = [[p JSONDict] JSONString];
    [[[sc.backendService notifications] take:1]
        subscribeNext:^(SCNotification *n) {
          XCTAssertNotNil(n);
          XCTAssertNotNil([n dictionary]);
          [expect fulfill];
        }];
    [sc.backendService publish:msg onTopic:@"/store/tracking"];
  }];
  [sc startAllServices];
  [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

@end
