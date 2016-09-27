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

#import "SCService.h"
#import "Reachability.h"
#import <Foundation/Foundation.h>
#import <ReactiveCocoa/RACSignal.h>
#import <CoreLocation/CoreLocation.h>

typedef enum : NSUInteger {
  SC_LOCATION_HIGH = 0,
  SC_LOCATION_NAVIGATION = 1,
  SC_LOCATION_LOW = 3
} SCLocationAccuracy;

@interface SCSensorService : SCService <CLLocationManagerDelegate> {
  __strong CLLocationManager *locationManager;
  CLLocationDistance distance;
  CLLocationAccuracy accuracy;
  RACBehaviorSubject *isReachableSubject;
}

@property(nonatomic, readonly) BOOL isTracking;
@property(nonatomic, retain) NSArray *location;
@property(nonatomic, readonly) RACSignal *lastKnown;
@property(nonatomic, readonly) RACSignal *isConnected;
@property(nonatomic, readonly) RACSignal *isConnectedViaWifi;
@property(nonatomic, readonly) RACSignal *isConnectedViaWAN;

- (void)locationAccuracy:(CLLocationAccuracy)accuracy
            withDistance:(CLLocationDistance)distance;

- (void)enableGPS;
- (void)disableGPS;

@end
