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

#import "SCGeometryCollection+GeoJSON.h"
#import "SCGeometry+GeoJSON.h"

@class SCPoint;

@implementation SCGeometryCollection (GeoJSON)

- (id)initWithGeoJSON:(SCGeoJSON *)gj {
  self = [super initWithGeoJSON:gj];
  if (!self) {
    return nil;
  }
  NSArray *geoms;
  if (gj.type == GEOJSON_FEATURE_COLLECTION) {
    geoms = gj.features;
  } else {
    geoms = gj.geometries;
  }
  self.geometries = [NSMutableArray
      arrayWithArray:[[geoms.rac_sequence map:^SCGeometry *(SCGeoJSON *gj) {
        return [[SCGeometry alloc] initWithGeoJSON:gj];
      }] array]];
  return self;
}

- (NSMutableDictionary *)geoJSONDict {
  NSArray *features =
      [[self.geometries.rac_sequence map:^NSDictionary *(SCGeometry *geom) {
        return geom.geoJSONDict;
      }] array];

  NSMutableDictionary *dict = [[NSMutableDictionary alloc]
      initWithObjects:@[ @"FeatureCollection", features ]
              forKeys:@[ @"type", @"features" ]];
  if (self.identifier) {
    dict[@"id"] = self.identifier;
  }
  dict[@"properties"] = self.properties ? self.properties : [NSNull null];
  dict[@"crs"] = @{
    @"type" : @"name",
    @"properties" : @{@"name" : @"EPSG:4326"}
  };
  return dict;
}

- (NSString *)geoJSONString {
  NSError *error;
  NSData *jsonData =
      [NSJSONSerialization dataWithJSONObject:[self geoJSONDict]
                                      options:NSJSONWritingPrettyPrinted
                                        error:&error];

  if (!jsonData) {
    NSLog(@"GeoJSON string generation: error: %@", error.localizedDescription);
    return @"[]";
  } else {
    return
        [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  }
}

@end
