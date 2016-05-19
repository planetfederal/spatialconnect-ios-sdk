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
#import "SCMultiPolygon.h"
#import "SCPolygon.h"

@interface SCMultiPolygon ()
@end

@implementation SCMultiPolygon

@synthesize polygons = _polygons;

- (id)initWithCoordinateArray:(NSArray *)coords {
  if (self = [super init]) {
    NSMutableArray *arr =
        [[NSMutableArray alloc] initWithCapacity:coords.count];
    for (NSArray *coord in coords) {
      [arr addObject:[[SCPolygon alloc] initWithCoordinateArray:coord]];
    }
    _polygons = [[NSArray alloc] initWithArray:arr];
  }
  self.bbox = [[SCBoundingBox alloc] init];
  [_polygons
      enumerateObjectsUsingBlock:^(SCPolygon *p, NSUInteger idx, BOOL *stop) {
        [self.bbox addPoints:p.points];
      }];
  return self;
}

- (GeometryType)type {
  return MULTIPOLYGON;
}

- (NSString *)description {
  NSMutableString *str =
      [[NSMutableString alloc] initWithString:@"MultiPolygon["];
  [self.polygons enumerateObjectsUsingBlock:^(SCPolygon *polygon,
                                              NSUInteger idx, BOOL *stop) {
    [str appendString:[polygon description]];
  }];
  [str appendString:@"]"];
  return str;
}

- (BOOL)isContained:(SCBoundingBox *)bbox {
  __block BOOL response = NO;
  [self.polygons enumerateObjectsUsingBlock:^(SCPolygon *poly, NSUInteger idx,
                                              BOOL *stop) {
    if ([poly isContained:bbox]) {
      response = YES;
      *stop = YES;
    }
  }];
  return response;
}

- (SCSimplePoint *)centroid {
  __block double x = 0;
  __block double y = 0;
  [self.polygons
      enumerateObjectsUsingBlock:^(SCPolygon *p, NSUInteger idx, BOOL *stop) {
        SCSimplePoint *pt = p.centroid;
        x += pt.x;
        y += pt.y;
      }];
  return [[SCSimplePoint alloc] initWithX:(x / self.polygons.count)
                                        Y:(y / self.polygons.count)];
}

- (NSDictionary *)JSONDict {
  NSMutableDictionary *dict =
      [NSMutableDictionary dictionaryWithDictionary:[super JSONDict]];
  NSArray *coords = [self coordinateArray];
  NSDictionary *geometry =
      [NSDictionary dictionaryWithObjects:@[ @"MultiPolygon", coords ]
                                  forKeys:@[ @"type", @"coordinates" ]];
  [dict setObject:geometry forKey:@"geometry"];
  return dict;
}

- (NSArray *)coordinateArray {
  return [[self.polygons.rac_sequence map:^NSArray *(SCPolygon *poly) {
    return poly.coordinateArray;
  }] array];
}

@end
