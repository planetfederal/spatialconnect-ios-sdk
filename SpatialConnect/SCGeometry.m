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

#import "SCGeometry.h"
#import "SCBoundingBox.h"

@implementation SCGeometry

@synthesize bbox;
@synthesize srsId;

- (id)initWithCoordinateArray:(NSArray *)coords {
  if (self = [self init]) {
    bbox = [[SCBoundingBox alloc] init];
    return self;
  }
  return nil;
}

- (id)init {
  self = [super init];
  if (self) {
    srsId = [NSNumber numberWithLong:4326];
  }
  return self;
}

- (GeometryType)type {
  return -1;
}

- (NSString *)description {
  return [self description];
}

- (BOOL)checkWithin:(SCBoundingBox *)bbox {
  return NO;
}
@end
