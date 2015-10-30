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



#import "SCLinearRing+GeoJSON.h"
#import "SCGeometry+GeoJSON.h"
#import "SCPoint+GeoJSON.h"

@implementation SCLinearRing (GeoJSON)

- (NSDictionary*)geoJSONDict {
  NSMutableDictionary *dict = [super geoJSONDict];
  
  NSDictionary *geometry = [NSDictionary dictionaryWithObjects:@[@"LineString",[self coordinateArray]] forKeys:@[@"type",@"coordinates"]];
  dict[@"geometry"] = geometry;
  return dict;
}

- (NSArray*)coordinateArray {
  return [[self.points.rac_sequence map:^NSArray*(SCPoint *p) {
    return p.coordinateArray;
  }] array];
}

- (NSString*)geoJSONString {
  return [super geoJSONString];
}

@end
