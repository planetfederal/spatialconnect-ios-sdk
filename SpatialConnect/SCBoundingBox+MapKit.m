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

#import "SCBoundingBox+MapKit.h"
#import "SCPoint+MapKit.h"

@implementation SCBoundingBox (MapKit)

- (MKMapRect)asMKMapRect {
  CLLocationCoordinate2D ur = CLLocationCoordinate2DMake(
      self.upperRight.latitude, self.upperRight.longitude);
  CLLocationCoordinate2D ll = CLLocationCoordinate2DMake(
      self.lowerLeft.latitude, self.lowerLeft.longitude);
  MKMapPoint upperRight = MKMapPointForCoordinate(ur);
  MKMapPoint lowerLeft = MKMapPointForCoordinate(ll);

  return MKMapRectMake(lowerLeft.x, upperRight.y,
                       fabs(upperRight.x - lowerLeft.x),
                       fabs(upperRight.y - lowerLeft.y));
}

@end
