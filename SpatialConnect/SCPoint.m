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

#import "SCBoundingBox.h"
#import "SCPoint.h"

#include <math.h>
#define deg2rad(d) (((d)*M_PI) / 180)
#define rad2deg(d) (((d)*180) / M_PI)
#define earth_radius 6378137

@implementation SCPoint

@synthesize x = _x;
@synthesize y = _y;
@synthesize z = _z;
@synthesize crs = _crs;

- (id)init {
  if (self = [super init]) {
    self.x = 0.0;
    self.y = 0.0;
    self.z = 0.0;
    self.crs = 4326;
  }
  return self;
}

- (id)initWithCoordinateArray:(NSArray *)coordinate {
  return [self initWithCoordinateArray:coordinate crs:4326];
}

- (id)initWithCoordinateArray:(NSArray *)coordinate crs:(NSInteger)c {
  self = [super initWithCoordinateArray:coordinate crs:c];
  if (self) {
    NSUInteger len = [coordinate count];
    if (len == 2) {
      _x = [[coordinate objectAtIndex:0] doubleValue];
      _y = [[coordinate objectAtIndex:1] doubleValue];
    } else if (len == 3) {
      _x = [[coordinate objectAtIndex:0] doubleValue];
      _y = [[coordinate objectAtIndex:1] doubleValue];
      _z = [[coordinate objectAtIndex:2] doubleValue];
    }
    return self;
  }
  return nil;
}

/*!
 *  @brief WGS84 EPSG:4326 Coordiate
 *
 *  @return double
 */
- (double)longitude {
  return self.crs == 3857 ? x2lon(self.x) : self.x;
}

/*!
 *  @brief WGS84 EPSG:4326
 *
 *  @return double
 */
- (double)latitude {
  return self.crs == 3857 ? y2lat(self.y) : self.y;
}

- (double)altitude {
  return self.z;
}

- (GeometryType)type {
  return POINT;
}

- (BOOL)equals:(SCPoint *)point {
  if (self.longitude != point.longitude) {
    return NO;
  }
  if (self.latitude != point.latitude) {
    return NO;
  }
  if (self.altitude != point.altitude) {
    return NO;
  }
  return YES;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"Point[%f,%f,%f]", self.longitude,
                                    self.latitude, self.z, nil];
}

- (BOOL)isContained:(SCBoundingBox *)bbox {
  return [bbox pointWithin:self];
}

- (SCSimplePoint *)centroid {
  return [[SCSimplePoint alloc] initWithX:self.x Y:self.y];
}

- (NSDictionary *)JSONDict {
  NSMutableDictionary *dict =
      [NSMutableDictionary dictionaryWithDictionary:[super JSONDict]];
  NSDictionary *geometry = [NSDictionary
      dictionaryWithObjects:@[ @"Point", [self coordinateArrayAsProj:4326] ]
                    forKeys:@[ @"type", @"coordinates" ]];
  [dict setObject:geometry forKey:@"geometry"];
  return [NSDictionary dictionaryWithDictionary:dict];
}

double y2lat(double y) {
  return rad2deg(2 * atan(exp(y / earth_radius)) - M_PI / 2);
}

double lat2y(double lat) { return log(tan(M_PI / 4 + deg2rad(lat) / 2)); }

double x2lon(double x) { return rad2deg(x / earth_radius); }

double lon2x(double lon) { return deg2rad(lon) * earth_radius; }

- (NSArray *)coordinateArray {
  return [self coordinateArrayAsProj:self.crs];
}

- (NSArray *)coordinateArrayAsProj:(NSInteger)c {
  if (c == self.crs) {
    return @[
      [NSNumber numberWithDouble:self.x],
      [NSNumber numberWithDouble:self.y],
      [NSNumber numberWithDouble:self.z]
    ];
  } else if (c == 4326 && self.crs == 3857) {
    return @[
      [NSNumber numberWithDouble:self.longitude],
      [NSNumber numberWithDouble:self.latitude],
      [NSNumber numberWithDouble:self.z]
    ];
  } else if (c == 3857 && self.crs == 4326) {
    return @[
      [NSNumber numberWithDouble:lon2x(self.x)],
      [NSNumber numberWithDouble:lat2y(self.y)],
      [NSNumber numberWithDouble:self.z]
    ];
  } else {
    return nil;
  }
}

@end
