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

#import "SCAuthService.h"
#import "SCHttpUtils.h"
#import "SCServerAuthMethod.h"
#import "SpatialConnect.h"

static NSString *const kAuthServiceName = @"SC_AUTH_SERVICE";

@implementation SCAuthService

- (id)initWithAuthMethod:(id<SCAuthProtocol>)ap {
  if (self = [super init]) {
    loginStatus = [RACBehaviorSubject
        behaviorSubjectWithDefaultValue:@(SCAUTH_NOT_AUTHENTICATED)];
    authProtocol = ap;
  }
  return self;
}

- (void)setup {
  loginStatus = [RACBehaviorSubject
      behaviorSubjectWithDefaultValue:@(SCAUTH_NOT_AUTHENTICATED)];
}

- (void)authenticate:(NSString *)username password:(NSString *)pass {
  BOOL authed = [authProtocol authenticate:username password:pass];

  if (authed) {
    [loginStatus sendNext:@(SCAUTH_AUTHENTICATED)];
  } else {
    [authProtocol logout];
    [loginStatus sendNext:@(SCAUTH_AUTHENTICATION_FAILED)];
  }
}

- (RACSignal *)loginStatus {
  return loginStatus;
}

- (NSString *)xAccessToken {
  return [authProtocol xAccessToken];
}

- (void)logout {
  [authProtocol logout];
  [loginStatus sendNext:@(SCAUTH_NOT_AUTHENTICATED)];
}

- (NSString *)username {
  return [authProtocol username];
}

#pragma mark -
#pragma SCServiceLifecycle

- (RACSignal *)start {
  [super start];
  BOOL authed = [authProtocol authFromCache];
  if (authed) {
    [loginStatus sendNext:@(SCAUTH_AUTHENTICATED)];
  } else {
    [loginStatus sendNext:@(SCAUTH_NOT_AUTHENTICATED)];
  };
  return [RACSignal empty];
}

- (void)pause {
  [super pause];
}

- (void)resume {
  [super resume];
}

- (void)stop {
  [super stop];
}

- (NSArray *)requires {
  return nil;
}

+ (NSString *)serviceId {
  return kAuthServiceName;
}

@end
