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
 * See the License for the specific language governing permissions and
 * limitations under the License
 */

#import "SCServiceNode.h"

@interface SCServiceNode ()
@property(nonatomic, readwrite, strong) id<SCServiceLifecycle> service;
@property(nonatomic, readwrite, strong) NSArray<SCServiceNode *> *edges;
@end

@implementation SCServiceNode

@synthesize service = _service;
@synthesize edges = _edges;

- (id)initWithService:(id<SCServiceLifecycle>)s
             andEdges:(NSArray<SCServiceNode *> *)e {
  self = [super init];
  if (self) {
    _service = s;
    _edges = e;
  }
  return self;
}

@end
