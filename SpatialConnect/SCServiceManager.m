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

#import "SCDataService.h"
#import "SCDataStore.h"
#import "SCFileUtils.h"
#import "SCServiceManager.h"
#import "SCStoreConfig.h"

#import <ReactiveCocoa/RACSequence.h>

@interface SCServiceManager ()
- (void)addDefaultServices;
@end

@implementation SCServiceManager

@synthesize services = _services;
@synthesize dataService = _dataService;
@synthesize networkService = _networkService;
@synthesize sensorService = _sensorService;
@synthesize rasterService = _rasterService;
@synthesize configService = _configService;

- (id)init {
  if (self = [super init]) {
    _configService = [[SCConfigService alloc] init];
    [self initServices];
  }
  return self;
}

- (instancetype)initWithFilepath:(NSString *)filepath {
  self = [super init];
  if (self) {
    _configService = [[SCConfigService alloc] initWithFilepath:filepath];
    [self initServices];
  }
  return self;
}

- (instancetype)initWithFilepaths:(NSArray *)filepaths {
  self = [super init];
  if (self) {
    _configService = [[SCConfigService alloc] initWithFilepaths:filepaths];
    [self initServices];
  }
  return self;
}

// Class store = [self.dataService
//               supportedStoreByKey:[NSString stringWithFormat:@"%@.%ld",
//               cfg.type,
//                                    (long)cfg.version]];
// SCDataStore *gmStore = [[store alloc] initWithStoreConfig:cfg];
// if (gmStore.key) {
//  [self.dataService registerStore:gmStore];
//}

- (void)initServices {
  _services = [[NSMutableDictionary alloc] init];
  _dataService = [[SCDataService alloc] init];
  _networkService = [[SCNetworkService alloc] init];
  _sensorService = [[SCSensorService alloc] init];
  _rasterService = [[SCRasterService alloc] init];
  [self addDefaultServices];
}

- (void)addDefaultServices {
  [self addService:self.dataService];
  [self addService:self.networkService];
  [self addService:self.sensorService];
  [self addService:self.rasterService];
  [self addService:self.configService];
}

#pragma mark - Service Lifecycle

- (void)addService:(SCService *)service {
  [self.services setObject:service forKey:[service identifier]];
}

- (void)removeService:(NSString *)serviceId {
  [self.services removeObjectForKey:serviceId];
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
  [[[self.configService load] filter:^BOOL(RACTuple *t) {
    SCConfigEvent evt = (SCConfigEvent)[t.first integerValue];
    return evt == SC_CONFIG_DATASERVICE_STORE_ADDED;
  }] subscribeNext:^(RACTuple *t) {
    SCStoreConfig *cfg = (SCStoreConfig *)t.second;
    Class store = [self.dataService
        supportedStoreByKey:[NSString stringWithFormat:@"%@.%ld", cfg.type,
                                                       (long)cfg.version]];
    SCDataStore *gmStore = [[store alloc] initWithStoreConfig:cfg];
    if (gmStore.key) {
      [self.dataService registerStore:gmStore];
    }
  }
      error:^(NSError *error) {
        NSLog(@"%@", error.description);
      }
      completed:^{
        for (SCService *service in [self.services allValues]) {
          [service start];
        }
      }];
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
