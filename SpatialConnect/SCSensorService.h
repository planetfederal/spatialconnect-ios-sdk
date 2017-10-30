/*!***************************************************************************
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

#import "Reachability.h"
#import "SCDataService.h"
#import "SCService.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <ReactiveCocoa/RACSignal.h>

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
  SCDataService *dataService;
}

/*!
 BOOL for location updates being active
 */
@property(nonatomic, readonly) BOOL isTracking;

/*!
 Last known location of the device emiting SCPoint over an Observable
 */
@property(nonatomic, readonly) RACSignal *lastKnown;

/*!
 Behavior subject return YES for Internet access, NO for offline
 */
@property(nonatomic, readonly) RACBehaviorSubject *isConnected;

/*!
 Behavior subject return YES for Wifi access, NO for no Wifi connectivity
 */
@property(nonatomic, readonly) RACBehaviorSubject *isConnectedViaWifi;

/*!
 Behavior subject return YES for WAN access, NO for no WAN connectivity
 */
@property(nonatomic, readonly) RACBehaviorSubject *isConnectedViaWAN;

- (void)locationAccuracy:(CLLocationAccuracy)accuracy
            withDistance:(CLLocationDistance)distance;

/*!
 Turns on location updates
 */
- (void)enableGPS;

/*!
 Turns off location updates
 */
- (void)disableGPS;

@end
