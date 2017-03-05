/**
 * Copyright 2017 Boundless http://boundlessgeo.com
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

#import "GeopackageStore.h"
#import "SCGeoFilterContains.h"
#import "SCGeopackageHelper.h"
#import "SCPoint.h"
#import "SCTestString.h"
#import "SpatialConnect.h"
#import "SpatialConnectHelper.h"
#import <SpatialConnect/SpatialConnect.h>
#import <XCTest/XCTest.h>

@interface SCStyleTest : XCTestCase
@property(nonatomic) SpatialConnect *sc;
@end

@implementation SCStyleTest

@synthesize sc;

- (void)setUp {
  [super setUp];
  self.sc = [SpatialConnectHelper loadLocalConfig];
  [self.sc startAllServices];
}

- (void)tearDown {
  [super tearDown];
  [self.sc stopAllServices];
}

- (void)testDataService {
  XCTestExpectation *expect =
  [self expectationWithDescription:@"Data Service Start"];
  [[self.sc serviceRunning:[SCDataService serviceId]]
   subscribeError:^(NSError *error) {
     DDLogError(@"Error:%@", error.description);
     [expect fulfill];
   }
   completed:^{
     XCTAssertNotNil(self.sc.dataService);
     SCDataStore *ds = [[[SpatialConnect sharedInstance] dataService] storeByIdentifier:@"5d7ddb49-83f1-48a1-b1b6-e48767b30c48"];
     XCTAssertNotNil(ds.style);
     [expect fulfill];
   }];
  [self waitForExpectationsWithTimeout:10.0 handler:nil];
}





@end
