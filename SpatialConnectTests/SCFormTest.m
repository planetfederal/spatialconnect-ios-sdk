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
#import "SCNetworkService.h"
#import "SCPoint.h"
#import "SpatialConnectHelper.h"
#import <XCTest/XCTest.h>

@interface SCFormTest : XCTestCase
@property SCNetworkService *net;
@property SpatialConnect *sc;
@end

@implementation SCFormTest

@synthesize net, sc;

- (void)setUp {
  [super setUp];
  self.sc = [SpatialConnectHelper loadRemoteConfig];
  self.net = self.sc.networkService;
}

- (void)tearDown {
  [super tearDown];
  [self.sc stopAllServices];
}

- (void)testGetForms {
  [self.sc startAllServices];
  NSDictionary *d = [self.sc.dataService defaultStoreForms];
  XCTAssertNotNil(d);
}

- (void)testFormToDict {
  [self.sc startAllServices];
  NSDictionary *d = [self.sc.dataService defaultStoreForms];

  [d enumerateKeysAndObjectsUsingBlock:^(NSString *key, SCFormConfig *obj, BOOL *stop) {
    NSDictionary *d = [obj JSONDict];
    XCTAssertNotNil(d[@"key"]);
    XCTAssertNotNil(d[@"label"]);
    XCTAssertNotNil(d[@"version"]);
    XCTAssertNotNil(d[@"fields"]);
  }];
}

@end
