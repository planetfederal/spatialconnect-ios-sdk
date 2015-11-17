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

#import "SCGeometry+GPKG.h"
#import "WKBGeometryTypes.h"
#import "SCPoint+GPKG.h"
#import "SCMultiPoint+GPKG.h"
#import "SCLineString+GPKG.h"
#import "SCMultiLineString+GPKG.h"
#import "SCPolygon+GPKG.h"
#import "SCMultiPolygon+GPKG.h"

@implementation SCGeometry (GPKG)

- (GPKGGeometryData *)wkb {
  NSAssert(NO, @"This is an abstract method and should be overridden");
  return nil;
}

+ (SCGeometry *)fromGeometryData:(GPKGGeometryData *)gData {
  SCGeometry *g;
  WKBGeometry *wkb = gData.geometry;
  switch (wkb.geometryType) {
  case WKB_POINT:
    g = [[SCPoint alloc] initWithWKB:(WKBPoint *)wkb];
    break;
  case WKB_MULTIPOINT:
    g = [[SCMultiPoint alloc] initWithWKB:(WKBMultiPoint *)wkb];
    break;
  case WKB_LINESTRING:
    g = [[SCLineString alloc] initWithWKB:(WKBLineString *)wkb];
    break;
  case WKB_MULTILINESTRING:
    g = [[SCMultiLineString alloc] initWithWKB:(WKBMultiLineString *)wkb];
    break;
  case WKB_POLYGON:
    g = [[SCPolygon alloc] initWithWKB:(WKBPolygon *)wkb];
    break;
  case WKB_MULTIPOLYGON:
    g = [[SCMultiPolygon alloc] initWithWKB:(WKBMultiPolygon *)wkb];
    break;
  default:
    break;
  }
  if (g) {
    NSNumber *n = gData.srsId;
    g.srsId = n;
  }
  return g;
}

@end
