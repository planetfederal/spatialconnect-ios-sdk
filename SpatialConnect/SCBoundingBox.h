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
#import "SCPolygon.h"
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class SCPoint;

@interface SCBoundingBox : NSObject

@property(strong, nonatomic) SCPoint *lowerLeft;
@property(strong, nonatomic) SCPoint *upperRight;
@property(nonatomic) NSInteger crs;

+ (instancetype)worldBounds;

- (id)initWithCoords:(NSArray *)coords;
- (id)initWithCoords:(NSArray *)coords crs:(NSInteger)c;
- (id)initWithPoints:(NSArray *)points crs:(NSInteger)c;
- (void)addPoint:(SCPoint *)pt;
- (void)addPoints:(NSArray *)pts;
- (BOOL)pointWithin:(SCPoint *)pt;
- (BOOL)geometryWithin:(SCGeometry *)g;
- (BOOL)bboxOverlaps:(SCBoundingBox *)obbox;
- (NSDictionary *)JSONDict;
- (SCPolygon *)polygon;

@end
