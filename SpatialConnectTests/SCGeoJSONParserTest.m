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

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "SCGeometryCollection.h"
#import "SCGeoJSON.h"
#import "SCFileUtils.h"

@interface SCGeoJSONParserTest : XCTestCase
@end

@implementation SCGeoJSONParserTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testFeatureReads {
  NSString *filePath = [SCFileUtils filePathFromBundle:@"feature.json"];
  NSError *error;
  NSDictionary *featureContent =
      [SCFileUtils jsonFileToDict:filePath error:&error];
  if (error) {
    XCTAssertTrue(NO, @"Error parsing Json");
  }
  if (featureContent) {
    SCGeometryCollection *features =
        (SCGeometryCollection *)[SCGeoJSON parseDict:featureContent];
    XCTAssert([[features geometries] count] > 0, @"FeatureCollection");
  }
}

- (void)testSimpleGeoJSONReads {
  NSError *error;
  NSDictionary *geometryContent = [SCFileUtils
      jsonFileToDict:[SCFileUtils filePathFromBundle:@"simple.json"]
               error:&error];
  if (error) {
    XCTAssertTrue(NO, @"Error parsing Json");
  }
  if (geometryContent) {
    SCGeometryCollection *geometries =
        (SCGeometryCollection *)[SCGeoJSON parseDict:geometryContent];
    XCTAssert([[geometries geometries] count] > 0, @"GeometryCollection");
  }
}

- (void)testMixedGeoJSONRead {
  NSError *error;
  NSDictionary *complexContent = [SCFileUtils
      jsonFileToDict:[SCFileUtils filePathFromBundle:@"all.geojson"]
               error:&error];
  if (error) {
    XCTAssertTrue(NO, @"Error parsing Json");
  }
  if (complexContent) {
    SCGeometryCollection *geometries =
        (SCGeometryCollection *)[SCGeoJSON parseDict:complexContent];
    XCTAssert([[geometries geometries] count] > 0,
              @"FeatureCollection with all types");
  }
}

- (void)testMediumGeoJSONRead {
  NSError *error;
  NSDictionary *mediumContent = [SCFileUtils
      jsonFileToDict:[SCFileUtils
                         filePathFromBundle:@"gz_2010_us_500_11_20m.json"]
               error:&error];
  if (error) {
    XCTAssertTrue(NO, @"Error parsing Json");
  }
  if (mediumContent) {
    SCGeometryCollection *geometries =
        (SCGeometryCollection *)[SCGeoJSON parseDict:mediumContent];
    XCTAssert([[geometries geometries] count] > 0,
              @"FeatureCollection with all types");
  } else {
    XCTAssertTrue(NO);
  }
}

- (void)testBigGeoJSONRead {
  NSError *error;
  NSDictionary *bigContent = [SCFileUtils
      jsonFileToDict:[SCFileUtils
                         filePathFromBundle:@"gz_2010_us_050_00_500k.json"]
               error:&error];
  if (error) {
    XCTAssertTrue(NO, @"Error parsing Json: %@", error.description);
    return;
  }
  if (bigContent) {
    SCGeometryCollection *geometries =
        (SCGeometryCollection *)[SCGeoJSON parseDict:bigContent];
    XCTAssert([[geometries geometries] count] > 0,
              @"FeatureCollection with all types");
  } else {
    XCTAssertTrue(NO);
  }
}

@end
