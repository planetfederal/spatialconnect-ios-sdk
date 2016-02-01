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

#import "SCServiceManager.h"
#import "SCStoreConfig.h"
#import "SCFileUtils.h"
#import "SCDataStore.h"
#import "SCDataService.h"

#import <ReactiveCocoa/RACSequence.h>

@interface SCServiceManager ()

- (void)addDefaultServices;
- (void)loadConfig:(NSString *)filepath;
- (void)sweepDataDirectory;

@end

@implementation SCServiceManager

@synthesize services = _services;
@synthesize dataService = _dataService;
@synthesize networkService = _networkService;
@synthesize sensorService = _sensorService;
@synthesize rasterService = _rasterService;

- (id)init {
  if (self = [super init]) {
    _services = [[NSMutableDictionary alloc] init];
    _dataService = [[SCDataService alloc] init];
    _networkService = [[SCNetworkService alloc] init];
    _sensorService = [[SCSensorService alloc] init];
    _rasterService = [[SCRasterService alloc] init];
    [self addDefaultServices];
    [self sweepDataDirectory];
  }
  return self;
}

- (instancetype)initWithFilepath:(NSString *)filepath {
  self = [self init];
  if (!self) {
    return nil;
  }
  [self loadConfig:filepath];
  return self;
}

- (instancetype)initWithFilepaths:(NSArray *)filepaths {
  self = [self init];
  if (!self) {
    return nil;
  }
  [filepaths enumerateObjectsUsingBlock:^(NSString *filepath, NSUInteger idx,
                                          BOOL *stop) {
    [self loadConfig:filepath];
  }];
  return self;
}

#pragma mark - Private

- (void)sweepDataDirectory {
  NSString *path = [NSSearchPathForDirectoriesInDomains(
      NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  NSArray *dirs =
      [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path
                                                          error:NULL];

  [[[dirs.rac_sequence filter:^BOOL(NSString *filename) {
    if ([filename.pathExtension.lowercaseString isEqualToString:@"scfg"]) {
      return YES;
    } else {
      return NO;
    }
  }] signal] subscribeNext:^(NSString *cfgFileName) {
    [self loadConfig:[NSString stringWithFormat:@"%@/%@", path, cfgFileName]];
  }];
}

- (void)loadConfig:(NSString *)filepath {
  NSError *error;
  NSDictionary *cfg = [SCFileUtils jsonFileToDict:filepath error:&error];
  if (error) {
    return;
  }

  for (NSDictionary *dict in cfg[@"stores"]) {
    SCStoreConfig *cfg = [[SCStoreConfig alloc] initWithDictionary:dict];
    Class store = [self.dataService
        supportedStoreByKey:[NSString stringWithFormat:@"%@.%ld", cfg.type,
                                                       (long)cfg.version]];
    SCDataStore *gmStore = [[store alloc] initWithStoreConfig:cfg];
    if (gmStore.key) {
      [self.dataService registerStore:gmStore];
    }
  }
}

- (void)addDefaultServices {
  [self addService:self.dataService];
  [self addService:self.networkService];
  [self addService:self.sensorService];
  [self addService:self.rasterService];
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
  for (SCService *service in [self.services allValues]) {
    [service start];
  }
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
