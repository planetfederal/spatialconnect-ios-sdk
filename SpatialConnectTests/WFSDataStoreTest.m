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

#import "SCDataStore.h"
#import "SCGeoFilterContains.h"
#import "SCGeopackageGeometryExtensions.h"
#import "SCGeopackageHelper.h"
#import "SCStoreStatusEvent.h"
#import "SpatialConnect.h"
#import "SpatialConnectHelper.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <XCTest/XCTest.h>

@interface WFSDataStoreTest : XCTestCase
@property(nonatomic) SpatialConnect *sc;
@end

@implementation WFSDataStoreTest
@synthesize sc;

- (void)setUp {
  [super setUp];
  self.sc = [SpatialConnectHelper loadConfig];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testWFSLayerList {
  XCTestExpectation *expect =
      [self expectationWithDescription:@"GetCapabilities"];

  [[SpatialConnectHelper
      loadWFSGDataStore:self.sc
                storeId:@"71522e9b-3ec6-48c3-8d5c-57c8d14baf6a"]
      subscribeNext:^(SCDataStore *ds) {
        if (ds) {
          NSArray *list = ds.layers;
          XCTAssertNotNil(list, @"Layer list as array");
        } else {
          XCTAssert(NO, @"Store is nil");
        }
        [expect fulfill];
      }
      error:^(NSError *error) {
        XCTAssert(NO, @"Error retrieving store");
        [expect fulfill];
      }];

  [self waitForExpectationsWithTimeout:12.0 handler:nil];
}

- (void)testWFSLayerQuery {
  XCTestExpectation *expect = [self expectationWithDescription:@"GetFeature"];
  __block BOOL hasFeatures = NO;
  [[[sc.dataService storeStarted:@"71522e9b-3ec6-48c3-8d5c-57c8d14baf6a"]
      flattenMap:^RACStream *(SCStoreStatusEvent *evt) {
        SCDataStore *ds = [sc.dataService
            storeByIdentifier:@"71522e9b-3ec6-48c3-8d5c-57c8d14baf6a"];
        if (ds) {
          XCTAssertNotNil(ds.layers, @"Layer list as array");
          SCQueryFilter *filter = [[SCQueryFilter alloc] init];
          SCBoundingBox *bbox = [[SCBoundingBox alloc]
              initWithCoords:@[ @(-178.0), @(-87.0), @(178.0), @(87.0) ]];
          SCGeoFilterContains *gfc =
              [[SCGeoFilterContains alloc] initWithBBOX:bbox];
          SCPredicate *predicate = [[SCPredicate alloc] initWithFilter:gfc];
          [filter addPredicate:predicate];
          id<SCSpatialStore> s = (id<SCSpatialStore>)ds;
          return [s query:filter];
        } else {
          XCTAssert(NO, @"Store is nil");
        }
        [expect fulfill];
      }] subscribeNext:^(SCSpatialFeature *f) {
    XCTAssertNotNil(f, @"Feature should be alloced");
    hasFeatures = YES;
  }
      error:^(NSError *error) {
        XCTFail(@"%@", [error description]);
      }
      completed:^{
        if (hasFeatures) {
          [expect fulfill];
        }
      }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testWFSMultiLayerQuery {
  XCTestExpectation *expect = [self expectationWithDescription:@"GetFeature"];
  __block BOOL hasFeatures = NO;
  [[[SpatialConnectHelper
      loadWFSGDataStore:self.sc
                storeId:@"71522e9b-3ec6-48c3-8d5c-57c8d14baf6a"]
      flattenMap:^RACStream *(SCDataStore *ds) {
        if (ds) {
          SCQueryFilter *filter = [[SCQueryFilter alloc] init];
          NSArray *ll = ds.layers;
          [filter addLayerIds:[ll subarrayWithRange:NSMakeRange(0, 3)]];
          SCBoundingBox *bbox = [[SCBoundingBox alloc] initWithCoords:@[
            @(-100.07438528127528), @(20.922397667217076),
            @(-60.76484934151024), @(58.79784328722645)
          ]];
          SCGeoFilterContains *gfc =
              [[SCGeoFilterContains alloc] initWithBBOX:bbox];
          SCPredicate *predicate = [[SCPredicate alloc] initWithFilter:gfc];
          [filter addPredicate:predicate];
          id<SCSpatialStore> s = (id<SCSpatialStore>)ds;
          return [s query:filter];
        } else {
          XCTAssert(NO, @"Store is nil");
        }
        [expect fulfill];
      }] subscribeNext:^(SCSpatialFeature *f) {
    XCTAssertNotNil(f, @"Feature should be alloc'ed");
    hasFeatures = YES;
  }
      error:^(NSError *error) {
        XCTFail(@"%@", [error description]);
      }
      completed:^{
        if (hasFeatures) {
          [expect fulfill];
        }
      }];
  [self waitForExpectationsWithTimeout:20.0 handler:nil];
}

@end
