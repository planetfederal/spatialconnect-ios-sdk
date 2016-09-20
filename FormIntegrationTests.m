/**
 * Copyright 2016 Boundless http://boundlessgeo.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License
 */

#import "JSONKit.h"
#import "SCHttpUtils.h"
#import "SCNotification.h"
#import "SCPoint.h"
#import "Scmessage.pbobjc.h"
#import "SpatialConnect.h"
#import "SpatialConnectHelper.h"
#import "SpatialConnectHelper.h"
#import <XCTest/XCTest.h>

@interface FormIntegrationTests : XCTestCase
@property(nonatomic, strong) SpatialConnect *sc;
@end

@implementation FormIntegrationTests

@synthesize sc;

- (void)setUp {
  [super setUp];
  self.sc = [SpatialConnectHelper loadRemoteConfigAndStartServices];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testForm {
  XCTestExpectation *expect = [self expectationWithDescription:@"MQTT"];

  [[[[self.sc serviceStarted:[SCBackendService serviceId]]
      flattenMap:^RACStream *(id value) {
        [sc.authService authenticate:@"admin@something.com" password:@"admin"];
        return [[sc.backendService configReceived] filter:^BOOL(NSNumber *n) {
          return [n boolValue] == YES;
        }];
      }] take:1] subscribeNext:^(id x){
  }];

  [sc startAllServices];
  [self waitForExpectationsWithTimeout:15.0 handler:nil];
}

@end
