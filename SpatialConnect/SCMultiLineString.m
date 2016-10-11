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
#import "SCLineString.h"
#import "SCMultiLinestring.h"

@interface SCMultiLineString ()
@property(readwrite, nonatomic, strong) NSArray *linestrings;
@end

@implementation SCMultiLineString

@synthesize linestrings = _linestrings;

- (id)initWithCoordinateArray:(NSArray *)coords crs:(NSInteger)s {
  if (self = [super initWithCoordinateArray:coords crs:s]) {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for (NSArray *linestring in coords) {
      SCLineString *l =
          [[SCLineString alloc] initWithCoordinateArray:linestring crs:s];
      [arr addObject:l];
    }
    _linestrings = [[NSArray alloc] initWithArray:arr];
  }
  self.bbox = [[SCBoundingBox alloc] init];
  [_linestrings enumerateObjectsUsingBlock:^(SCLineString *l, NSUInteger idx,
                                             BOOL *stop) {
    [self.bbox addPoints:l.points];
  }];
  return self;
}

- (id)initWithCoordinateArray:(NSArray *)coords {
  return [self initWithCoordinateArray:coords crs:4326];
}

- (GeometryType)type {
  return MULTILINESTRING;
}

- (NSString *)description {
  NSMutableString *str =
      [[NSMutableString alloc] initWithString:@"MultiLineString["];
  [self.linestrings enumerateObjectsUsingBlock:^(SCLineString *lineString,
                                                 NSUInteger idx, BOOL *stop) {
    [str appendString:[lineString description]];
  }];
  [str appendString:@"]"];
  return str;
}

- (BOOL)isContained:(SCBoundingBox *)bbox {
  __block BOOL response = NO;
  [self.linestrings enumerateObjectsUsingBlock:^(SCLineString *line,
                                                 NSUInteger idx, BOOL *stop) {
    if ([line isContained:bbox]) {
      response = YES;
      *stop = YES;
    }
  }];
  return response;
}

- (SCSimplePoint *)centroid {
  __block double x = 0;
  __block double y = 0;
  [self.linestrings enumerateObjectsUsingBlock:^(SCLineString *l,
                                                 NSUInteger idx, BOOL *stop) {
    SCSimplePoint *p = l.centroid;
    x += p.x;
    y += p.y;
  }];
  return [[SCSimplePoint alloc] initWithX:(x / self.linestrings.count)
                                        Y:(y / self.linestrings.count)];
}

- (NSDictionary *)JSONDict {
  NSMutableDictionary *dict =
      [NSMutableDictionary dictionaryWithDictionary:[super JSONDict]];
  NSDictionary *geometry =
      [NSDictionary dictionaryWithObjects:@[
        @"MultiLineString", [self coordinateArrayAsProj:4326]
      ]
                                  forKeys:@[ @"type", @"coordinates" ]];
  [dict setObject:geometry forKey:@"geometry"];
  return [NSDictionary dictionaryWithDictionary:dict];
}

- (NSArray *)coordinateArray {
  return [self coordinateArrayAsProj:self.crs];
}

- (NSArray *)coordinateArrayAsProj:(NSInteger)c {
  return
      [[self.linestrings.rac_sequence map:^NSArray *(SCLineString *lineString) {
        return [lineString coordinateArrayAsProj:c];
      }] array];
}

@end
