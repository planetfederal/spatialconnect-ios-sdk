//
//  SCGeopackageQueryTest.m
//  SpatialConnect
//
//  Created by Wes Richardet on 11/10/15.
//  Copyright © 2015 Boundless Spatial. All rights reserved.
//

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
        [[ds queryAllLayers:nil] subscribeError:^(NSError *error) {
          NSLog(@"Error");
        } completed:^{
          [expect fulfill];
        }];
      }];

  [self.sc startAllServices];
  [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

@end
