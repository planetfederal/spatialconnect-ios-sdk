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
@property SpatialConnect *sc;
@end

@implementation SCGeoJSONStoreTest

@synthesize sc;

- (void)setUp {
  [super setUp];
  self.sc = [SpatialConnectHelper loadConfig];
}

- (void)tearDown {
  [super tearDown];
}

// download geojson file and check if file exists
- (void)testGeoJSONDownload {
  XCTestExpectation *expect = [self expectationWithDescription:@"Delete"];
  NSString *storeId = @"08e4c309-46b8-4ad5-ba2b-190ab52c8efc";
  NSString *fileName = [NSString stringWithFormat:@"%@.geojson", storeId];
  NSString *path = [SCFileUtils filePathFromDocumentsDirectory:fileName];
  [[[[[[sc serviceStarted:[SCBackendService serviceId]] flattenMap:^RACStream *(id value) {
    return sc.backendService.configReceived;
  }] filter:^BOOL(NSNumber *v) {
    return v.boolValue;
  }] take:1] flattenMap:^RACStream *(id value) {
    return [sc.dataService storeStarted:storeId];
  }] subscribeNext:^(id<SCSpatialStore> ds) {
    BOOL b = [[NSFileManager defaultManager] fileExistsAtPath:path];
    XCTAssertTrue(b);
    [expect fulfill];
  }
      error:^(NSError *error) {
        XCTFail(@"Error getting store");
        [expect fulfill];
      }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
