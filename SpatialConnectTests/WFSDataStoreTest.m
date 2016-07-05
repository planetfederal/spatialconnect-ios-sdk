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
#import "SCGeopackageGeometryExtensions.h"
#import "SCGeopackageHelper.h"
#import "SCStoreStatusEvent.h"
#import "SpatialConnect.h"
#import "SpatialConnectHelper.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <XCTest/XCTest.h>
#import "SCGeoFilterContains.h"

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
  [self.sc stopAllServices];
}

- (void)testWFSLayerList {
  XCTestExpectation *expect = [self expectationWithDescription:@"GetCapabilities"];

  [[SpatialConnectHelper loadWFSGDataStore:self.sc
                                   storeId:@"0f193979-b871-47cd-b60d-e271d6504359"]
   subscribeNext:^(SCDataStore *ds) {
     if (ds) {
       XCTAssertNotNil(ds.layerList, @"Layer list as array");
       XCTAssertNoThrow([sc stopAllServices]);
     } else {
       XCTAssert(NO, @"Store is nil");
     }
     [expect fulfill];
   }
   error:^(NSError *error) {
     XCTAssert(NO, @"Error retrieving store");
     [expect fulfill];
   }];

  [sc startAllServices];
  [self waitForExpectationsWithTimeout:12.0 handler:nil];
}

- (void)testWFSLayerQuery {
  XCTestExpectation *expect = [self expectationWithDescription:@"GetFeature"];
  __block BOOL hasFeatures = NO;
  [[[SpatialConnectHelper loadWFSGDataStore:self.sc
                                   storeId:@"0f193979-b871-47cd-b60d-e271d6504359"]
   flattenMap:^RACStream *(SCDataStore *ds) {
     if (ds) {
       NSString *defaultLayer = ds.defaultLayerName;
       XCTAssertNotNil(defaultLayer, @"Layer Name shall be set");
       XCTAssertNotNil(ds.layerList, @"Layer list as array");
       SCQueryFilter *filter = [[SCQueryFilter alloc] init];
       [filter addLayerId:defaultLayer];
       SCBoundingBox *bbox = [[SCBoundingBox alloc] initWithCoords:@[@(-124.07438528127528),@(42.922397667217076),@(-64.76484934151024),@(58.79784328722645)]];
       SCGeoFilterContains *gfc = [[SCGeoFilterContains alloc] initWithBBOX:bbox];
       SCPredicate *predicate = [[SCPredicate alloc] initWithFilter:gfc];
       [filter addPredicate:predicate];
       id<SCSpatialStore> s = (id<SCSpatialStore>)ds;
       return [s query:filter];
     } else {
       XCTAssert(NO, @"Store is nil");
     }
     [expect fulfill];
   }]
   subscribeNext:^(SCSpatialFeature *f) {
     XCTAssertNotNil(f,@"Feature should be alloced");
     hasFeatures = YES;
   } error:^(NSError *error) {
     XCTFail(@"%@",[error description]);
   } completed:^{
     XCTAssertNoThrow([sc stopAllServices]);
     if (hasFeatures) {
       [expect fulfill];
     }
   }];

  [sc startAllServices];
  [self waitForExpectationsWithTimeout:15.0 handler:nil];
}

@end