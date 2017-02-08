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
@property RACBehaviorSubject *isConnectedViaWifi;
@property RACBehaviorSubject *isConnectedViaWAN;
@property RACBehaviorSubject *isConnected;

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

#pragma mark -
#pragma mark SCServiceLifecyle methods

- (BOOL)start:(NSDictionary<NSString *, id<SCServiceLifecycle>> *)deps {
  DDLogInfo(@"Starting Sensor Service...");
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
    DDLogInfo(@"Please Enable Location Services");
  }

  [self setupSignals];
  DDLogInfo(@"Sensor Service Started");
  return [super start:nil];
}

- (BOOL)stop {
  if (locationManager) {
    [self stopLocationManager];
    locationManager = nil;
    locationManager.delegate = nil;
  }
  return [super stop];
}

- (BOOL)resume {
  [self shoudlEnableGPS];
  return [super resume];
}

- (BOOL)pause {
  [self stopLocationManager];
  return [super pause];
}

- (NSArray *)requires {
  return nil;
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

- (void)enableGPS {
  if (self.status != SC_SERVICE_RUNNING) {
    DDLogInfo(@"SCSensorService not running");
    return;
  }
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  SCCache *c = sc.cache;
  [c setValue:@(YES) forKey:GPS_ENABLED];
  [self startLocationManager];
}

- (void)disableGPS {
  [self stopLocationManager];
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  SCCache *c = sc.cache;
  [c setValue:@(NO) forKey:GPS_ENABLED];
}

- (BOOL)shoudlEnableGPS {
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  SCCache *p = sc.cache;
  NSNumber *enabled = (NSNumber *)[p valueForKey:GPS_ENABLED];
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

// TODO set CE error
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
