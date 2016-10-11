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

#import "SCGeometryHelper.h"
#import "SCMultiPolygon.h"
#import "SCPoint.h"
#import "SCPolygon.h"

@interface SCMultiPolygonTest : XCTestCase {
  NSArray *polys;
  int polyCount;
}

@end

@implementation SCMultiPolygonTest

- (void)setUp {
  [super setUp];
  polyCount = 20;
  NSMutableArray *tempArray =
      [[NSMutableArray alloc] initWithCapacity:polyCount];
  for (int i = 0; i < polyCount; i++) {
    NSMutableArray *pts = [SCGeometryHelper generateRandomNumberOfPoints];
    [pts addObject:[[pts firstObject] copy]]; // close the polygon
    [tempArray addObject:[[NSMutableArray alloc]
                             initWithObjects:[pts copy], [NSArray array], nil]];
  }
  polys = [[NSArray alloc] initWithArray:tempArray];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each
  // test method in the class.
  [super tearDown];
}

- (void)testMultiPolygon {
  SCMultiPolygon *mPolys =
      [[SCMultiPolygon alloc] initWithCoordinateArray:polys];
  XCTAssertEqual(mPolys.polygons.count, polyCount, @"Size");
  for (int i = 0; i < polyCount; i++) {
    SCPolygon *mPoly = mPolys.polygons[i];
    NSArray *testPolyOuter = polys[i][0];
    long c1 = mPoly.points.count;
    long c2 = testPolyOuter.count;
    if (c1 > 0) {
      XCTAssertEqual(c1, c2, @"Size");
      for (int i = 0; i < testPolyOuter.count; i++) {
        SCPoint *p = mPoly.points[i];
        NSArray *pT = testPolyOuter[i];
        XCTAssertEqual(p.longitude, [pT[0] doubleValue], @"Longitude");
        XCTAssertEqual(p.latitude, [pT[1] doubleValue], @"Latitude");
        XCTAssertEqual(p.altitude, [pT[2] doubleValue], @"Altitude");
      }
    }
  }
}

@end
