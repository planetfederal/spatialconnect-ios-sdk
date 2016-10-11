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

#import "SCGeoJSON.h"
#import "SCGeometry+GeoJSON.h"
#import "SCGeometryCollection+GeoJSON.h"
#import "SCKeyTuple.h"
#import "SCLineString+GeoJSON.h"
#import "SCMultiLineString+GeoJSON.h"
#import "SCMultiPoint+GeoJSON.h"
#import "SCMultiPolygon+GeoJSON.h"
#import "SCPoint+GeoJSON.h"
#import "SCPolygon+GeoJSON.h"

@interface SCGeoJSON ()

- (GeoJSONType)typeFromString:(NSString *)typeStr;

@end

@implementation SCGeoJSON

- (id)initWithDictionary:(NSDictionary *)dictionary {
  if (self = [super init]) {
    type = [self typeFromString:[dictionary objectForKey:@"type"]];
    identifier = dictionary[@"id"];
    properties = [dictionary objectForKey:@"properties"];
    if (type == GEOJSON_FEATURE_COLLECTION) {
      features = [dictionary objectForKey:@"features"];
    } else if (type == GEOJSON_GEOMETRY_COLLECTION) {
      geometries = [dictionary objectForKey:@"geometries"];
    } else if (type == GEOJSON_FEATURE) {
      geometry = [dictionary objectForKey:@"geometry"];
    } else {
      coordinates = [dictionary objectForKey:@"coordinates"];
    }
    metadata = [dictionary objectForKey:@"metadata"];
  }
  return self;
}

- (GeoJSONType)type {
  return type;
}
- (NSArray *)coordinates {
  return coordinates;
}
- (NSArray *)features {
  return features;
}
- (NSArray *)geometries {
  return geometries;
}
- (SCGeoJSON *)geometry {
  return geometry;
}
- (NSString *)identifier {
  return identifier;
}
- (NSDictionary *)properties {
  return properties;
}

- (NSDictionary *)metadata {
  return metadata;
}

- (GeoJSONType)typeFromString:(NSString *)typeStr {
  if ([typeStr isEqualToString:@"Point"]) {
    return GEOJSON_POINT;
  } else if ([typeStr isEqualToString:@"MultiPoint"]) {
    return GEOJSON_MULTIPOINT;
  } else if ([typeStr isEqualToString:@"LineString"]) {
    return GEOJSON_LINESTRING;
  } else if ([typeStr isEqualToString:@"MultiLineString"]) {
    return GEOJSON_MULTILINESTRING;
  } else if ([typeStr isEqualToString:@"Polygon"]) {
    return GEOJSON_POLYGON;
  } else if ([typeStr isEqualToString:@"MultiPolygon"]) {
    return GEOJSON_MULTIPOLYGON;
  } else if ([typeStr isEqualToString:@"Feature"]) {
    return GEOJSON_FEATURE;
  } else if ([typeStr isEqualToString:@"FeatureCollection"]) {
    return GEOJSON_FEATURE_COLLECTION;
  } else if ([typeStr isEqualToString:@"GeometryCollection"]) {
    return GEOJSON_GEOMETRY_COLLECTION;
  } else {
    return -1;
  }
}

- (GeoJSONType)typeFromType:(GeometryType)geometryType {
  switch (geometryType) {
  case POINT:
    return GEOJSON_POINT;
    break;
  case MULTIPOINT:
    return GEOJSON_MULTIPOINT;
    break;
  case LINEARRING:
    return GEOJSON_LINESTRING;
    break;
  case LINESTRING:
    return GEOJSON_LINESTRING;
    break;
  case MULTILINESTRING:
    return GEOJSON_MULTILINESTRING;
    break;
  case POLYGON:
    return GEOJSON_POLYGON;
    break;
  case MULTIPOLYGON:
    return GEOJSON_MULTIPOLYGON;
  default:
    return -1;
  }
}

#pragma mark -
#pragma mark Class Methods
+ (SCGeometry *)parseDict:(NSDictionary *)jsonDictionary {
  SCGeoJSON *geoJson = [[SCGeoJSON alloc] initWithDictionary:jsonDictionary];
  SCGeometry *geom;
  switch (geoJson.type) {
  case GEOJSON_GEOMETRY_COLLECTION:
    geom = [SCGeoJSON parseGeometryCollection:geoJson];
    break;
  case GEOJSON_FEATURE:
    geom = [SCGeoJSON parseDict:geoJson.geometry];
    break;
  case GEOJSON_FEATURE_COLLECTION:
    geom = [SCGeoJSON parseFeatureCollection:geoJson];
    break;
  case GEOJSON_POINT:
    geom = [[SCPoint alloc] initWithCoordinateArray:geoJson.coordinates];
    break;
  case GEOJSON_MULTIPOINT:
    geom = [[SCMultiPoint alloc] initWithCoordinateArray:geoJson.coordinates];
    break;
  case GEOJSON_LINESTRING:
    geom = [[SCLineString alloc] initWithCoordinateArray:geoJson.coordinates];
    break;
  case GEOJSON_MULTILINESTRING:
    geom =
        [[SCMultiLineString alloc] initWithCoordinateArray:geoJson.coordinates];
    break;
  case GEOJSON_POLYGON:
    geom = [[SCPolygon alloc] initWithCoordinateArray:geoJson.coordinates];
    break;
  case GEOJSON_MULTIPOLYGON:
    geom = [[SCMultiPolygon alloc] initWithCoordinateArray:geoJson.coordinates];
    break;
  default:
    geom = (SCGeometry *)[[SCSpatialFeature alloc] init];
    break;
  }
  if (geoJson.identifier) {
    geom.identifier = geoJson.identifier;
  }
  if (geoJson.properties && ![geoJson.properties isKindOfClass:NSNull.class]) {
    geom.properties =
        [NSMutableDictionary dictionaryWithDictionary:geoJson.properties];
  }
  if (geoJson.metadata) {
    geom.layerId = geoJson.metadata[@"layerId"];
    geom.storeId = geoJson.metadata[@"storeId"];
  }
  return geom;
}

#pragma mark - Private

+ (SCGeometry *)parseGeometryCollection:(SCGeoJSON *)geoJson {
  NSArray *arr =
      [NSMutableArray arrayWithArray:[[geoJson.geometries.rac_sequence
                                         map:^SCGeometry *(NSDictionary *d) {
                                           return [SCGeoJSON parseDict:d];
                                         }] array]];
  SCGeometryCollection *gc =
      [[SCGeometryCollection alloc] initWithGeometriesArray:arr];
  return gc;
}

+ (SCGeometry *)parseFeatureCollection:(SCGeoJSON *)geoJson {
  NSArray *arr =
      [NSMutableArray arrayWithArray:[[geoJson.features.rac_sequence
                                         map:^SCGeometry *(NSDictionary *d) {
                                           return [SCGeoJSON parseDict:d];
                                         }] array]];
  SCGeometryCollection *gc =
      [[SCGeometryCollection alloc] initWithGeometriesArray:arr];
  return gc;
}

@end
