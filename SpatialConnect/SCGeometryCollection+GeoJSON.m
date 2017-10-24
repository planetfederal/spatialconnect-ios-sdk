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

#import "SCGeometry+GeoJSON.h"
#import "SCGeometryCollection+GeoJSON.h"

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

- (NSString *)geoJSONString {
  NSError *error;
  NSData *jsonData =
      [NSJSONSerialization dataWithJSONObject:[self JSONDict]
                                      options:NSJSONWritingPrettyPrinted
                                        error:&error];

  if (!jsonData) {
    DDLogError(@"GeoJSON string generation: error: %@",
               error.localizedDescription);
    return @"[]";
  } else {
    return
        [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  }
}

@end
