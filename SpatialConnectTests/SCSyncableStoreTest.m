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
  [[SpatialConnectHelper loadFormStore:[SpatialConnect sharedInstance]]
   subscribeNext:^(SCDataStore *ds) {
     id<SCSpatialStore> s = (id<SCSpatialStore>)ds;
     NSError *jsonError;
     NSData *objectData = [@"{\"type\":\"Feature\",\"properties\":{\"street\":\"test\"},\"geometry\":{\"type\":\"Point\",\"coordinates\":[-104.4140625,42.032974332441405]}}" dataUsingEncoding:NSUTF8StringEncoding];
     NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                          options:NSJSONReadingMutableContainers
                                                            error:&jsonError];
     SCSpatialFeature *feat = [SCGeoJSON parseDict:json];
     feat.layerId = @"potholes";
     [[s create:feat] subscribeCompleted:^{
       XCTAssertNotNil(feat.identifier);
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
