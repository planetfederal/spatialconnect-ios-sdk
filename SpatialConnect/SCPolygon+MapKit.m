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




#import "SCPolygon+MapKit.h"
#import "SCPoint+MapKit.h"
#import "SCLinearRing+MapKit.h"
#import "SCGeometry+MapKit.h"
#import "SCBoundingBox+MapKit.h"

@implementation SCPolygon (MapKit)

-(MKPolygon*)shape {
  CLLocationCoordinate2D outerRing[self.points.count];
  CLLocationCoordinate2D *outer = outerRing;
  [self.points enumerateObjectsUsingBlock:^(SCPoint *p,NSUInteger idx, BOOL *stop) {
    outer[idx] = CLLocationCoordinate2DMake(p.latitude, p.longitude);
  }];
  
  NSMutableArray *arr = [NSMutableArray arrayWithCapacity:self.holes.count];
  [self.holes enumerateObjectsUsingBlock:^(SCLinearRing *ring, NSUInteger idx, BOOL *stop) {
    [arr addObject:[ring shape]];
  }];
  
  MKPolygon *polygon = [MKPolygon polygonWithCoordinates:outerRing
                                                   count:self.points.count
                                        interiorPolygons:arr];
  return polygon;
}

-(CLLocationCoordinate2D)coordinate {
  __block float x = 0;
  __block float y = 0;
  [self.points enumerateObjectsUsingBlock:^(SCPoint* p, NSUInteger idx, BOOL *stop) {
    x += p.x;
    y += p.y;
  }];
  return CLLocationCoordinate2DMake(y/self.points.count, x/self.points.count);
}

-(NSUInteger)pointCount {
  return self.points.count;
}

-(MKMapRect)boundinSCapRect {
  return self.bbox.asMKMapRect;
}

-(void)addToMap:(MKMapView *)mapview {
  [mapview addOverlay:self];
}

@end
