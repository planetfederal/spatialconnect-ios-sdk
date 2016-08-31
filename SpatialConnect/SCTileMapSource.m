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

#import "SCBoundingBox.h"
#import "SCPoint.h"
#import "SCTileMapSource.h"

#define TILE_WIDTH 256.0
#define TILE_HEIGHT 256.0

@implementation SCTileMapSource

- (id)init {
  if (self = [super init]) {
    SCPoint *ll =
        [[SCPoint alloc] initWithCoordinateArray:@[ @(-180), @(-90) ]];
    SCPoint *ur = [[SCPoint alloc] initWithCoordinateArray:@[ @(180), @(90) ]];
    self.coverage = [[SCBoundingBox alloc] initWithPoints:@[ ll, ur ] crs:4326];
  }
  return self;
}

- (id)initWithCoverageBBOX:(SCBoundingBox *)bbox {
  if (self = [super init]) {
    self.coverage = bbox;
  }
  return self;
}

@end
