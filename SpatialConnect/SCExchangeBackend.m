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

#import "SCExchangeBackend.h"
#import "SCConfig.h"
#import <Foundation/Foundation.h>

@implementation SCExchangeBackend

- (id)initWithRemoteConfig:(SCRemoteConfig *)cfg {
  self = [super init];
  if (self) {
    remoteConfig = cfg;
  }
  return self;
}

- (BOOL)start:(NSDictionary<NSString *, id<SCServiceLifecycle>> *)svcs {
  sensorService = [svcs objectForKey:[SCSensorService serviceId]];
  return YES;
}

- (BOOL)stop {
  return YES;
}

- (NSString *)backendUri {
  return remoteConfig.httpUri;
}

- (RACSignal *)notifications {
  return nil;
}

- (void)updateDeviceToken:(NSString *)token {
}

- (RACBehaviorSubject *)isConnected {
  return sensorService.isConnected;
}

@end
