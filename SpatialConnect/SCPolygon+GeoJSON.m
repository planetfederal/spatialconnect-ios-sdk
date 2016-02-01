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



#import "SCPoint+GeoJSON.h"
#import "SCPolygon+GeoJSON.h"
#import "SCGeometry+GeoJSON.h"

@implementation SCPolygon (GeoJSON)

//- (id)initWithGeoJSON:(SCGeoJSON *)gj {
//  self = [self initWithCoordinateArray:gj.coordinates];
//  if (!self) {
//    return nil;
//  }
//  self.identifier = gj.identifier;
//  self.properties = [NSMutableDictionary dictionaryWithDictionary:gj.properties];
//  return self;
//}

- (NSDictionary*)geoJSONDict {
  NSMutableDictionary *dict = [super geoJSONDict];
  NSDictionary *geometry = [NSDictionary dictionaryWithObjects:@[@"Polygon",self.coordinateArray] forKeys:@[@"type",@"coordinates"]];
  [dict setObject:geometry forKey:@"geometry"];
  return dict;
}

- (NSArray*)coordinateArray {
  NSMutableArray *coords = [[NSMutableArray alloc] initWithObjects:[[[self.points rac_sequence] map:^NSArray*(SCPoint* p) {
    return @[[NSNumber numberWithDouble:p.x],[NSNumber numberWithDouble:p.y],[NSNumber numberWithDouble:p.z]];
  }] array ], nil];
  
  if (self.holes) {
    [coords addObjectsFromArray:[[[self.holes.rac_sequence map:^NSArray*(SCLinearRing *ring) {
      return ring.points;
    }] map:^NSArray*(NSArray *p) {
      return [[p.rac_sequence map:^NSArray*(SCPoint *p) {
        return @[[NSNumber numberWithDouble:p.x],[NSNumber numberWithDouble:p.y],[NSNumber numberWithDouble:p.z]];
      }] array];
    }] array]];
  }
  return [NSArray arrayWithArray:coords];
}

- (NSString*)geoJSONString {
  return [super geoJSONString];
}

@end
