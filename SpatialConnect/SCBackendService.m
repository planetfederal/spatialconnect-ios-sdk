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
#import "Actions.h"
#import "JSONKit.h"
#import "Msg.pbobjc.h"
#import "SCConfig.h"
#import "SCNotification.h"
#import "SpatialConnect.h"

static NSString *const kBackendServiceName = @"SC_BACKEND_SERVICE";

@implementation SCBackendService

@synthesize backendUri = _backendUri;
@synthesize isConnected = _isConnected;
@synthesize configReceived = _configReceived;

- (id)initWithBackend:(id<SCBackendProtocol>)bp {
  if (self = [super init]) {
    backend = bp;
    _backendUri = backend.backendUri;
    _isConnected = backend.isConnected;
    _configReceived =
        [RACBehaviorSubject behaviorSubjectWithDefaultValue:@(NO)];
  }
  return self;
}

- (void)updateDeviceToken:(NSString *)token {
  [backend updateDeviceToken:token];
}

- (BOOL)start:(NSDictionary<NSString *, id<SCServiceLifecycle>> *)deps {
  authService = [deps objectForKey:[SCAuthService serviceId]];
  configService = [deps objectForKey:[SCConfigService serviceId]];
  sensorService = [deps objectForKey:[SCSensorService serviceId]];
  dataService = [deps objectForKey:[SCDataService serviceId]];
  [backend start:deps];
  DDLogInfo(@"Backend Service Started");
  return [super start:nil];
}

- (BOOL)stop {
  [backend stop];
  return [super stop];
}

- (NSArray *)requires {
  return @[
    [SCAuthService serviceId], [SCConfigService serviceId],
    [SCSensorService serviceId], [SCDataService serviceId]
  ];
}

+ (NSString *)serviceId {
  return kBackendServiceName;
}
@end
