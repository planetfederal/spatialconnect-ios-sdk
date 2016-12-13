//
//  SCWFSTest.m
//  SpatialConnect
//
//  Created by Landon Robinson on 12/12/16.
//  Copyright © 2016 Boundless Spatial. All rights reserved.
//

#import "SCDataStore.h"
#import "SCGeoFilterContains.h"
#import "SCGeopackageGeometryExtensions.h"
#import "SCGeopackageHelper.h"
#import "SCStoreStatusEvent.h"
#import "SpatialConnect.h"
#import "SpatialConnectHelper.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <XCTest/XCTest.h>

@interface SCWFSTest : XCTestCase
@property(nonatomic) SpatialConnect *sc;
@end

@implementation SCWFSTest
@synthesize sc;

- (void)setUp {
    [super setUp];
     sc = [SpatialConnect sharedInstance];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testWFSLayerList {
    XCTestExpectation *expect =
    [self expectationWithDescription:@"GetCapabilities"];
    
    [[SpatialConnectHelper loadWFSGDataStore:self.sc]
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
         DDLogWarn(@"Error %@ ", [error description]);
     }];
    
    [self waitForExpectationsWithTimeout:120.0 handler:nil];
}

- (void)testWFSLayerQuery {
    XCTestExpectation *expect = [self expectationWithDescription:@"GetFeature"];
    __block BOOL hasFeatures = NO;
    [[[SpatialConnectHelper loadWFSGDataStore:self.sc]
      flattenMap:^RACStream *(SCDataStore *ds) {
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
    [self waitForExpectationsWithTimeout:100.0 handler:nil];
}

- (void)testWFSMultiLayerQuery {
    XCTestExpectation *expect = [self expectationWithDescription:@"GetFeature"];
    __block BOOL hasFeatures = NO;
    [[[SpatialConnectHelper loadWFSGDataStore:self.sc]
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
