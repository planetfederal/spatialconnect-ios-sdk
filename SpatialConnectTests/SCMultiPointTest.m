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

#import "SCMultiPoint.h"
#import "SCPoint.h"
#import "SCGeometryHelper.h"

@interface SCMultiPointTest : XCTestCase {
  NSArray *points;
  NSUInteger numPoints;
}

@end

@implementation SCMultiPointTest

- (void)setUp {
  [super setUp];
  numPoints = 500;
  points = [SCGeometryHelper generateNRandomPoints:numPoints];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testMultiPoint {
  SCMultiPoint *mPoint = [[SCMultiPoint alloc] initWithCoordinateArray:points];
  XCTAssertEqual(mPoint.points.count, numPoints, @"Size");
  for (int i = 0; i < numPoints; i++) {
    SCPoint *p = mPoint.points[i];
    NSArray *pT = points[i];
    XCTAssertEqual(p.longitude, [pT[0] doubleValue], @"Longitude");
    XCTAssertEqual(p.latitude, [pT[1] doubleValue], @"Latitude");
    XCTAssertEqual(p.altitude, [pT[2] doubleValue], @"Altitude");
  }
}

@end
