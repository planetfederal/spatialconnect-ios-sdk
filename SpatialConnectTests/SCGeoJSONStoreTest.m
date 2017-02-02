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

#import "GeoJSONStore.h"
#import "SpatialConnectHelper.h"
#import <XCTest/XCTest.h>

@interface SCGeoJSONStoreTest : XCTestCase
@end

@implementation SCGeoJSONStoreTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

// download geojson file and check if file exists
- (void)testGeoJSONDownloadAndDestroy {
  XCTestExpectation *expect = [self expectationWithDescription:@"GeoJson"];
  NSString *geojsonStore = @"a5d93796-5026-46f7-a2ff-e5dec85d116c";
  NSString *fileName = [NSString stringWithFormat:@"%@.geojson", geojsonStore];
  NSString *path = [SCFileUtils filePathFromDocumentsDirectory:fileName];
  [[SpatialConnectHelper loadGeojsonDataStore:[SpatialConnect sharedInstance]]
      subscribeNext:^(id<SCDataStoreLifeCycle> ds) {
        BOOL b = [[NSFileManager defaultManager] fileExistsAtPath:path];
        XCTAssertTrue(b);
        [ds destroy];
        b = [[NSFileManager defaultManager] fileExistsAtPath:path];
        XCTAssertEqual(b, NO);
        [expect fulfill];
      }
      error:^(NSError *error) {
        XCTFail(@"Error getting store");
        [expect fulfill];
      }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
