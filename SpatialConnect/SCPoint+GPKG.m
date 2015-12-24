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

#import "SCPoint+GPKG.h"
#import "WKBGeometry.h"

@implementation SCPoint (GPKG)

- (id)initWithWKB:(WKBPoint *)w {
  self = [self initWithCoordinateArray:@[ w.x, w.y ]];

  return self;
}

- (WKBPoint *)wkGeometry {
  WKBPoint *p = [[WKBPoint alloc]
      initWithHasZ:NO
           andHasM:NO
              andX:[[NSDecimalNumber alloc] initWithDouble:self.x]
              andY:[[NSDecimalNumber alloc] initWithDouble:self.y]];
  return p;
}

- (GPKGGeometryData *)wkb {
  GPKGGeometryData *pointGeomData =
      [[GPKGGeometryData alloc] initWithSrsId:[NSNumber numberWithInt:4326]];
  [pointGeomData setGeometry:self.wkGeometry];
  return pointGeomData;
}

@end
