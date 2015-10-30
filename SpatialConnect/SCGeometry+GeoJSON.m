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
#import "SCBoundingBox.h"
#import "SCPoint+GeoJSON.h"

@implementation SCGeometry (GeoJSON)

- (id)initWithGeoJSON:(SCGeoJSON *)gj {
  self = [self initWithCoordinateArray:gj.coordinates];
  self.properties = [NSMutableDictionary dictionaryWithDictionary:gj.properties];
  self.identifier = gj.identifier;
  return self;
}

- (NSMutableDictionary*)geoJSONDict {
  NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
  if (self.identifier) {
    dict[@"id"] = self.identifier;
  }
  if (self.properties) {
    dict[@"properties"] = self.properties;
  } else {
    dict[@"properties"] = [NSNull null];
  }
  if (self.bboxArray) {
    dict[@"bbox"] = self.bboxArray;
  }
  dict[@"type"] = @"Feature";
  dict[@"crs"] = @{
                   @"type" : @"name",
                   @"properties": @{
                       @"name" : @"EPSG:4326"
                       }
                   };
  
  return dict;
}

- (NSString*)geoJSONString {
  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self geoJSONDict]
                                                     options:NSJSONWritingPrettyPrinted
                                                       error:&error];
  
  if (! jsonData) {
    NSLog(@"GeoJSON string generation: error: %@", error.localizedDescription);
    return @"[]";
  } else {
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  }
}

- (NSArray*)bboxArray {
  return @[
           [NSNumber numberWithDouble:self.bbox.lowerLeft.longitude],
           [NSNumber numberWithDouble:self.bbox.lowerLeft.latitude],
           [NSNumber numberWithDouble:self.bbox.upperRight.longitude],
           [NSNumber numberWithDouble:self.bbox.upperRight.latitude]
          ];
}

@end
