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

#import "SCBackendService.h"
#import "Commands.h"
#import "JSONKit.h"
#import "SCConfig.h"
#import "SCNotification.h"
#import "Scmessage.pbobjc.h"
#import "SpatialConnect.h"

static NSString *const kSERVICENAME = @"SC_BACKEND_SERVICE";

@interface SCBackendService ()
@property(nonatomic, readwrite, strong) RACSignal *notifications;
- (void)subscribeToTopic:(NSString *)topic;
- (void)connect;
@end

@implementation SCBackendService

@synthesize notifications;
@synthesize backendUri = _backendUri;
@synthesize configReceived = _configReceived;

- (id)initWithRemoteConfig:(SCRemoteConfig *)cfg {
  self = [super init];
  if (self) {
    httpProtocol = cfg.httpProtocol;
    httpEndpoint = cfg.httpHost;
    httpPort = cfg.httpPort;
    mqttEndpoint = cfg.mqttHost;
    mqttPort = cfg.mqttPort;
    mqttProtocol = cfg.mqttProtocol;
    _backendUri = [NSString
        stringWithFormat:@"%@://%@:%@", httpProtocol, httpEndpoint, httpPort];
    _configReceived =
        [RACBehaviorSubject behaviorSubjectWithDefaultValue:@(NO)];
    connectedToBroker =
        [RACBehaviorSubject behaviorSubjectWithDefaultValue:@(NO)];
  }
  return self;
}

- (RACSignal *)start {
  [super start];
  [self listenForNetworkConnection];
  return [RACSignal empty];
}

- (void)stop {
  if (sessionManager) {
    [sessionManager disconnect];
  }
}

- (void)authListener {
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  SCAuthService *as = sc.authService;
  // You have the url to the server. Wait for someone to properly
  // authenticate before fetching the config
  [[[[as loginStatus] filter:^BOOL(NSNumber *n) {
    SCAuthStatus s = [n integerValue];
    return s == SCAUTH_AUTHENTICATED;
  }] take:1] subscribeNext:^(NSNumber *n) {
    [self connect];
    [[[connectedToBroker filter:^BOOL(NSNumber *n) {
      return n.boolValue;
    }] take:1] subscribeNext:^(id x) {
      [self registerAndFetchConfig];
    }];
  }];
}

- (void)setupSubscriptions {

  NSString *ident = [[SpatialConnect sharedInstance] deviceIdentifier];
  self.notifications = [[[self listenOnTopic:@"/notify"]
      merge:[self
                listenOnTopic:[NSString stringWithFormat:@"/notify/%@", ident]]]
      map:^id(SCMessage *m) {
        return [[SCNotification alloc] initWithMessage:m];
      }];

  [[self listenOnTopic:@"/config/update"] subscribeNext:^(SCMessage *msg) {
    NSString *payload = msg.payload;
    SpatialConnect *sc = [SpatialConnect sharedInstance];
    switch (msg.action) {
    case CONFIG_ADD_STORE: {
      NSDictionary *json = [payload objectFromJSONString];
      SCStoreConfig *config = [[SCStoreConfig alloc] initWithDictionary:json];
      [sc.dataService registerAndStartStoreByConfig:config];
      break;
    }
    case CONFIG_UPDATE_STORE: {
      NSDictionary *json = [payload objectFromJSONString];
      SCStoreConfig *config = [[SCStoreConfig alloc] initWithDictionary:json];
      [sc.dataService updateStoreByConfig:config];
      break;
    }
    case CONFIG_REMOVE_STORE: {
      SCDataStore *ds = [[[SpatialConnect sharedInstance] dataService]
          storeByIdentifier:payload];
      [sc.dataService unregisterStore:ds];
      break;
    }
    case CONFIG_ADD_FORM: {
      SCFormConfig *f =
          [[SCFormConfig alloc] initWithDict:[payload objectFromJSONString]];
      if (f) {
        [sc.dataService.formStore registerFormByConfig:f];
      }
      break;
    }
    case CONFIG_UPDATE_FORM: {
      [sc.dataService.formStore
          updateFormByConfig:[[SCFormConfig alloc]
                                 initWithDict:[payload objectFromJSONString]]];
      break;
    }
    case CONFIG_REMOVE_FORM: {
      [sc.dataService.formStore unregisterFormByKey:payload];
      break;
    }
    default:
      break;
    }
  }];
}

- (void)registerAndFetchConfig {

  NSDictionary *regDict = @{
    @"identifier" : [[SpatialConnect sharedInstance] deviceIdentifier],
    @"device_info" : @{@"os" : @"ios"}
  };
  SCMessage *regMsg = [[SCMessage alloc] init];
  regMsg.action = CONFIG_REGISTER_DEVICE;
  regMsg.payload = [regDict JSONString];
  [self publishExactlyOnce:regMsg onTopic:@"/config/register"];
  SCMessage *cMsg = [SCMessage new];
  cMsg.action = CONFIG_FULL;
  [[self publishReplyTo:cMsg onTopic:@"/config"] subscribeNext:^(SCMessage *m) {
    NSString *json = m.payload;
    NSDictionary *dict = [json objectFromJSONString];
    SCConfig *cfg = [[SCConfig alloc] initWithDictionary:dict];
    [[[SpatialConnect sharedInstance] configService] loadConfig:cfg];
    [_configReceived sendNext:@(YES)];
  }];
}

- (void)connect {

  if (!sessionManager) {

    NSString *ident = [[SpatialConnect sharedInstance] deviceIdentifier];

    sessionManager = [[MQTTSessionManager alloc] init];
    [sessionManager addObserver:self
                     forKeyPath:@"state"
                        options:NSKeyValueObservingOptionInitial |
                                NSKeyValueObservingOptionNew
                        context:nil];

    [sessionManager
             connectTo:mqttEndpoint
                  port:[mqttPort integerValue]
                   tls:NO
             keepalive:60
                 clean:false
                  auth:false
                  user:nil
                  pass:nil
             willTopic:[NSString stringWithFormat:@"/device/%@-will", ident]
                  will:[@"offline" dataUsingEncoding:NSUTF8StringEncoding]
               willQos:MQTTQosLevelExactlyOnce
        willRetainFlag:NO
          withClientId:ident];

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
    [sessionManager connectToLast];
  }
}

- (void)listenForNetworkConnection {
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  [[[[sc serviceStarted:SCSensorService.serviceId]
      flattenMap:^RACStream *(id value) {
        return sc.sensorService.isConnected;
      }] filter:^BOOL(NSNumber *x) {
    return x.boolValue;
  }] subscribeNext:^(id x) {
    [self authListener];
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
    NSLog(@"MQTT Closed");
    break;
  case MQTTSessionManagerStateClosing:
    NSLog(@"MQTT Closing");
    break;
  case MQTTSessionManagerStateConnected:
    [connectedToBroker sendNext:@(YES)];
    NSLog(@"MQTT Connected");
    break;
  case MQTTSessionManagerStateConnecting:
    break;
  case MQTTSessionManagerStateError:
    NSLog(@"Error MQTT COnnection");
    NSLog(@"Error:%@", err.description);
    break;
  case MQTTSessionManagerStateStarting:
    NSLog(@"Starting MQTT Connection");
    break;
  default:
    break;
  }
}

- (void)publish:(SCMessage *)msg onTopic:(NSString *)topic {
  if (sessionManager.state == MQTTSessionManagerStateConnected) {
    [sessionManager sendData:[msg data]
                       topic:topic
                         qos:MQTTQosLevelExactlyOnce
                      retain:NO];
  }
}

- (void)publishAtMostOnce:(SCMessage *)msg onTopic:(NSString *)topic {
  if (sessionManager.state == MQTTSessionManagerStateConnected) {
    [sessionManager sendData:[msg data]
                       topic:topic
                         qos:MQTTQosLevelAtMostOnce
                      retain:NO];
  }
}

- (void)publishAtLeastOnce:(SCMessage *)msg onTopic:(NSString *)topic {
  if (sessionManager.state == MQTTSessionManagerStateConnected) {
    [sessionManager sendData:[msg data]
                       topic:topic
                         qos:MQTTQosLevelAtLeastOnce
                      retain:NO];
  }
}

- (void)publishExactlyOnce:(SCMessage *)msg onTopic:(NSString *)topic {
  if (sessionManager.state == MQTTSessionManagerStateConnected) {
    [sessionManager sendData:[msg data]
                       topic:topic
                         qos:MQTTQosLevelExactlyOnce
                      retain:NO];
  }
}

- (RACSignal *)publishReplyTo:(SCMessage *)msg onTopic:(NSString *)topic {
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  NSTimeInterval ti = [[NSDate date] timeIntervalSince1970];
  msg.correlationId = ti;
  msg.replyTo =
      [NSString stringWithFormat:@"/device/%@-replyTo", sc.deviceIdentifier];
  if (sessionManager.state == MQTTSessionManagerStateConnected) {
    RACSignal *s = [[multicast map:^SCMessage *(RACTuple *t) {
      NSData *d = (NSData *)t.first;
      NSError *err;
      SCMessage *m = [[SCMessage alloc] initWithData:d error:&err];
      if (err) {
        NSLog(@"%@", err.description);
      }
      return m;
    }] filter:^BOOL(SCMessage *m) {
      if (m.correlationId == msg.correlationId) {
        return YES;
      }
      return NO;
    }];
    [self subscribeToTopic:msg.replyTo];
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
  }] map:^SCMessage *(RACTuple *t) {
    NSData *d = (NSData *)[t first];
    NSError *err;
    SCMessage *msg = [[SCMessage alloc] initWithData:d error:&err];
    if (err) {
      NSLog(@"%@", err.description);
    }
    return msg;
  }];
  [self subscribeToTopic:topic];
  return s;
}

+ (NSString *)serviceId {
  return kSERVICENAME;
}

@end
