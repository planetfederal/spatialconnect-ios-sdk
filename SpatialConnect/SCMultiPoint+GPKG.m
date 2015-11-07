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

#import "SCMultiPoint+GPKG.h"
#import "SCPoint+GPKG.h"
#import "WKBMultiPoint.h"

@implementation SCMultiPoint (GPKG)

- (GPKGGeometryData*)wkb {
  WKBMultiPoint *mp = [[WKBMultiPoint alloc] initWithType:WKB_MULTIPOINT andHasZ:NO andHasM:NO];
  [self.points enumerateObjectsUsingBlock:^(SCPoint *p, NSUInteger idx, BOOL * _Nonnull stop) {
    [mp addPoint:p.wkGeometry];
  }];
  GPKGGeometryData *geomData = [[GPKGGeometryData alloc] initWithSrsId:[NSNumber numberWithInt:4326]];
  [geomData setGeometry:mp];
  return geomData;
}

@end
