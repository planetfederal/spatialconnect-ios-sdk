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

#import "SCTileOverlay.h"

@implementation SCTileOverlay

- (id)initWithRasterSource:(SCRasterSource *)rs {
  if (self = [super init]) {
    rasterSource = rs;
  }
  return self;
}

- (NSURL *)URLForTilePath:(MKTileOverlayPath)path {
  return [rasterSource URLForPath:path tileSize:self.tileSize];
}

- (void)loadTileAtPath:(MKTileOverlayPath)path
                result:(void (^)(NSData *, NSError *))result {
  if (!result) {
    return;
  }
  [rasterSource tileForPath:path tileSize:self.tileSize result:result];
}

@end
