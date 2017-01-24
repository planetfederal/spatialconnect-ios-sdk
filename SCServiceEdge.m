/**
 * Copyright 2017 Boundless http://boundlessgeo.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and limitations under the License
 */

#import "SCServiceEdge.h"

@interface SCServiceEdge()

@end

@implementation SCServiceEdge

@synthesize node = _node;
@synthesize dep = _dep;

+ (SCServiceEdge *)withNode:(SCServiceNode *)node andDep:(SCServiceNode *)dep {
  return [SCServiceEdge withNode:node andDep:dep];
}

- (id)initWithNode:(SCServiceNode *)n dep:(SCServiceNode *)d {
  self = [super init];
  if (self) {
    _node = n;
    _dep = d;
  }
  return self;
}
@end
