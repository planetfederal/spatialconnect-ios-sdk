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

#import "SCPoint.h"

@interface SCPointTest : XCTestCase {
  NSArray *pointCoord;
  double latrand;
  double lonrand;
  double altrand;
}
@end

@implementation SCPointTest

- (void)setUp {
  [super setUp];
  srand((int)time(0));
  latrand = (drand48() - 0.5)*90;
  lonrand = (drand48() - 0.5)*180;
  altrand = (drand48() - 0.5) * 1000;
  pointCoord = [NSArray arrayWithObjects:
                [NSNumber numberWithDouble:lonrand],
                [NSNumber numberWithDouble:latrand],
                [NSNumber numberWithDouble:altrand], nil];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testPoint {
  SCPoint *point = [[SCPoint alloc] initWithCoordinateArray:pointCoord];
  XCTAssert([point latitude] == latrand, @"Latitude ");
  XCTAssert(point.longitude == lonrand, @"Longitude");
  XCTAssert(point.altitude == altrand, @"Altitude");
}


@end
