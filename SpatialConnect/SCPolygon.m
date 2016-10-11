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

#import "SCPolygon.h"
#import "SCBoundingBox.h"
#import "SCPoint.h"

@implementation SCPolygon

@synthesize holes;

- (id)initWithCoordinateArray:(NSArray *)coords crs:(NSInteger)s {
  if (self = [super initWithCoordinateArray:coords[0] crs:s]) {
    if (coords.count > 1) {
      self.holes = [[[[coords
          objectsAtIndexes:[NSIndexSet
                               indexSetWithIndexesInRange:NSMakeRange(
                                                              1, coords.count -
                                                                     1)]]
          rac_sequence] map:^SCLinearRing *(NSArray *coordArray) {
        return [[SCLinearRing alloc] initWithCoordinateArray:coordArray crs:s];
      }] array];
    }
    self.bbox = [[SCBoundingBox alloc] initWithPoints:self.points crs:self.crs];
  }
  return self;
}

- (id)initWithCoordinateArray:(NSArray *)coords {
  return [self initWithCoordinateArray:coords crs:4326];
}

- (GeometryType)type {
  return POLYGON;
}

- (NSString *)description {
  NSMutableString *str = [[NSMutableString alloc] initWithString:@"Polygon["];
  [str appendString:@"["];
  [self.points
      enumerateObjectsUsingBlock:^(SCPoint *p, NSUInteger idx, BOOL *stop) {
        [str appendString:[p description]];
      }];
  [str appendString:@"]"];
  [self.holes enumerateObjectsUsingBlock:^(SCLinearRing *hole, NSUInteger idx,
                                           BOOL *stop) {
    [str appendString:[hole description]];
  }];
  [str appendString:@"]"];
  return str;
}

- (BOOL)isContained:(SCBoundingBox *)bbox {
  __block BOOL response = NO;
  [self.points
      enumerateObjectsUsingBlock:^(SCPoint *p, NSUInteger idx, BOOL *stop) {
        if ([bbox pointWithin:p]) {
          *stop = YES;
          response = YES;
        }
      }];
  return response;
}

- (SCSimplePoint *)centroid {
  __block double x = 0;
  __block double y = 0;
  [self.points
      enumerateObjectsUsingBlock:^(SCPoint *p, NSUInteger idx, BOOL *stop) {
        x += p.x;
        y += p.y;
      }];
  return [[SCSimplePoint alloc] initWithX:(x / self.points.count)
                                        Y:(y / self.points.count)];
}

- (NSDictionary *)JSONDict {
  NSMutableDictionary *dict =
      [NSMutableDictionary dictionaryWithDictionary:[super JSONDict]];
  NSDictionary *geometry = [NSDictionary
      dictionaryWithObjects:@[ @"Polygon", [self coordinateArrayAsProj:4326] ]
                    forKeys:@[ @"type", @"coordinates" ]];
  [dict setObject:geometry forKey:@"geometry"];
  return [NSDictionary dictionaryWithDictionary:dict];
}

- (NSArray *)coordinateArray {
  return [self coordinateArrayAsProj:self.crs];
}

- (NSArray *)coordinateArrayAsProj:(NSInteger)c {
  NSMutableArray *coords = [[NSMutableArray alloc]
      initWithObjects:[[[self.points rac_sequence] map:^NSArray *(SCPoint *p) {
                        return [p coordinateArrayAsProj:c];
                      }] array],
                      nil];

  if (self.holes) {
    [coords addObjectsFromArray:[[[self.holes.rac_sequence
                                    map:^NSArray *(SCLinearRing *ring) {
                                      return ring.points;
                                    }] map:^NSArray *(NSArray *p) {
              return [[p.rac_sequence map:^NSArray *(SCPoint *p) {
                return [p coordinateArrayAsProj:c];
              }] array];
            }] array]];
  }
  return [NSArray arrayWithArray:coords];
}

@end
