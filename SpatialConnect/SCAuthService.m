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
#import "SpatialConnect.h"

static NSString *const kSERVICENAME = @"SC_AUTH_SERVICE";

@implementation SCAuthService

- (id)init {
  if (self = [super init]) {
    keychainItem = [[KeychainItemWrapper alloc]
        initWithIdentifier:@"SpatialConnect"
               accessGroup:@"com.boundlessgeo.spatialconnect"];
    loginStatus = [RACBehaviorSubject
        behaviorSubjectWithDefaultValue:@(SCAUTH_NOT_AUTHENTICATED)];
  }
  return self;
}

- (void)authenticate:(NSString *)username password:(NSString *)pass {
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  SCBackendService *bs = sc.backendService;
  NSString *serverUrl = bs.backendUri;
  if (!serverUrl) {
    NSLog(@"There is no remote server uri set");
    return;
  }
  NSURL *url =
      [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/authenticate",
                                                      serverUrl]];
  NSDictionary *authDict = @{ @"email" : username, @"password" : pass };
  NSDictionary *res =
      [SCHttpUtils postDictRequestAsDictBLOCKING:url body:authDict];
  if (res && (jsonWebToken = res[@"result"][@"token"])) {
    [keychainItem setObject:pass forKey:(__bridge id)kSecValueData];
    [keychainItem setObject:username forKey:(__bridge id)kSecAttrAccount];
    [loginStatus sendNext:@(SCAUTH_AUTHENTICATED)];
  } else {
    [self logout];
    [loginStatus sendNext:@(SCAUTH_NOT_AUTHENTICATED)];
  }
}

- (RACSignal *)loginStatus {
  return loginStatus;
}

- (NSString *)xAccessToken {
  return jsonWebToken;
}

- (void)logout {
  [keychainItem resetKeychainItem];
  [loginStatus sendNext:@(SCAUTH_NOT_AUTHENTICATED)];
}

#pragma mark -
#pragma SCServiceLifecycle

- (RACSignal *)start {
  [super start];
  [[[SpatialConnect sharedInstance]
      serviceStarted:[SCBackendService serviceId]] subscribeNext:^(id value) {
    NSString *password = [keychainItem objectForKey:(__bridge id)kSecValueData];
    NSString *username =
        [keychainItem objectForKey:(__bridge id)kSecAttrAccount];
    if (![password isEqualToString:@""] && ![username isEqualToString:@""]) {
      [self authenticate:username password:password];
    } else {
      [loginStatus sendNext:@(SCAUTH_NOT_AUTHENTICATED)];
    }
  }];
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

- (void)startError {
  [super startError];
}

- (NSArray *)requires {
  return nil;
}

+ (NSString *)serviceId {
  return kSERVICENAME;
}

@end
