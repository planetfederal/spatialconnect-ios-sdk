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
#import "SCConfig.h"
#import "SCDataService.h"
#import "SCLoggingAssertionHandler.h"
#import "SCService.h"
#import "SCServiceStatusEvent.h"

@interface SpatialConnect ()
@property(readwrite, nonatomic, strong) RACSubject *serviceEventSubject;
@property(readwrite, atomic, strong) NSMutableDictionary *services;
- (void)initialize;
@end

@implementation SpatialConnect

@synthesize services = _services;
@synthesize serviceEventSubject = _serviceEventSubject;
@synthesize cache = _cache;

@synthesize serviceEvents = _serviceEvents;

/**
 This singleton of SpatialConnect is shared across your app.

 @return instance of SC
 */
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
    _cache = [SCCache new];
    [self initialize];
    self.serviceEventSubject = [RACSubject new];
    _serviceEvents = [self.serviceEventSubject publish];
    [self setupLogger];
  }
  return self;
}

- (void)addDefaultServices {
  _services = [[NSMutableDictionary alloc] init];
  [self addService:[SCConfigService new]];
  [self addService:[SCDataService new]];
  [self addService:[SCSensorService new]];
  [self addService:[SCAuthService new]];
}

- (void)setupLogger {
  [DDLog addLogger:[DDTTYLogger sharedInstance]];
  [DDLog addLogger:[DDASLLogger sharedInstance]];
  DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
  fileLogger.rollingFrequency = 60 * 60 * 24;
  fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
  [DDLog addLogger:fileLogger];
}

#pragma mark - Service Lifecycle
- (void)addService:(SCService *)service {
  [self.services setObject:service forKey:[service.class serviceId]];
}

- (void)removeService:(NSString *)serviceId {
  [self.services removeObjectForKey:serviceId];
}

- (SCService *)serviceById:(NSString *)ident {
  return [self.services objectForKey:ident];
}

- (void)startService:(NSString *)serviceId {
  SCService *service = [self.services objectForKey:serviceId];
  [[service start] subscribeError:^(NSError *error) {
    [self.serviceEventSubject
        sendNext:[SCServiceStatusEvent fromEvent:SC_SERVICE_EVT_ERROR
                                  andServiceName:serviceId]];
  }
      completed:^{
        [self.serviceEventSubject
            sendNext:[SCServiceStatusEvent fromEvent:SC_SERVICE_EVT_STARTED
                                      andServiceName:serviceId]];
      }];
}

- (RACSignal *)serviceRunning:(NSString *)serviceId {
  if ([[self serviceById:serviceId] status] == SC_SERVICE_RUNNING) {
    SCServiceStatusEvent *evt =
        [SCServiceStatusEvent fromEvent:SC_SERVICE_EVT_RUNNING
                         andServiceName:serviceId];
    return [RACSignal return:evt];
  }
  RACMulticastConnection *rmcc = self.serviceEvents;
  [rmcc connect];
  return [[rmcc.signal filter:^BOOL(SCServiceStatusEvent *evt) {
    if (evt.status == SC_SERVICE_EVT_RUNNING &&
        [evt.serviceName isEqualToString:serviceId]) {
      return YES;
    }
    return NO;
  }] take:1];
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

- (void)connectBackend:(SCRemoteConfig *)r {
  if (![_services objectForKey:[SCBackendService serviceId]]) {
    [self addService:[[SCBackendService alloc] initWithRemoteConfig:r]];
    [self startService:[SCBackendService serviceId]];
  } else {
    DDLogWarn(@"SCBackendService Already Connected");
  }
}

- (void)connectAuth:(id<SCAuthProtocol>)ap {
  if (![_services objectForKey:[SCAuthService serviceId]]) {
    [self addService:[[SCAuthService alloc] initWithAuthMethod:ap]];
    [self startService:[SCAuthService serviceId]];
  } else {
    DDLogWarn(@"SCAuthService Already Connected");
  }
}

- (NSString *)deviceIdentifier {
  NSString *ident = [[NSUserDefaults standardUserDefaults]
      stringForKey:@"SPATIALCONNECT_UNIQUE_ID"];
  if (!ident) {
    ident = [[UIDevice currentDevice].identifierForVendor UUIDString];
    [[NSUserDefaults standardUserDefaults]
        setObject:ident
           forKey:@"SPATIALCONNECT_UNIQUE_ID"];
  }
  return ident;
}

@end
