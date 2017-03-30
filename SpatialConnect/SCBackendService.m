/**
 * Copyright 2016 Boundless http://boundlessgeo.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License
 */

#import "ConnectMessage.pbobjc.h"
#import "SCBackendService.h"
#import "Commands.h"
#import "JSONKit.h"
#import "SCConfig.h"
#import "SCNotification.h"
#import "SpatialConnect.h"

static NSString *const kBackendServiceName = @"SC_BACKEND_SERVICE";
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)                             \
  ([[[UIDevice currentDevice] systemVersion]                                   \
       compare:v                                                               \
       options:NSNumericSearch] != NSOrderedAscending)

@interface SCBackendService ()
@property(nonatomic, readwrite, strong) RACSignal *notifications;
- (void)subscribeToTopic:(NSString *)topic;
- (void)connect;
- (void)registerForLocalNotifications;
- (void)createNotification:(SCNotification *)notification;
- (NSString *)jwt;
@end

@implementation SCBackendService

@synthesize notifications;
@synthesize backendUri = _backendUri;
@synthesize configReceived = _configReceived;
@synthesize connectedToBroker;

- (id)initWithRemoteConfig:(SCRemoteConfig *)cfg {
  self = [super init];
  if (self) {
    httpProtocol = cfg.httpProtocol;
    httpEndpoint = cfg.httpHost;
    httpPort = cfg.httpPort;
    mqttEndpoint = cfg.mqttHost;
    mqttPort = cfg.mqttPort;
    mqttProtocol = cfg.mqttProtocol;
    _backendUri = cfg.httpUri;
    _configReceived =
        [RACBehaviorSubject behaviorSubjectWithDefaultValue:@(NO)];
    connectedToBroker =
        [RACBehaviorSubject behaviorSubjectWithDefaultValue:@(NO)];
  }
  return self;
}

- (BOOL)start:(NSDictionary<NSString *, id<SCServiceLifecycle>> *)deps {
  authService = [deps objectForKey:[SCAuthService serviceId]];
  configService = [deps objectForKey:[SCConfigService serviceId]];
  sensorService = [deps objectForKey:[SCSensorService serviceId]];
  dataService = [deps objectForKey:[SCDataService serviceId]];
  DDLogInfo(@"Starting Backend Service...");
  [self listenForNetworkConnection];
  //[self registerForLocalNotifications];
  DDLogInfo(@"Backend Service Started");
  return [super start:nil];
}

- (BOOL)stop {
  if (sessionManager) {
    [sessionManager disconnect];
  }
  return [super stop];
}

- (NSArray *)requires {
  return @[
    [SCAuthService serviceId], [SCConfigService serviceId],
    [SCSensorService serviceId], [SCDataService serviceId]
  ];
}

- (void)registerForLocalNotifications {
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
    UNUserNotificationCenter *center =
        [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound |
                                             UNAuthorizationOptionAlert |
                                             UNAuthorizationOptionBadge)
                          completionHandler:^(BOOL granted,
                                              NSError *_Nullable error) {

                          }];
  } else {
    [[UIApplication sharedApplication]
        registerUserNotificationSettings:
            [UIUserNotificationSettings
                settingsForTypes:UIUserNotificationTypeAlert |
                                 UIUserNotificationTypeBadge |
                                 UIUserNotificationTypeSound
                      categories:nil]];
  }
}

- (void)setupSubscriptions {

  NSString *ident = [[SpatialConnect sharedInstance] deviceIdentifier];
  self.notifications = [[[self listenOnTopic:@"/notify"]
      merge:[self
                listenOnTopic:[NSString stringWithFormat:@"/notify/%@", ident]]]
      map:^id(ConnectMessage *m) {
        return [[SCNotification alloc] initWithMessage:m];
      }];

  [self.notifications subscribeNext:^(SCNotification *notification) {
    [self createNotification:notification];
  }];

  [[self listenOnTopic:@"/config/update"] subscribeNext:^(ConnectMessage *msg) {
    NSString *payload = msg.payload;
    SCConfig *cachedConfig = configService.cachedConfig;
    switch (msg.command) {
    case CONFIG_ADD_STORE: {
      NSDictionary *json = [payload objectFromJSONString];
      SCStoreConfig *config = [[SCStoreConfig alloc] initWithDictionary:json];
      [cachedConfig addStore:config];
      [dataService registerAndStartStoreByConfig:config];
      break;
    }
    case CONFIG_UPDATE_STORE: {
      NSDictionary *json = [payload objectFromJSONString];
      SCStoreConfig *config = [[SCStoreConfig alloc] initWithDictionary:json];
      [cachedConfig updateStore:config];
      [dataService updateStoreByConfig:config];
      break;
    }
    case CONFIG_REMOVE_STORE: {
      NSDictionary *json = [payload objectFromJSONString];
      NSString *storeid = [json objectForKey:@"id"];
      SCDataStore *ds = [dataService storeByIdentifier:storeid];
      [cachedConfig removeStore:storeid];
      [dataService unregisterStore:ds];
      break;
    }
    case CONFIG_ADD_FORM: {
      SCFormConfig *f =
          [[SCFormConfig alloc] initWithDict:[payload objectFromJSONString]];
      if (f) {
        [cachedConfig addForm:f];
        [dataService.formStore registerFormByConfig:f];
      }
      break;
    }
    case CONFIG_UPDATE_FORM: {
      SCFormConfig *f =
          [[SCFormConfig alloc] initWithDict:[payload objectFromJSONString]];
      if (f) {
        [cachedConfig updateForm:f];
        [dataService.formStore updateFormByConfig:f];
      }
      break;
    }
    case CONFIG_REMOVE_FORM: {
      NSDictionary *json = [payload objectFromJSONString];
      NSString *formKey = [json objectForKey:@"form_key"];
      [cachedConfig removeForm:formKey];
      [dataService.formStore unregisterFormByKey:formKey];
      break;
    }
    default:
      break;
    }
    [configService setCachedConfig:cachedConfig];
  }];
}

/**
 Registers the mobile device's identifier and retrieves the config for the
 device. The identifier is sent and the server will filter for only
 configuration specific to this user/device.
 */
- (void)registerAndFetchConfig {

  NSDictionary *regDict = @{
    @"identifier" : [[SpatialConnect sharedInstance] deviceIdentifier],
    @"device_info" : @{@"os" : @"ios"},
    @"name" : [NSString stringWithFormat:@"mobile:%@", [authService username]]
  };
  ConnectMessage *regMsg = [[ConnectMessage alloc] init];
  regMsg.command = CONFIG_REGISTER_DEVICE;
  regMsg.payload = [regDict JSONString];
  [self publishExactlyOnce:regMsg onTopic:@"/config/register"];
  ConnectMessage *cMsg = [ConnectMessage new];
  cMsg.command = CONFIG_FULL;
  [[self publishReplyTo:cMsg onTopic:@"/config"] subscribeNext:^(ConnectMessage *m) {
    NSString *json = m.payload;
    NSDictionary *dict = [json objectFromJSONString];
    SCConfig *cfg = [[SCConfig alloc] initWithDictionary:dict];
    [configService loadConfig:cfg];
    [configService setCachedConfig:cfg];
    [_configReceived sendNext:@(YES)];
  }];
}

- (NSString *)jwt {
  return [authService xAccessToken];
}

- (void)connect {

  if (!sessionManager) {

    NSString *ident = [[SpatialConnect sharedInstance] deviceIdentifier];
    NSString *token = [authService xAccessToken];
    sessionManager = [[MQTTSessionManager alloc] init];

    MQTTSSLSecurityPolicy *policy = [MQTTSSLSecurityPolicy defaultPolicy];
    policy.allowInvalidCertificates = NO;
    policy.validatesCertificateChain = NO;
    policy.validatesDomainName = NO;

    dispatch_async(dispatch_get_main_queue(), ^{
      [sessionManager
               connectTo:mqttEndpoint
                    port:mqttPort.integerValue
                     tls:[mqttProtocol isEqualToString:@"tls"]
               keepalive:60
                   clean:true
                    auth:true
                    user:token
                    pass:@"anypass"
                    will:true
               willTopic:[NSString stringWithFormat:@"/device/%@-will", ident]
                 willMsg:[@"offline" dataUsingEncoding:NSUTF8StringEncoding]
                 willQos:MQTTQosLevelExactlyOnce
          willRetainFlag:NO
            withClientId:ident
          securityPolicy:policy
            certificates:nil];
    });

    RACSignal *d =
        [self rac_signalForSelector:@selector(handleMessage:onTopic:retained:)
                       fromProtocol:@protocol(MQTTSessionManagerDelegate)];

    multicast = [[d publish] autoconnect];
    sessionManager.delegate = (id<MQTTSessionManagerDelegate>)self;

    [[[connectedToBroker filter:^BOOL(NSNumber *v) {
      return v.boolValue;
    }] take:1] subscribeNext:^(id x) {
      [self setupSubscriptions];
    }];

  } else {
    RACSignal *notConnected =
        [[connectedToBroker take:1] filter:^BOOL(NSNumber *value) {
          return !value.boolValue;
        }];
    [notConnected subscribeNext:^(id x) {
      [sessionManager connectToLast];
    }];
  }

  [sessionManager addObserver:self
                   forKeyPath:@"state"
                      options:NSKeyValueObservingOptionInitial |
                              NSKeyValueObservingOptionNew
                      context:nil];
}

- (void)listenForNetworkConnection {
  /*
   * Check for connectivity.
   * If not connected
   *    load the cached config.
   * else if connected
   *    wait for authentication
   */
  [sensorService.isConnected subscribeNext:^(NSNumber *x) {
    BOOL connected = x.boolValue;
    if (connected) {
      [self authListener];
    } else {
      [connectedToBroker sendNext:@(NO)];
      [self loadCachedConfig];
    }
  }];
}

- (void)listenForSyncEvents {
  
  RACSignal *syncableStores = [dataService storesByProtocol:@protocol(SCSyncableStore) onlyRunning:YES];
  
  RACSignal *storeEditSync = [[syncableStores flattenMap:^RACSignal *(SCDataStore *ds) {
    id<SCSyncableStore> ss = (id<SCSyncableStore>)ds;
    RACMulticastConnection *rmcc = [ss storeEdited];
    [rmcc connect];
    return rmcc.signal;
  }] flattenMap:^RACSignal *(SCSpatialFeature *f) {
    SCDataStore *store = [dataService storeByIdentifier:[f storeId]];
    return [self syncStore:store];
  }];
  
  RACSignal *onlineSync = [[connectedToBroker filter:^BOOL(NSNumber *v) {
    return v.boolValue;
  }] flattenMap:^RACSignal *(id value) {
    return [self syncStores];
  }];
  
  RACSignal *sync = [RACSignal merge:@[storeEditSync, onlineSync]];
  
  [[sync subscribeOn:[RACScheduler schedulerWithPriority:RACSchedulerPriorityBackground]]
    subscribeError:^(NSError *error) {
      DDLogError(@"Store syncing error %@", error.localizedFailureReason);
    }
    completed:^{
      DDLogInfo(@"Store syncing complete");
    }];
}

- (RACSignal *)syncStores {
  RACSignal *syncableStores = [dataService storesByProtocol:@protocol(SCSyncableStore) onlyRunning:YES];
  return [syncableStores flattenMap:^RACSignal *(id<SCSyncableStore> store) {
    return [self syncStore:store];
  }];
}

- (RACSignal *)syncStore:(SCDataStore *)ds {
  id<SCSyncableStore> ss = (id<SCSyncableStore>)ds;
  return [ss.unSent flattenMap:^RACSignal *(SCSpatialFeature *f) {
    return [self send:f];
  }];
}

- (RACSignal *)send:(SCSpatialFeature *)feature {
  return [[connectedToBroker take:1] flattenMap:^RACStream *(NSNumber *n) {
    if (n.boolValue) {
      SCDataStore *store = [dataService storeByIdentifier:[feature storeId]];
      id<SCSyncableStore> ss = (id<SCSyncableStore>)store;
      ConnectMessage *msg = [[ConnectMessage alloc] init];
      msg.payload = [[ss generateSendPayload:feature] JSONString];
      [self publishExactlyOnce:msg onTopic:[ss syncChannel]];
      return [ss updateAuditTable:feature];
    } else {
      return [RACSignal empty];
    }
  }];
}

/**
 Load a cached config from SCCache
 */
- (void)loadCachedConfig {
  SCConfig *config = [configService cachedConfig];
  if (config) {
    [configService loadConfig:config];
    [_configReceived sendNext:@(YES)];
  }
}

- (void)authListener {
  // You have the url to the server. Wait for someone to properly
  // authenticate before fetching the config
  RACSignal *authed = [[[authService loginStatus] filter:^BOOL(NSNumber *n) {
    SCAuthStatus s = [n integerValue];
    return s == SCAUTH_AUTHENTICATED;
  }] take:1];

  RACSignal *failedAuth =
      [[[authService loginStatus] filter:^BOOL(NSNumber *n) {
        SCAuthStatus s = [n integerValue];
        return s == SCAUTH_AUTHENTICATION_FAILED;
      }] take:1];

  [[[[[authed flattenMap:^RACSignal*(id x) {
    [self connect];
    return connectedToBroker;
  }] filter:^BOOL(NSNumber *n) {
    return n.boolValue;
  }] flattenMap:^RACSignal*(id x) {
    return _configReceived;
  }] filter:^BOOL(NSNumber *received) {
    return !received.boolValue;
  }] subscribeNext:^(id x) {
    [self registerAndFetchConfig];
    [self listenForSyncEvents];
  }];

  [failedAuth subscribeNext:^(id x) {
    [self loadCachedConfig];
  }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  NSError *err = sessionManager.lastErrorCode;
  switch (sessionManager.state) {
  case MQTTSessionManagerStateClosed:
    [connectedToBroker sendNext:@(NO)];
    DDLogInfo(@"MQTT Closed");
    break;
  case MQTTSessionManagerStateClosing:
    DDLogInfo(@"MQTT Closing");
    break;
  case MQTTSessionManagerStateConnected:
    [connectedToBroker sendNext:@(YES)];
    DDLogInfo(@"MQTT Connected");
    break;
  case MQTTSessionManagerStateConnecting:
    break;
  case MQTTSessionManagerStateError:
    DDLogError(@"Error MQTT COnnection");
    DDLogError(@"Error:%@", err.description);
    break;
  case MQTTSessionManagerStateStarting:
    DDLogInfo(@"Starting MQTT Connection");
    break;
  default:
    break;
  }
}

- (void)publish:(ConnectMessage *)msg onTopic:(NSString *)topic {
  msg.jwt = self.jwt;
  if (sessionManager.state == MQTTSessionManagerStateConnected) {
    [sessionManager sendData:[msg data]
                       topic:topic
                         qos:MQTTQosLevelExactlyOnce
                      retain:NO];
  }
}

- (void)publishAtMostOnce:(ConnectMessage *)msg onTopic:(NSString *)topic {
  msg.jwt = self.jwt;
  if (sessionManager.state == MQTTSessionManagerStateConnected) {
    [sessionManager sendData:[msg data]
                       topic:topic
                         qos:MQTTQosLevelAtMostOnce
                      retain:NO];
  }
}

- (void)publishAtLeastOnce:(ConnectMessage *)msg onTopic:(NSString *)topic {
  msg.jwt = self.jwt;
  if (sessionManager.state == MQTTSessionManagerStateConnected) {
    [sessionManager sendData:[msg data]
                       topic:topic
                         qos:MQTTQosLevelAtLeastOnce
                      retain:NO];
  }
}

- (void)publishExactlyOnce:(ConnectMessage *)msg onTopic:(NSString *)topic {
  msg.jwt = self.jwt;
  if (sessionManager.state == MQTTSessionManagerStateConnected) {
    [sessionManager sendData:[msg data]
                       topic:topic
                         qos:MQTTQosLevelExactlyOnce
                      retain:NO];
  }
}

- (RACSignal *)publishReplyTo:(ConnectMessage *)msg onTopic:(NSString *)topic {
  NSTimeInterval ti = [[NSDate date] timeIntervalSince1970];
  msg.correlationId = @(ti * 1000).intValue;
  msg.to = [NSString
      stringWithFormat:@"/device/%@-replyTo",
                       [[SpatialConnect sharedInstance] deviceIdentifier]];
  msg.jwt = self.jwt;
  if (sessionManager.state == MQTTSessionManagerStateConnected) {
    RACSignal *s = [[multicast map:^ConnectMessage *(RACTuple *t) {
      NSData *d = (NSData *)t.first;
      NSError *err;
      ConnectMessage *m = [[ConnectMessage alloc] initWithData:d error:&err];
      if (err) {
        DDLogError(@"%@", err.description);
      }
      return m;
    }] filter:^BOOL(ConnectMessage *m) {
      if (m.correlationId == msg.correlationId) {
        return YES;
      }
      return NO;
    }];
    [self subscribeToTopic:msg.to];
    [self publish:msg onTopic:topic];
    return s;
  }
  return nil;
}

- (void)subscribeToTopic:(NSString *)topic {
  NSMutableDictionary<NSString *, NSNumber *> *subs = [NSMutableDictionary new];
  [subs setObject:[NSNumber numberWithInt:MQTTQosLevelExactlyOnce]
           forKey:topic];
  sessionManager.subscriptions = subs;
}

- (RACSignal *)listenOnTopic:(NSString *)topic {
  RACSignal *s = [[multicast filter:^BOOL(RACTuple *t) {
    return [[t second] isEqualToString:topic];
  }] map:^ConnectMessage *(RACTuple *t) {
    NSData *d = (NSData *)[t first];
    NSError *err;
    ConnectMessage *msg = [[ConnectMessage alloc] initWithData:d error:&err];
    if (err) {
      DDLogError(@"%@", err.description);
    }
    return msg;
  }];
  [self subscribeToTopic:topic];
  return s;
}

- (void)createNotification:(SCNotification *)notification {
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.title = notification.title;
    content.body = notification.body;
    content.sound = [UNNotificationSound defaultSound];
    UNTimeIntervalNotificationTrigger *trigger =
        [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1
                                                           repeats:NO];
    NSString *identifier = @"UYLLocalNotification";
    UNNotificationRequest *request =
        [UNNotificationRequest requestWithIdentifier:identifier
                                             content:content
                                             trigger:trigger];

    UNUserNotificationCenter *center =
        [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:request
             withCompletionHandler:^(NSError *_Nullable error) {
               if (error != nil) {
                 NSLog(@"Something went wrong: %@", error);
               }
             }];
  } else {
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
    localNotification.alertBody = notification.body;
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    [[UIApplication sharedApplication]
        scheduleLocalNotification:localNotification];
  }
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:
             (void (^)(UNNotificationPresentationOptions options))
                 completionHandler {
  completionHandler(UNAuthorizationOptionSound | UNAuthorizationOptionAlert |
                    UNAuthorizationOptionBadge);
}

+ (NSString *)serviceId {
  return kBackendServiceName;
}
@end
