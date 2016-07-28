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

#import "SCConfig.h"
#import "SCDataService.h"
#import "SCLoggingAssertionHandler.h"
#import "SCNetworkService.h"
#import "SpatialConnect.h"

@interface SpatialConnect ()
- (void)createDeviceIdentifier;
@end

@implementation SpatialConnect

@synthesize services = _services;
@synthesize dataService = _dataService;
@synthesize networkService = _networkService;
@synthesize sensorService = _sensorService;
@synthesize rasterService = _rasterService;
@synthesize configService = _configService;
@synthesize kvpService = _kvpService;
@synthesize authService = _authService;

+ (id)sharedInstance {
  static SpatialConnect *sc;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sc = [[self alloc] init];
  });
  return sc;
}

- (id)init {
  if (self = [super init]) {
    filepaths = [NSMutableArray new];
    _kvpService = [SCKVPService new];
    [self createDeviceIdentifier];
    [self createConfigService];
    [self initServices];
  }
  return self;
}

- (void)createDeviceIdentifier {
  NSString *ident =
      [[NSUserDefaults standardUserDefaults] stringForKey:@"UNIQUE_ID"];
  if (!ident) {
    ident = [[UIDevice currentDevice].identifierForVendor UUIDString];
    [[NSUserDefaults standardUserDefaults] setObject:ident forKey:@"UNIQUE_ID"];
  }
}

- (void)createConfigService {
  _configService = [[SCConfigService alloc] init];
}

- (void)initServices {
  _services = [[NSMutableDictionary alloc] init];
  _dataService = [SCDataService new];
  _networkService = [SCNetworkService new];
  _sensorService = [SCSensorService new];
  _rasterService = [SCRasterService new];
  _authService = [SCAuthService new];
  [self addDefaultServices];
}

- (void)addDefaultServices {
  [self addService:self.kvpService];
  // Config services relies on the keyvalue service
  // Order matters here
  [self addService:self.dataService];
  [self addService:self.configService];
  [self addService:self.networkService];
  [self addService:self.sensorService];
  [self addService:self.rasterService];
  [self addService:self.authService];
}

#pragma mark - Service Lifecycle

- (void)addService:(SCService *)service {
  [self.services setObject:service forKey:[service identifier]];
}

- (void)removeService:(NSString *)serviceId {
  [self.services removeObjectForKey:serviceId];
}

- (SCService *)serviceById:(NSString *)ident {
  return [self.services objectForKey:ident];
}

- (void)startService:(NSString *)serviceId {
  SCService *service = [self.services objectForKey:serviceId];
  [service start];
}

- (void)stopService:(NSString *)serviceId {
  [[self.services objectForKey:serviceId] stop];
}

- (void)restartService:(NSString *)serviceId {
  SCService *service = [self.services objectForKey:serviceId];
  [service stop];
  [service start];
}

- (void)startAllServices {
  [self.kvpService start];
  [self.dataService start];
  [self.configService start];
  [self.networkService start];
  [self.sensorService start];
  [self.rasterService start];
  [self.authService start];
}

- (void)stopAllServices {
  for (SCService *service in [self.services allValues]) {
    [service stop];
  }
}

- (void)restartAllServices {
  [self stopAllServices];
  [self startAllServices];
}

@end
