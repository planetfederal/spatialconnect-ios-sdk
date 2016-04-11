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
#import "SCLoggingAssertionHandler.h"
#import "SCNetworkService.h"
#import "SpatialConnect.h"
#import "SCLocalConfig.h"

@interface SpatialConnect ()

- (void)startAssertionHandler;

@end

@implementation SpatialConnect

@synthesize services = _services;
@synthesize dataService = _dataService;
@synthesize networkService = _networkService;
@synthesize sensorService = _sensorService;
@synthesize rasterService = _rasterService;
@synthesize configService = _configService;
@synthesize kvpService = _kvpService;

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
    bus = [RACSubject new];
    _kvpService = [SCKVPService new];
    [self createConfigService];
    [self initServices];
    [self startAssertionHandler];
  }
  return self;
}

- (void)createConfigService {
  RACSignal *configSignal = [bus filter:^BOOL(SCMessage *m) {
    if ([m.serviceIdentifier isEqualToString:@"CONFIG_SERVICE"]) {
      return YES;
    }
    return NO;
  }];
  _configService = [[SCConfigService alloc] initWithSignal:configSignal];
}

- (void)initServices {
  _services = [[NSMutableDictionary alloc] init];
  _dataService = [SCDataService new];
  _networkService = [SCNetworkService new];
  _sensorService = [SCSensorService new];
  _rasterService = [SCRasterService new];
  [self addDefaultServices];
}

- (void)addDefaultServices {
  [self addService:self.kvpService];
  //Config services relies on the keyvalue service
  //Order matters here
  [self addService:self.configService];
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

- (SCService*)serviceById:(NSString*)ident {
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
  [self.services enumerateKeysAndObjectsUsingBlock:^(NSString* k, SCService *s, BOOL *stop) {
    [s start];
  }];
  [self loadLocalConfigs];
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

- (void)addConfigFilepath:(NSString *)fp {
  [filepaths addObject:fp];
}

- (void)addConfigFilepaths:(NSArray*)fps {
  [filepaths addObjectsFromArray:fps];
}

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
    [filepaths
     addObject:[NSString stringWithFormat:@"%@/%@", path, cfgFileName]];
  }];
}

- (void)loadLocalConfigs {
  [filepaths enumerateObjectsUsingBlock:^(NSString *fp, NSUInteger idx,
                                            BOOL *_Nonnull stop) {
    NSError *error;
    NSDictionary *cfg = [SCFileUtils jsonFileToDict:fp error:&error];
    if (error) {
      NSLog(@"%@",error.description);
    }
    SCLocalConfig *lcfg = [[SCLocalConfig alloc] initWithDictionary:cfg];
    [[lcfg messages] enumerateObjectsUsingBlock:^(SCMessage *m, NSUInteger idx, BOOL *stop) {
      m.serviceIdentifier = @"CONFIG_SERVICE";
      m.action = SCACTION_DATASERVICE_ADDSTORE;
      [bus sendNext:m];
    }];
  }];
}

@end
