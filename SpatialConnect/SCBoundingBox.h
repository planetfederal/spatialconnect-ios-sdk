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





#import <Foundation/Foundation.h>
#import "SCGeometry.h"

@import MapKit;

@class SCPoint;

typedef struct {
  double x;
  double y;
} GMBoundingBoxCorner;

@interface SCBoundingBox : NSObject {
  double
  ll_x,ll_y,ur_x,ur_y;
}

@property (strong,nonatomic) SCPoint *lowerLeft;
@property (strong,nonatomic) SCPoint *upperRight;

+ (instancetype)worldBounds;

- (id)initWithPoints:(NSArray*)points;
- (void)addPoint:(SCPoint*)pt;
- (void)addPoints:(NSArray*)pts;
- (BOOL)pointWithin:(SCPoint*)pt;

@end
