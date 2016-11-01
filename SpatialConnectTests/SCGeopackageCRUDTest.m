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

#import "GeopackageStore.h"
#import "SCGeoFilterContains.h"
#import "SCGeopackageHelper.h"
#import "SCPoint.h"
#import "SCTestString.h"
#import "SpatialConnect.h"
#import "SpatialConnectHelper.h"
#import <SpatialConnect/SpatialConnect.h>
#import <XCTest/XCTest.h>

@interface SCGeopackageTests : XCTestCase
@property(nonatomic) SpatialConnect *sc;
@end

@implementation SCGeopackageTests

@synthesize sc;

- (void)setUp {
  [super setUp];
  self.sc = [SpatialConnectHelper loadConfigAndStartServices];
}

- (void)tearDown {
  [super tearDown];
  [self.sc stopAllServices];
}

- (void)testGpkgFeatureDelete {
  XCTestExpectation *expect = [self expectationWithDescription:@"Delete"];
  SCQueryFilter *filter = [[SCQueryFilter alloc] init];
  filter.limit = 1;
  [[SCGeopackageHelper loadGPKGDataStore:self.sc]
      subscribeNext:^(id<SCSpatialStore> ds) {
        [[[ds query:filter] flattenMap:^RACStream *(SCSpatialFeature *f) {
          return [ds delete:f.key];
        }] subscribeError:^(NSError *error) {
          XCTFail(@"Error Deleting Feature");
          [expect fulfill];
        }
            completed:^{
              [expect fulfill];
            }];

      }
      error:^(NSError *error) {
        XCTFail(@"Error getting store");
        [expect fulfill];
      }];

  [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testGpkgDownload {
  XCTestExpectation *expect = [self expectationWithDescription:@"Download"];

  [[SCGeopackageHelper loadGPKGDataStore:self.sc]
      subscribeNext:^(SCDataStore *ds) {
        if (ds) {
          XCTAssertNotNil(ds.layers, @"Layer list as array");
        } else {
          XCTAssert(NO, @"Store is nil");
        }
        [expect fulfill];
      }
      error:^(NSError *error) {
        XCTAssert(NO, @"Error retrieving store");
        [expect fulfill];
      }];

  [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testGpkgFeatureQuery {
  XCTestExpectation *expect = [self expectationWithDescription:@"Query"];
  SCQueryFilter *filter = [[SCQueryFilter alloc] init];
  SCBoundingBox *bbox = [SCBoundingBox worldBounds];
  SCGeoFilterContains *gfc = [[SCGeoFilterContains alloc] initWithBBOX:bbox];
  SCPredicate *predicate = [[SCPredicate alloc] initWithFilter:gfc];
  [filter addPredicate:predicate];
  [[SCGeopackageHelper loadGPKGDataStore:self.sc]
      subscribeNext:^(GeopackageStore *ds) {
        [[ds query:filter] subscribeError:^(NSError *error) {
          DDLogError(@"%@", error.description);
        }
            completed:^{
              [expect fulfill];
            }];
      }];

  [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testGpkgFeatureCreate {
  XCTestExpectation *expect = [self expectationWithDescription:@"Create"];
  [[[SCGeopackageHelper loadGPKGDataStore:self.sc]
      flattenMap:^RACStream *(GeopackageStore *ds) {
        SCPoint *p =
            [[SCPoint alloc] initWithCoordinateArray:@[ @(32.3), @(43.1) ]];
        NSArray *list = ds.layers;
        p.layerId = list[0];
        return [ds create:p];
      }] subscribeError:^(NSError *error) {
    DDLogError(@"%@", error.description);
    XCTAssert(NO, @"Error creating point");
    [expect fulfill];
  }
      completed:^{
        XCTAssert(YES, @"Point created");
        [expect fulfill];
      }];
  [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testGpkgFeatureUpdate {
  XCTestExpectation *expect = [self expectationWithDescription:@"Update"];

  [[SCGeopackageHelper
      loadGPKGDataStore:self.sc] subscribeNext:^(GeopackageStore *ds) {
    RACSignal *query = [[ds query:nil] take:1];
    RACSignal *complete = [[query materialize] filter:^BOOL(RACEvent *evt) {
      return RACEventTypeCompleted == evt.eventType;
    }];
    [[[query combineLatestWith:complete] flattenMap:^RACStream *(RACTuple *t) {
      SCSpatialFeature *f = (SCSpatialFeature *)t.first;
      NSString *key = [[f.properties allKeys] objectAtIndex:0];
      [f.properties setObject:[SCTestString randomStringWithLength:200]
                       forKey:key];
      return [ds update:f];
    }] subscribeError:^(NSError *error) {
      XCTAssert(NO, @"Error loading GPGK");
      [expect fulfill];
    }
        completed:^{
          XCTAssert(YES, @"Update successfully");
          [expect fulfill];
        }];
  }];

  [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

@end
