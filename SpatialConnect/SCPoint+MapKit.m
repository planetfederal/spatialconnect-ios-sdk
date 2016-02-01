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

#import "SCGeometry+MapKit.h"
#import "SCPoint+MapKit.h"

@implementation SCPoint (MapKit)

- (MKPointAnnotation *)shape {
  MKPointAnnotation *p = [MKPointAnnotation new];
  p.coordinate = CLLocationCoordinate2DMake(self.latitude, self.longitude);
  return p;
}

- (void)addToMap:(MKMapView *)mapview {
  [mapview addAnnotation:self];
}

- (CLLocationCoordinate2D)coordinate {
  return CLLocationCoordinate2DMake(self.latitude, self.longitude);
}

+ (instancetype)pointFromCLLocationCoordinate2D:(CLLocationCoordinate2D)coord {
  NSArray *arr = @[ @(coord.longitude), @(coord.latitude) ];
  SCPoint *p = [[SCPoint alloc] initWithCoordinateArray:arr];
  return p;
}

- (NSString *)title {
  return [NSString
      stringWithFormat:@"%@.%@", self.key.layerId, self.key.featureId];
}

- (NSString *)subtitle {
  return self.storeId;
}

- (MKAnnotationView *)createViewAnnotationForMapView:(MKMapView *)mapView
                                          annotation:
                                              (id<MKAnnotation>)annotation {
  MKAnnotationView *returnedAnnotationView = [mapView
      dequeueReusableAnnotationViewWithIdentifier:NSStringFromClass(
                                                      [SCPoint class])];
  if (returnedAnnotationView == nil) {
    returnedAnnotationView = [[MKPinAnnotationView alloc]
        initWithAnnotation:annotation
           reuseIdentifier:NSStringFromClass([SCPoint class])];

    ((MKPinAnnotationView *)returnedAnnotationView).pinTintColor =
        [MKPinAnnotationView greenPinColor];
    ((MKPinAnnotationView *)returnedAnnotationView).animatesDrop = NO;
    ((MKPinAnnotationView *)returnedAnnotationView).canShowCallout = YES;
  }

  return returnedAnnotationView;
}

@end
