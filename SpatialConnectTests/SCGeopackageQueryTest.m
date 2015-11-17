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

#import <XCTest/XCTest.h>
#import "SpatialConnect.h"
#import "SCGeopackageHelper.h"
#import "GeopackageStore.h"
#import "SpatialConnectHelper.h"

@interface SCGeopackageQueryTest : XCTestCase
@property(nonatomic) SpatialConnect *sc;
@end

@implementation SCGeopackageQueryTest

@synthesize sc;

- (void)setUp {
  [super setUp];
  self.sc = [SpatialConnectHelper loadConfig];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testGpkgFeatureQuery {
  XCTestExpectation *expect = [self expectationWithDescription:@"Query"];

  [[SCGeopackageHelper loadGPKGDataStore:self.sc]
      subscribeNext:^(GeopackageStore *ds) {
        [[ds query:nil] subscribeError:^(NSError *error) {
          NSLog(@"Error");
        } completed:^{
          [expect fulfill];
        }];
      }];

  [self.sc startAllServices];
  [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

@end
