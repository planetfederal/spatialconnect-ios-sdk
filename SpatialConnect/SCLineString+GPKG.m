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

#import "SCLineString+GPKG.h"
#import "SCPoint+GPKG.h"
#import <wkb_ios/WKBLineString.h>

@implementation SCLineString (GPKG)

- (id)initWithWKB:(WKBLineString *)w {
  NSArray *arr = [[w.points.rac_sequence map:^NSArray *(WKBPoint *p) {
    return @[ p.x, p.y ];
  }] array];
  self = [self initWithCoordinateArray:arr];
  return self;
}

- (WKBLineString *)wkGeometry {
  WKBLineString *ls =
      [[WKBLineString alloc] initWithType:WKB_LINESTRING andHasZ:NO andHasM:NO];
  [self.points enumerateObjectsUsingBlock:^(SCPoint *p, NSUInteger idx,
                                            BOOL *_Nonnull stop) {
    [ls addPoint:p.wkGeometry];
  }];
  return ls;
}

@end
