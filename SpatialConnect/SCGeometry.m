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
#import "SCGeometry.h"
#import "SCPoint.h"

@implementation SCGeometry

@synthesize bbox;
@synthesize crs;

- (id)initWithCoordinateArray:(NSArray *)coords {
  return [self initWithCoordinateArray:coords crs:4326];
}

- (id)initWithCoordinateArray:(NSArray *)coords crs:(NSInteger)c {
  if (self = [self init]) {
    bbox = [[SCBoundingBox alloc] init];
    self.crs = c;
    return self;
  }
  return nil;
}

- (id)init {
  self = [super init];
  if (self) {
    crs = 4326;
  }
  return self;
}

- (GeometryType)type {
  return -1;
}

- (NSString *)description {
  return [self description];
}

- (BOOL)isContained:(SCBoundingBox *)bbox {
  return NO;
}

- (SCSimplePoint *)centroid {
  return nil;
}

- (NSArray *)bboxArray {
  return @[
    [NSNumber numberWithDouble:self.bbox.lowerLeft.x],
    [NSNumber numberWithDouble:self.bbox.lowerLeft.y],
    [NSNumber numberWithDouble:self.bbox.upperRight.x],
    [NSNumber numberWithDouble:self.bbox.upperRight.y]
  ];
}

- (NSMutableDictionary *)JSONDict {
  NSMutableDictionary *dict =
      [[NSMutableDictionary alloc] initWithDictionary:[super JSONDict]];
  if (self.bboxArray) {
    dict[@"bbox"] = self.bboxArray;
  }
  dict[@"type"] = @"Feature";
  dict[@"crs"] = @{
    @"type" : @"name",
    @"properties" :
        @{@"name" : [NSString stringWithFormat:@"EPSG:%ld", (long)crs]}
  };

  return dict;
}

- (NSArray *)coordinateArray {
  return nil;
}

- (NSArray *)coordinateArrayAsProj:(NSInteger)c {
  return nil;
}

@end
