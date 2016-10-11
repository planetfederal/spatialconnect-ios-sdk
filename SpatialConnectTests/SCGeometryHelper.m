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

#import "SCGeometryHelper.h"

@implementation SCGeometryHelper

+ (NSMutableArray *)generateNRandomPoints:(NSUInteger)numPoints {
  NSMutableArray *points = [[NSMutableArray alloc] initWithCapacity:numPoints];
  for (int i = 0; i < numPoints; i++) {
    [points
        addObject:[NSArray arrayWithObjects:
                               [SCGeometryHelper generateRandomLongitude],
                               [SCGeometryHelper generateRandomLatitude],
                               [SCGeometryHelper generateRandomAltitude], nil]];
  }
  return points;
}

+ (NSMutableArray *)generateRandomNumberOfPoints {
  return [SCGeometryHelper
      generateNRandomPoints:[SCGeometryHelper generateRandomInteger]];
}

+ (NSUInteger)generateRandomInteger {
  srand((int)time(0));
  NSUInteger numPoints = arc4random_uniform(100) + 3;
  return numPoints;
}

+ (NSNumber *)generateRandomLongitude {
  return [NSNumber numberWithDouble:(drand48() - 0.5) * 180];
}

+ (NSNumber *)generateRandomLatitude {
  return [NSNumber numberWithDouble:(drand48() - 0.5) * 90];
}

+ (NSNumber *)generateRandomAltitude {
  return [NSNumber numberWithDouble:(drand48() - 0.5) * 1000];
}

@end
