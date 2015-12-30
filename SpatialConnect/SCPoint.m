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

@implementation SCPoint

@synthesize x = _x;
@synthesize y = _y;
@synthesize z = _z;

- (id)init {
  if (self = [super init]) {
    self.x = 0.0;
    self.y = 0.0;
    self.z = 0.0;
  }
  return self;
}

- (id)initWithCoordinateArray:(NSArray *)coordinate {
  self = [super init];
  if (!self) {
    return nil;
  }
  NSUInteger len = [coordinate count];
  if (len == 2) {
    _x = [[coordinate objectAtIndex:0] doubleValue];
    _y = [[coordinate objectAtIndex:1] doubleValue];
  } else if (len == 3) {
    _x = [[coordinate objectAtIndex:0] doubleValue];
    _y = [[coordinate objectAtIndex:1] doubleValue];
    _z = [[coordinate objectAtIndex:2] doubleValue];
  } else {
    self = nil;
  }

  return self;
}

- (double)longitude {
  return self.x;
}

- (double)latitude {
  return self.y;
}

- (double)altitude {
  return self.z;
}

- (GeometryType)type {
  return POINT;
}

- (BOOL)equals:(SCPoint *)point {
  if (self.longitude != point.longitude) {
    return NO;
  }
  if (self.latitude != point.latitude) {
    return NO;
  }
  if (self.altitude != point.altitude) {
    return NO;
  }
  return YES;
}

- (NSString *)description {
  return [NSString
      stringWithFormat:@"Point[%f,%f,%f]", self.x, self.y, self.z, nil];
}

- (BOOL)checkWithin:(SCBoundingBox *)bbox {
  return [bbox pointWithin:self];
}

- (SCSimplePoint *)centroid {
  return [[SCSimplePoint alloc] initWithX:self.x Y:self.y];
}

@end
