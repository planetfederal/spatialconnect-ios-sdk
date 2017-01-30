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
@property(readwrite, atomic, strong) SCServiceGraph *serviceGraph;
@end

@implementation SpatialConnect

@synthesize serviceGraph = _serviceGraph;
@synthesize serviceEventSubject = _serviceEventSubject;
@synthesize cache = _cache;
@synthesize serviceEvents = _serviceEvents;
@synthesize sensorService = _sensorService;
@synthesize dataService = _dataService;
@synthesize configService = _configService;
@synthesize authService = _authService;
@synthesize backendService = _backendService;
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
    _cache = [SCCache new];
    _serviceEventSubject = [RACSubject new];
    _serviceEvents = [self.serviceEventSubject publish];
    _serviceGraph = [SCServiceGraph new];
    _sensorService = [SCSensorService new];
    _dataService = [SCDataService new];
    _configService = [SCConfigService new];
    [self addDefaultServices];
    [self setupLogger];
  }
  return self;
}

- (void)addDefaultServices {
  [self addService:self.sensorService];
  [self addService:self.dataService];
  [self addService:self.configService];
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
  [_serviceGraph addService:service];
}

- (void)removeService:(NSString *)serviceId {
  [_serviceGraph removeService:serviceId];
}

- (SCService *)serviceById:(NSString *)ident {
  return [_serviceGraph nodeById:ident];
}

- (void)startService:(NSString *)serviceId {
  [[_serviceGraph startService:serviceId] subscribeError:^(NSError *error) {
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
  [_serviceGraph stopService:serviceId];
}

- (void)restartService:(NSString *)serviceId {
  //TODO
//  SCService *service = [self.services objectForKey:serviceId];
//  [service stop];
//  [service start];
}

- (void)startAllServices {
  [[_serviceGraph startAllServices] subscribeError:^(NSError *error) {
    DDLogError(@"%@",error.localizedDescription);
  }
                                         completed:^{
                                           DDLogInfo(@"Services Started");
                                         }];
}

- (void)stopAllServices {
  [_serviceGraph stopAllServices];
}

- (void)restartAllServices {
  [_serviceGraph stopAllServices];
  [_serviceGraph startAllServices];
}

- (void)connectBackend:(SCRemoteConfig *)r {
  if (![_serviceGraph nodeById:[SCBackendService serviceId]]) {
    [self addService:[[SCBackendService alloc] initWithRemoteConfig:r]];
    [self startService:[SCBackendService serviceId]];
  } else {
    DDLogWarn(@"SCBackendService Already Connected");
  }
}

- (void)connectAuth:(id<SCAuthProtocol>)ap {
  if (![_serviceGraph nodeById:[SCAuthService serviceId]]) {
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
