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

#import "SCLineString.h"
#import "SCBoundingBox.h"
#import "SCPoint.h"

@implementation SCLineString

@synthesize points;

- (id)initWithCoordinateArray:(NSArray *)coords crs:(NSInteger)c {
  if (self = [super initWithCoordinateArray:coords crs:c]) {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for (NSArray *coord in coords) {
      [arr addObject:[[SCPoint alloc] initWithCoordinateArray:coord
                                                          crs:self.crs]];
    }
    self.points = [[NSArray alloc] initWithArray:arr];
    self.bbox = [[SCBoundingBox alloc] initWithPoints:self.points crs:self.crs];
  }
  return self;
}

- (id)initWithCoordinateArray:(NSArray *)coords {
  return [self initWithCoordinateArray:coords crs:4326];
}

- (SCPoint *)first {
  return self.points.firstObject;
}

- (SCPoint *)last {
  return self.points.lastObject;
}

- (GeometryType)type {
  return LINESTRING;
}

#pragma mark - NSObject

- (NSString *)description {
  NSMutableString *str =
      [[NSMutableString alloc] initWithString:@"LineString["];
  [self.points
      enumerateObjectsUsingBlock:^(SCPoint *point, NSUInteger idx, BOOL *stop) {
        [str appendString:[point description]];
      }];
  [str appendString:@"]"];
  return str;
}

- (BOOL)isContained:(SCBoundingBox *)bbox {
  __block BOOL response = NO;
  [self.points
      enumerateObjectsUsingBlock:^(SCPoint *p, NSUInteger idx, BOOL *stop) {
        if ([bbox pointWithin:p]) {
          response = YES;
          *stop = YES;
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
  NSDictionary *geometry =
      [NSDictionary dictionaryWithObjects:@[
        @"LineString", [self coordinateArrayAsProj:4326]
      ]
                                  forKeys:@[ @"type", @"coordinates" ]];
  [dict setObject:geometry forKey:@"geometry"];
  return dict;
}

- (NSArray *)coordinateArray {
  return [self coordinateArrayAsProj:self.crs];
}

- (NSArray *)coordinateArrayAsProj:(NSInteger)c {
  return [[self.points.rac_sequence map:^NSArray *(SCPoint *p) {
    return [p coordinateArrayAsProj:c];
  }] array];
}

@end
