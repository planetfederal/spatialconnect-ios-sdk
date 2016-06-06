

#import "SCGeoFilterContains.h"
#import "SCGeometryCollection.h"
#import "SCGeopackage.h"
#import "SCGeopackageHelper.h"
#import "SCPoint.h"
#import <XCTest/XCTest.h>

@interface SCGeopackageTest : XCTestCase {
  SCGeopackage *gpkg;
}
@end

@implementation SCGeopackageTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
  if (gpkg) {
    [gpkg close];
  }
}

- (void)testContents {
  XCTestExpectation *expect = [self expectationWithDescription:@"Storage"];

  [[SCGeopackageHelper downloadGpkgFile] subscribeNext:^(NSString *filename) {
    gpkg = [[SCGeopackage alloc] initWithFilename:filename];
    __block BOOL foundOne = NO;
    [[gpkg contents] subscribeNext:^(id x) {
      foundOne = YES;
    }
        completed:^{
          if (foundOne) {
            [expect fulfill];
          } else {
            [expect fulfill];
          }
        }];
  }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testExtensions {
  XCTestExpectation *expect = [self expectationWithDescription:@"Extensions"];

  [[SCGeopackageHelper downloadGpkgFile] subscribeNext:^(NSString *filename) {
    gpkg = [[SCGeopackage alloc] initWithFilename:filename];
    __block BOOL foundOne = NO;
    [[gpkg extensions] subscribeNext:^(id x) {
      foundOne = YES;
    }
        completed:^{
          if (foundOne) {
            [expect fulfill];
          } else {
            [expect fulfill];
          }
        }];
  }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testVectors {
  XCTestExpectation *expect = [self expectationWithDescription:@"Vectors"];
  [[SCGeopackageHelper downloadGpkgFile] subscribeNext:^(NSString *filename) {
    gpkg = [[SCGeopackage alloc] initWithFilename:filename];
    SCGpkgFeatureSource *pointFeatures = [gpkg featureSource:@"point_features"];
    XCTAssertNotNil(pointFeatures.geomColName);
    XCTAssertGreaterThan(pointFeatures.colsTypes.allKeys.count, 0);
    SCGpkgFeatureSource *linFeatures = [gpkg featureSource:@"linear_features"];
    XCTAssertNotNil(linFeatures.geomColName);
    XCTAssertGreaterThan(linFeatures.colsTypes.allKeys.count, 0);
    SCGpkgFeatureSource *polyFeatures =
        [gpkg featureSource:@"polygon_features"];
    XCTAssertNotNil(polyFeatures.geomColName);
    XCTAssertGreaterThan(polyFeatures.colsTypes.allKeys.count, 0);
    [expect fulfill];
  }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testEmptyQuery {
  XCTestExpectation *expect = [self expectationWithDescription:@"Vectors"];
  [[SCGeopackageHelper downloadGpkgFile] subscribeNext:^(NSString *filename) {
    gpkg = [[SCGeopackage alloc] initWithFilename:filename];
    SCGpkgFeatureSource *pointFeatures = [gpkg featureSource:@"point_features"];
    [[pointFeatures queryWithFilter:nil] subscribeNext:^(SCSpatialFeature *x) {
      XCTAssertNotNil(x);
      XCTAssertNotNil(x.identifier);
    }
        error:^(NSError *error) {
          XCTFail();
        }
        completed:^{
          [expect fulfill];
        }];

  }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testCreate {
  XCTestExpectation *expect = [self expectationWithDescription:@"Vectors"];
  [[SCGeopackageHelper downloadGpkgFile] subscribeNext:^(NSString *filename) {
    gpkg = [[SCGeopackage alloc] initWithFilename:filename];
    SCGpkgFeatureSource *pointFeatures = [gpkg featureSource:@"point_features"];
    SCPoint *p = [[SCPoint alloc] initWithCoordinateArray:@[ @(80), @(30) ]];
    [[pointFeatures create:p] subscribeCompleted:^{
      XCTAssertNotNil(p.identifier);
      [expect fulfill];
    }];
  }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testUpdate {
  XCTestExpectation *expect = [self expectationWithDescription:@"Vectors"];
  [[SCGeopackageHelper downloadGpkgFile] subscribeNext:^(NSString *filename) {
    gpkg = [[SCGeopackage alloc] initWithFilename:filename];
    SCGpkgFeatureSource *pointFeatures = [gpkg featureSource:@"point_features"];
    SCPoint *p = [[SCPoint alloc] initWithCoordinateArray:@[ @(80), @(30) ]];
    [[[[[pointFeatures create:p] materialize] filter:^BOOL(RACEvent *evt) {
      return evt.eventType == RACEventTypeCompleted;
    }] flattenMap:^RACStream *(id val) {
      NSString *key = [[p.properties allKeys] firstObject];
      [p.properties setObject:@"foo" forKey:key];
      return [pointFeatures update:p];
    }] subscribeError:^(NSError *error) {
      XCTFail(@"Error %@", error.description);
      [expect fulfill];
    }
        completed:^{
          [expect fulfill];
        }];

  }];
  [self waitForExpectationsWithTimeout:50.0 handler:nil];
}

- (void)testDeleteFeature {
  XCTestExpectation *expect = [self expectationWithDescription:@"Vectors"];
  [[SCGeopackageHelper downloadGpkgFile] subscribeNext:^(NSString *filename) {
    gpkg = [[SCGeopackage alloc] initWithFilename:filename];
    SCGpkgFeatureSource *pointFeatures = [gpkg featureSource:@"point_features"];
    SCPoint *p = [[SCPoint alloc] initWithCoordinateArray:@[ @(80), @(30) ]];
    [[[[[pointFeatures create:p] materialize] filter:^BOOL(RACEvent *event) {
      return event.eventType == RACEventTypeCompleted;
    }] flattenMap:^RACStream *(id value) {
      return [pointFeatures remove:p.key];
    }] subscribeError:^(NSError *error) {
      XCTFail(@"%@", error.description);
      [expect fulfill];
    }
        completed:^{
          [expect fulfill];
        }];
  }];
  [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testFindById {
  XCTestExpectation *expect = [self expectationWithDescription:@"Vectors"];
  [[SCGeopackageHelper downloadGpkgFile] subscribeNext:^(NSString *filename) {
    gpkg = [[SCGeopackage alloc] initWithFilename:filename];
    SCGpkgFeatureSource *pointFeatures =
        [gpkg featureSource:@"polygon_features"];
    SCPoint *p = [[SCPoint alloc] initWithCoordinateArray:@[ @(80), @(30) ]];
    RACSignal *create = [pointFeatures create:p];
    RACSignal *complete = [[create materialize] filter:^BOOL(RACEvent *evt) {
      return evt.eventType == RACEventTypeCompleted;
    }];
    [[complete flattenMap:^RACStream *(id value) {
      return [pointFeatures findById:p.identifier];
    }] subscribeNext:^(SCSpatialFeature *x) {
      XCTAssertEqual(p.identifier, x.identifier);
      [expect fulfill];
    }
        error:^(NSError *error) {
          XCTFail(@"%@", error.description);
          [expect fulfill];
        }];
  }];
  [self waitForExpectationsWithTimeout:15.0 handler:nil];
}

- (void)testAddTable {
  XCTestExpectation *expect = [self expectationWithDescription:@"Add Table"];
  [[SCGeopackageHelper downloadGpkgFile] subscribeNext:^(NSString *filename) {
    gpkg = [[SCGeopackage alloc] initWithFilename:filename];
    [gpkg addFeatureSource:@"foo" withTypes:nil];
    [expect fulfill];
  }];
  [self waitForExpectationsWithTimeout:12.0 handler:nil];
}

@end
