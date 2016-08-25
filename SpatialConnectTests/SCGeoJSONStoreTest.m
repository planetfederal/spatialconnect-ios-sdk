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

#import "SpatialConnectHelper.h"
#import <XCTest/XCTest.h>

@interface SCGeoJSONStoreTest : XCTestCase
@property SCNetworkService *net;
@property SpatialConnect *sc;
@end

@implementation SCGeoJSONStoreTest

@synthesize net, sc;

- (void)setUp {
  [super setUp];
  self.sc = [SpatialConnectHelper loadConfig];
  [self.sc startAllServices];
}

- (void)tearDown {
  [super tearDown];
  [self.sc stopAllServices];
}

//download geojson file and check if file exists
- (void)testGeoJSONDownload {
  XCTestExpectation *expect = [self expectationWithDescription:@"Delete"];
  NSString *storeId = @"a5d93796-5026-46f7-a2ff-e5dec85d116c";
  NSString *fileName = [NSString stringWithFormat:@"%@.geojson", storeId];
  NSString *path = [SCFileUtils filePathFromNSHomeDirectory:fileName];
  [[[sc.dataService storeStarted:storeId] map:^SCDataStore*(SCStoreStatusEvent *evt) {
    SCDataStore *ds = [sc.dataService storeByIdentifier:storeId];
    return ds;
  }] subscribeNext:^(id<SCSpatialStore> ds) {
    BOOL b = [[NSFileManager defaultManager] fileExistsAtPath:path];
    XCTAssertTrue(b);
    [expect fulfill];
  } error:^(NSError *error) {
    XCTFail(@"Error getting store");
    [expect fulfill];
  }];
  [self waitForExpectationsWithTimeout:1000.0 handler:nil];
}


@end
