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

#import "SCGeometryCollection.h"

@implementation SCGeometryCollection

@synthesize geometries;

- (id)initWithGeometriesArray:(NSArray *)geoms {
  if (self = [super init]) {
    self.geometries = [[NSMutableArray alloc] initWithArray:geoms];
  }
  return self;
}

- (GeometryType)type {
  return GEOMETRY_COLLECTION;
}

- (NSString *)description {
  NSMutableString *str =
      [[NSMutableString alloc] initWithString:@"GeometryCollection"];
  [self.geometries enumerateObjectsUsingBlock:^(SCGeometry *geom,
                                                NSUInteger idx, BOOL *stop) {
    if (idx > 0) {
      [str appendString:@","];
    }
    [str appendString:[geom description]];
  }];
  return str;
}

- (void)applyStyle:(SCStyle *)style {
  [self.geometries enumerateObjectsUsingBlock:^(SCGeometry *geom,
                                                NSUInteger idx, BOOL *stop) {
    if (!geom.style) {
      geom.style = [[SCStyle alloc] init];
    }
    [geom.style addMissing:style];
  }];
}

- (void)addGeometry:(SCGeometry *)geom {
  [self.geometries addObject:geom];
}

- (void)removeGeometryById:(NSObject *)identifier {
  [[[self.geometries.rac_sequence filter:^BOOL(SCGeometry *g) {
    if ([g.identifier isEqual:identifier]) {
      return YES;
    }
    return NO;
  }] signal] subscribeNext:^(SCGeometry *g) {
    [self.geometries removeObject:g];
  }];
}

- (void)removeGeometry:(SCGeometry *)geom {
  [self.geometries removeObject:geom];
}

- (BOOL)isContained:(SCBoundingBox *)bbox {
  __block BOOL response = NO;
  [self.geometries
      enumerateObjectsUsingBlock:^(SCGeometry *g, NSUInteger idx, BOOL *stop) {
        if ([g isContained:bbox]) {
          response = YES;
          *stop = YES;
        }
      }];
  return response;
}

- (NSMutableDictionary *)JSONDict {
  NSArray *features =
      [[self.geometries.rac_sequence map:^NSDictionary *(SCGeometry *geom) {
        return geom.JSONDict;
      }] array];

  NSMutableDictionary *dict = [[NSMutableDictionary alloc]
      initWithObjects:@[ @"FeatureCollection", features ]
              forKeys:@[ @"type", @"features" ]];
  if (self.identifier) {
    dict[@"id"] = self.identifier;
  }
  dict[@"properties"] = self.properties ? self.properties : [NSNull null];
  dict[@"crs"] =
      @{ @"type" : @"name",
         @"properties" : @{@"name" : @"EPSG:4326"} };
  return dict;
}

@end
