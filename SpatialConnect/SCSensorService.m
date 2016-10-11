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

#import "SCSensorService.h"
#import "JSONKit.h"
#import "Reachability.h"
#import "SCPoint.h"
#import "Scmessage.pbobjc.h"
#import "SpatialConnect.h"

static NSString *const kSERVICENAME = @"SC_SENSOR_SERVICE";

@interface SCSensorService ()

@property(nonatomic) CLLocationDistance distance;
@property(nonatomic) CLLocationAccuracy accuracy;
@property(nonatomic) BOOL isTracking;
@property(nonatomic) RACSignal *lastKnown;
@property RACSignal *isConnectedViaWifi;
@property RACSignal *isConnectedViaWAN;
@property RACSignal *isConnected;

- (void)startLocationManager;
- (void)stopLocationManager;
- (BOOL)shoudlEnableGPS;

@end

@implementation SCSensorService

#define GPS_ENABLED @"service.sensor.gps.enabled"

@synthesize distance, accuracy;
@synthesize lastKnown = _lastKnown;
@synthesize isConnectedViaWAN = _isConnectedViaWAN;
@synthesize isConnectedViaWifi = _isConnectedViaWifi;
@synthesize isConnected = _isConnected;

- (instancetype)init {
  self = [super init];
  if (!self)
    return nil;
  self.distance = kCLDistanceFilterNone;
  self.accuracy = kCLLocationAccuracyBest;
  self.isTracking = NO;
  return self;
}

- (RACSignal *)start {
  [super start];
  if (!locationManager) {
    locationManager = [CLLocationManager new];
    locationManager.delegate = self;
  }

  if ([CLLocationManager locationServicesEnabled]) {
    if ([CLLocationManager authorizationStatus] ==
        kCLAuthorizationStatusNotDetermined) {
      [locationManager requestAlwaysAuthorization];
    }

    if ([CLLocationManager authorizationStatus] !=
            kCLAuthorizationStatusDenied &&
        [CLLocationManager authorizationStatus] !=
            kCLAuthorizationStatusRestricted) {
      [self startLocationManager];
    }
  } else {
    NSLog(@"Please Enable Location Services");
  }

  [self setupSignals];
  return [RACSignal empty];
}

- (void)setupSignals {
  self.lastKnown = [[
      [self rac_signalForSelector:@selector(locationManager:didUpdateLocations:)
                     fromProtocol:@protocol(CLLocationManagerDelegate)]
      sample:[RACSignal interval:5.0
                     onScheduler:[RACScheduler currentScheduler]]]
      map:^SCPoint *(RACTuple *tuple) {
        CLLocation *loc = [(NSArray *)tuple.second lastObject];
        CLLocationDistance alt = loc.altitude;
        float lat = loc.coordinate.latitude;
        float lon = loc.coordinate.longitude;
        SCPoint *p = [[SCPoint alloc]
            initWithCoordinateArray:@[ @(lon), @(lat), @(alt) ]];
        return p;
      }];

  Reachability *reach = [Reachability reachabilityForInternetConnection];

  reach.reachableBlock = ^(Reachability *r) {
    [isReachableSubject sendNext:r];
  };

  reach.unreachableBlock = ^(Reachability *r) {
    [isReachableSubject sendNext:r];
  };

  isReachableSubject =
      [RACBehaviorSubject behaviorSubjectWithDefaultValue:reach];

  self.isConnected = [isReachableSubject map:^NSNumber *(Reachability *r) {
    return @(r.isReachable);
  }];

  self.isConnectedViaWAN =
      [isReachableSubject map:^NSNumber *(Reachability *r) {
        return @(r.isReachableViaWWAN);
      }];

  self.isConnectedViaWifi =
      [isReachableSubject map:^NSNumber *(Reachability *r) {
        return @(r.isReachableViaWiFi);
      }];

  [reach startNotifier];
}

- (void)stop {
  [super stop];
  if (locationManager) {
    [self stopLocationManager];
    locationManager = nil;
    locationManager.delegate = nil;
  }
}

- (void)resume {
  [super resume];
  [self shoudlEnableGPS];
}

- (void)pause {
  [super pause];
  [self stopLocationManager];
}

- (void)enableGPS {
  if (self.status != SC_SERVICE_RUNNING) {
    [self start];
  }
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  SCKVPStore *kvp = sc.kvpService.kvpStore;
  [kvp putValue:@(YES) forKey:GPS_ENABLED];
  [self startLocationManager];

  [[self.lastKnown flattenMap:^RACStream *(SCPoint *p) {
    return [sc.dataService.locationStore create:p];
  }] subscribeNext:^(id x) {
    NSLog(@"Location sent to Location Store");
  }];
}

- (void)disableGPS {
  [self stopLocationManager];
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  SCKVPStore *kvp = sc.kvpService.kvpStore;
  [kvp putValue:@(NO) forKey:GPS_ENABLED];
}

- (BOOL)shoudlEnableGPS {
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  SCKVPStore *kvp = sc.kvpService.kvpStore;
  NSNumber *enabled = (NSNumber *)[kvp valueForKey:GPS_ENABLED];
  if ([(NSNumber *)enabled isEqual:@(YES)]) {
    return YES;
  } else {
    return NO;
  }
}

- (void)startLocationManager {
  locationManager.desiredAccuracy = self.accuracy;
  locationManager.distanceFilter = self.distance;
  if ([CLLocationManager locationServicesEnabled]) {
    [locationManager startUpdatingLocation];
    [locationManager startUpdatingHeading];
    self.isTracking = YES;
  }
}

- (void)stopLocationManager {
  [locationManager stopUpdatingHeading];
  [locationManager stopUpdatingLocation];
  self.isTracking = NO;
}

- (void)locationAccuracy:(CLLocationAccuracy)acc
            withDistance:(CLLocationDistance)dist {
  self.accuracy = accuracy;
  self.distance = distance;
  [self startLocationManager];
}

+ (NSString *)serviceId {
  return kSERVICENAME;
}

@end
