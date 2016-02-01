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




#import "SCLineString+MapKit.h"
#import "SCPoint+MapKit.h"
#import "SCBoundingBox+MapKit.h"

@implementation SCLineString (MapKit)

- (MKPolyline*) shape {
    CLLocationCoordinate2D coords[self.points.count];
    int caIndex = 0;
    for (SCPoint *p in self.points) {
        coords[caIndex] = CLLocationCoordinate2DMake(p.latitude,p.longitude);
        caIndex++;
    }

    MKPolyline *poly = [MKPolyline polylineWithCoordinates:coords count:self.points.count];
    return poly;
}

- (CLLocationCoordinate2D)coordinate {
    __block float x = 0;
    __block float y = 0;
    [self.points enumerateObjectsUsingBlock:^(SCPoint* p, NSUInteger idx, BOOL *stop) {
        x += p.x;
        y += p.y;
    }];
    return CLLocationCoordinate2DMake(y/self.points.count, x/self.points.count);
}

- (MKMapRect)boundingMapRect {
    return self.bbox.asMKMapRect;
}

- (void)addToMap:(MKMapView *)mapview {
    [mapview addOverlay:self];
}

@end
