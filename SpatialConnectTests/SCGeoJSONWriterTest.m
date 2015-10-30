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

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "SCFileUtils.h"
#import "SCGeoJSON.h"
#import "SCGeometryCollection+GeoJSON.h"

@interface SCGeoJSONWriterTest : XCTestCase

@end

@implementation SCGeoJSONWriterTest

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testWriter {
  NSString *filePath = [SCFileUtils filePathFromBundle:@"all.geojson"];
  NSError *error;
  NSDictionary *featureContent =
      [SCFileUtils jsonFileToDict:filePath error:&error];
  if (featureContent) {
    SCGeometryCollection *features =
        (SCGeometryCollection *)[SCGeoJSON parseDict:featureContent];
    NSDictionary *geoJSONDict = [features geoJSONDict];
    XCTAssert(geoJSONDict, @"FeatureCollection");
  }

  NSDictionary *geometryContent = [SCFileUtils
      jsonFileToDict:[SCFileUtils filePathFromBundle:@"simple.json"]
               error:&error];
  if (geometryContent) {
    SCGeometryCollection *geometries =
        (SCGeometryCollection *)[SCGeoJSON parseDict:geometryContent];
    XCTAssert([[geometries geometries] count] > 0, @"GeometryCollection");
  }
}

@end
