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

#import "SCFormFeature.h"
#import "SCGeopackageHelper.h"
#import "SCPoint.h"
#import "Reachability.h"
#import "SpatialConnectHelper.h"
#import <XCTest/XCTest.h>

@interface SCNetworkServiceTest : XCTestCase
@property SpatialConnect *sc;
@end

@implementation SCNetworkServiceTest

@synthesize sc;

- (void)setUp {
  [super setUp];
  self.sc = [SpatialConnectHelper loadRemoteConfig];
  [self.sc startAllServices];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each
  // test method in the class.
  [super tearDown];
  [self.sc stopAllServices];
}

- (void)testReachability {
  XCTestExpectation *expect = [self expectationWithDescription:@"Reachability"];
  [[sc serviceStarted:[SCSensorService serviceId]] subscribeNext:^(id value) {
    [self.sc.sensorService.reachabilitySignal subscribeNext:^(Reachability *r) {
      XCTAssertNotNil(r);
      [expect fulfill];
    }];
  }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testGetRequest {
  XCTestExpectation *expect = [self expectationWithDescription:@"Ping Server"];
  NSString *url =
      [NSString stringWithFormat:@"%@/ping", self.sc.backendService.backendUri];
  [[SCHttpUtils getRequestURLAsData:[NSURL URLWithString:url]]
      subscribeNext:^(NSData *d) {
        XCTAssertNotNil(d);
        [expect fulfill];
      }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testRemoteConfig {
  NSArray *arr = [self.sc.dataService.defaultStore layerList];
  XCTAssertNotNil(arr);
}

- (void)testFormSubmission {
  XCTestExpectation *expect = [self expectationWithDescription:@"FormSubmit"];
  NSArray *arr = [self.sc.dataService.defaultStore layerList];
  XCTAssertNotNil(arr);
  SCPoint *p = [[SCPoint alloc] initWithCoordinateArray:@[ @(-22.3), @(56.2) ]];
  SCFormFeature *f = [[SCFormFeature alloc] init];
  GeopackageStore *ds = self.sc.dataService.defaultStore;
  f.layerId = @"baseball_team";
  f.storeId = ds.storeId;
  f.geometry = p;
  [f.properties setObject:@"Baltimore Orioles" forKey:@"team"];
  [f.properties setObject:@"Why Not?" forKey:@"why"];
  [[ds create:f] subscribeError:^(NSError *error) {
    NSLog(@"%@", error.description);
    [expect fulfill];
  }
      completed:^{
        XCTAssert(YES);
        [expect fulfill];
      }];
  [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

@end
