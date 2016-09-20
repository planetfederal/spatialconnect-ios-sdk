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

#import "Commands.h"
#import "JSONKit.h"
#import "SCBackendService.h"
#import "SCConfig.h"
#import "SCNotification.h"
#import "Scmessage.pbobjc.h"
#import "SpatialConnect.h"

static NSString *const kSERVICENAME = @"SC_BACKEND_SERVICE";

@interface SCBackendService ()
@property(nonatomic, readwrite, strong) RACSignal *notifications;
- (void)fetchConfigAndListen;
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
  }
  return self;
}

- (RACSignal *)start {
  [super start];
  [self setupMQTT];
  [self setupSubscriptions];
  [self authListener];
  return [RACSignal empty];
}

- (void)stop {
  [session disconnect];
}

- (void)authListener {
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  SCAuthService *as = sc.authService;
  // You have the url to the server. Wait for someone to properly
  // authenticate before fetching the config
  [[as loginStatus] subscribeNext:^(NSNumber *n) {
    SCAuthStatus s = [n integerValue];
    if (s == SCAUTH_AUTHENTICATED) {
      [self registerAndFetchConfig];
      [self listenForUpdates];
    }
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
}

- (void)listenForUpdates {
  [[self listenOnTopic:@"/config/update"] subscribeNext:^(SCMessage *msg) {
    NSString *payload = msg.payload;
    SpatialConnect *sc = [SpatialConnect sharedInstance];
    switch (msg.action) {
    case CONFIG_ADD_STORE: {
      NSDictionary *json = [payload objectFromJSONString];
      SCStoreConfig *config = [[SCStoreConfig alloc] initWithDictionary:json];
      [sc.dataService
          registerAndStartStoreByConfig:config];
      break;
    }
    case CONFIG_UPDATE_STORE: {
      NSDictionary *json = [payload objectFromJSONString];
      SCStoreConfig *config = [[SCStoreConfig alloc] initWithDictionary:json];
      [sc.dataService
          updateStoreByConfig:config];
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
      [sc.dataService.formStore registerFormByConfig:f];
      break;
    }
    case CONFIG_UPDATE_FORM: {
      [sc.dataService.formStore
          updateFormByConfig:[[SCFormConfig alloc]
                                 initWithDict:[payload objectFromJSONString]]];
      break;
    }
    case CONFIG_REMOVE_FORM: {
      [sc.dataService.formStore
          unregisterFormByKey:payload];
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

- (void)setupMQTT {
  MQTTCFSocketTransport *transport = [[MQTTCFSocketTransport alloc] init];
  transport.host = mqttEndpoint;
  transport.port = [[NSString stringWithFormat:@"%@", mqttPort] integerValue];

  NSString *ident = [[SpatialConnect sharedInstance] deviceIdentifier];

  session = [[MQTTSession alloc] init];
  session.transport = transport;
  session.clientId = ident;
  RACSignal *d = [self
      rac_signalForSelector:@selector(newMessage:data:onTopic:qos:retained:mid:)
               fromProtocol:@protocol(MQTTSessionDelegate)];

  multicast = [[d publish] autoconnect];

  session.delegate = self;
  [session connectAndWaitTimeout:30];
}

- (void)publish:(SCMessage *)msg onTopic:(NSString *)topic {
  if (session) {
    [session publishData:[msg data]
                 onTopic:topic
                  retain:NO
                     qos:MQTTQosLevelExactlyOnce];
  }
}

- (void)publishAtMostOnce:(SCMessage *)msg onTopic:(NSString *)topic {
  if (session) {
    [session publishData:msg.data
                 onTopic:topic
                  retain:NO
                     qos:MQTTQosLevelAtMostOnce];
  }
}

- (void)publishAtLeastOnce:(SCMessage *)msg onTopic:(NSString *)topic {
  if (session) {
    [session publishData:msg.data
                 onTopic:topic
                  retain:NO
                     qos:MQTTQosLevelAtLeastOnce];
  }
}

- (void)publishExactlyOnce:(SCMessage *)msg onTopic:(NSString *)topic {
  if (session) {
    [session publishData:msg.data
                 onTopic:topic
                  retain:NO
                     qos:MQTTQosLevelExactlyOnce];
  }
}

- (RACSignal *)publishReplyTo:(SCMessage *)msg onTopic:(NSString *)topic {
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  NSTimeInterval ti = [[NSDate date] timeIntervalSince1970];
  msg.correlationId = ti;
  msg.replyTo =
      [NSString stringWithFormat:@"/device/%@-replyTo", sc.deviceIdentifier];
  if (session) {
    RACSignal *s = [[multicast map:^SCMessage *(RACTuple *t) {
      NSData *d = (NSData *)[t second];
      NSError *err;
      SCMessage *msg = [[SCMessage alloc] initWithData:d error:&err];
      if (err) {
        NSLog(@"%@", err.description);
      }
      return msg;
    }] filter:^BOOL(SCMessage *m) {
      if (m.correlationId == msg.correlationId) {
        return YES;
      }
      return NO;
    }];
    [session subscribeTopic:msg.replyTo];
    [session publishData:[msg data] onTopic:topic];
    return s;
  }
  return nil;
}

- (RACSignal *)listenOnTopic:(NSString *)topic {
  RACSignal *s = [[multicast filter:^BOOL(RACTuple *t) {
    return [[t third] isEqualToString:topic];
  }] map:^SCMessage *(RACTuple *t) {
    NSData *d = (NSData *)[t second];
    NSError *err;
    SCMessage *msg = [[SCMessage alloc] initWithData:d error:&err];
    if (err) {
      NSLog(@"%@", err.description);
    }
    return msg;
  }];
  [session subscribeTopic:topic];
  return s;
}

+ (NSString *)serviceId {
  return kSERVICENAME;
}

@end
