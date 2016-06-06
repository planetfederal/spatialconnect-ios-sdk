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


#import "SpatialConnect.h"
#import "SCSensorService.h"

@interface SCSensorService ()

@property (nonatomic) CLLocationDistance distance;
@property (nonatomic) CLLocationAccuracy accuracy;
@property (nonatomic) BOOL isTracking;
@property (nonatomic) RACSignal *lastKnown;

-(void)startLocationManager;
-(void)stopLocationManager;
-(BOOL)shoudlEnableGPS;

@end

@implementation SCSensorService

#define GPS_ENABLED @"service.sensor.gps.enabled"

@synthesize distance,accuracy;
@synthesize lastKnown = _lastKnown;

-(instancetype)init {
    self = [super init];
    if (!self) return nil;
    self.distance = kCLDistanceFilterNone;
    self.accuracy = kCLLocationAccuracyBest;
    self.isTracking = NO;
    return self;
}

-(void)start {
    [super start];
    if (!locationManager) {
        locationManager = [CLLocationManager new];
        locationManager.delegate = self;
    }
    
    if ([CLLocationManager locationServicesEnabled]) {
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
            [locationManager requestAlwaysAuthorization];
        }
        
        if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied
            && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusRestricted) {
            [self startLocationManager];
        }
    } else {
        NSLog(@"Please Enable Location Services");
    }
    
    [self setupSignals];
}

-(void)setupSignals {
    self.lastKnown = [[self rac_signalForSelector:@selector(locationManager:didUpdateLocations:) fromProtocol:@protocol(CLLocationManagerDelegate)] map:^id(RACTuple *tuple) {
            return [(NSArray*)tuple.second lastObject];
    }];
}

-(void)stop {
    [super stop];
    if (locationManager) {
        [self stopLocationManager];
        locationManager = nil;
        locationManager.delegate = nil;
    }
}

-(void)resume {
    [super resume];
    [self shoudlEnableGPS];
}

-(void)pause {
    [super pause];
    [self stopLocationManager];
}

-(void)enableGPS {
  if (self.status != SC_SERVICE_RUNNING) {
    [self start];
  }
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  SCKVPStore *kvp = sc.kvpService.kvpStore;
  [kvp putValue:@(YES) forKey:GPS_ENABLED];
  [self startLocationManager];
}

-(void)disableGPS {
  [self stopLocationManager];
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  SCKVPStore *kvp = sc.kvpService.kvpStore;
  [kvp putValue:@(NO) forKey:GPS_ENABLED];
}

-(BOOL)shoudlEnableGPS {
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  SCKVPStore *kvp = sc.kvpService.kvpStore;
  NSNumber *enabled = (NSNumber*)[kvp valueForKey:GPS_ENABLED];
  if ([(NSNumber*)enabled isEqual:@(YES)]) {
    return YES;
  } else {
    return NO;
  }
}

-(void)startLocationManager {
    locationManager.desiredAccuracy = self.accuracy;
    locationManager.distanceFilter = self.distance;
    if ([CLLocationManager locationServicesEnabled]) {
        [locationManager startUpdatingLocation];
        [locationManager startUpdatingHeading];
        self.isTracking = YES;
    }
}

-(void)stopLocationManager {
    [locationManager stopUpdatingHeading];
    [locationManager stopUpdatingLocation];
    self.isTracking = NO;
}

-(void)locationAccuracy:(CLLocationAccuracy)acc withDistance:(CLLocationDistance)dist {
    self.accuracy = accuracy;
    self.distance = distance;
    [self startLocationManager];
}

@end
