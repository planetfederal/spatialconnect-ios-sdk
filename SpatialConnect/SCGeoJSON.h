/*!***************************************************************************
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

#import "SCGeometry.h"
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, GeoJSONType) {
  GEOJSON_POINT,
  GEOJSON_MULTIPOINT,
  GEOJSON_LINESTRING,
  GEOJSON_MULTILINESTRING,
  GEOJSON_POLYGON,
  GEOJSON_MULTIPOLYGON,
  GEOJSON_FEATURE,
  GEOJSON_FEATURE_COLLECTION,
  GEOJSON_GEOMETRY_COLLECTION
};

@interface SCGeoJSON : NSObject {
  GeoJSONType type;
  NSArray *coordinates;
  NSArray *geometries;
  NSArray *features;
  SCGeoJSON *geometry;
  NSDictionary *properties;
  NSString *identifier; //"id"
  NSDictionary *metadata;
}

- (id)initWithDictionary:(NSDictionary *)dictionary;

- (GeoJSONType)type;
- (NSArray *)coordinates;
- (NSArray *)geometries;
- (NSArray *)features;
- (NSDictionary *)geometry;
- (NSString *)identifier;
- (NSDictionary *)properties;
- (NSDictionary *)metadata;
+ (SCGeometry *)parseDict:(NSDictionary *)jsonDictionary;

@end
