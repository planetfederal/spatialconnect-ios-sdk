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
#import "SCPolygon.h"
#import "SCPoint.h"

@interface SCPolygonTest : XCTestCase {
  NSArray *testPoly;
}

@end

@implementation SCPolygonTest

- (void)setUp {
  [super setUp];
  NSMutableArray *pts = [SCGeometryHelper generateRandomNumberOfPoints];
  testPoly = [[NSMutableArray alloc] initWithObjects:[pts copy], [NSArray array],nil];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testPolygonWithNoHoles {
  SCPolygon *mPoly = [[SCPolygon alloc] initWithCoordinateArray:testPoly];
  NSArray *testPolyOuter = testPoly[0];
  XCTAssertEqual(mPoly.points.count-1,testPolyOuter.count, @"Size");
  for (int i=0; i < testPolyOuter.count; i++) {
    SCPoint *p = mPoly.points[i];
    NSArray *pT = testPolyOuter[i];
    XCTAssertEqual(p.longitude, [pT[0] doubleValue],@"Longitude");
    XCTAssertEqual(p.latitude, [pT[1] doubleValue],@"Latitude");
    XCTAssertEqual(p.altitude, [pT[2] doubleValue],@"Altitude");
  }
}


@end
