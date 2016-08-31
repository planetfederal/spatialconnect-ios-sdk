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

#import "SCGeopackageHelper.h"
#import "SpatialConnect.h"
#import "SpatialConnectHelper.h"
#import <XCTest/XCTest.h>

@interface SCRasterTest : XCTestCase
@property(nonatomic) SpatialConnect *sc;
@end

@implementation SCRasterTest

@synthesize sc;

- (void)setUp {
  [super setUp];
  self.sc = [SpatialConnectHelper loadConfigAndStartServices];
}

- (void)tearDown {
  [super tearDown];
  [self.sc stopAllServices];
}

- (void)testRasterTableInfo {
  NSString *localRasterStoreId = @"ba293796-5026-46f7-a2ff-e5dec85heh6b";
  XCTestExpectation *expect = [self expectationWithDescription:@"Table Info"];
  [[SCGeopackageHelper loadGPKGRasterStore:self.sc]
      subscribeNext:^(SCDataStore *ds) {
        id<SCRasterStore> rs = (id<SCRasterStore>)[[self.sc dataService]
            storeByIdentifier:localRasterStoreId];
        XCTAssertNotNil(rs);
        [expect fulfill];
      }];
  [self waitForExpectationsWithTimeout:120.0 handler:nil];
}

@end
