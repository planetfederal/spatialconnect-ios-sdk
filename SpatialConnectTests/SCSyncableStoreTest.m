//
//  SCSyncableStoreTest.m
//  SpatialConnect
//
//  Created by Frank Rowe on 2/28/17.
//  Copyright © 2017 Boundless Spatial. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpatialConnectHelper.h"
#import <XCTest/XCTest.h>
#import "SCPoint.h"

@interface SCSyncableStoreTest : XCTestCase
@property(nonatomic) SpatialConnect *sc;
@end

@implementation SCSyncableStoreTest

- (void)setUp {
  [super setUp];
  self.sc = [SpatialConnectHelper loadLocalConfig];
  [self.sc startAllServices];
}

- (void)tearDown {
  [super tearDown];
}

// download geojson file and check if file exists
- (void)testFormStoreFlag {
  XCTestExpectation *expect =
  [self expectationWithDescription:@"Flag column inserted"];
  [[SpatialConnectHelper loadGeopackageStore:[SpatialConnect sharedInstance]]
   subscribeNext:^(SCDataStore *ds) {
     GeopackageStore *gs = (GeopackageStore *)ds;
     SCGpkgFeatureSource *pointFeatures = [gs.gpkg featureSource:@"point_features"];
     SCPoint *p = [[SCPoint alloc] initWithCoordinateArray:@[ @(80), @(30) ]];
     [[pointFeatures create:p] subscribeCompleted:^{
       XCTAssertNotNil(p.identifier);
       [expect fulfill];
     }];
   }
   error:^(NSError *error) {
     XCTAssert(NO, @"Error retrieving store");
     [expect fulfill];
   }];

  [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

@end
