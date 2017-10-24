/**
 * Copyright 2017 Boundless http://boundlessgeo.com
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

#import "SCServerAuthMethod.h"
#import "SCHttpUtils.h"

@implementation SCServerAuthMethod

- (id)initWithDictionary:(NSDictionary *)d {
  self = [super init];
  if (self) {
    serverUrl = d[@"server_url"];
    keychainItem =
        [[KeychainItemWrapper alloc] initWithIdentifier:@"SpatialConnect"
                                            accessGroup:nil];
  }
  return self;
}

- (BOOL)authFromCache {
  NSString *password = [keychainItem objectForKey:(__bridge id)kSecValueData];
  NSString *username = [keychainItem objectForKey:(__bridge id)kSecAttrAccount];
  if (![password isEqualToString:@""] && ![username isEqualToString:@""]) {
    return [self authenticate:username password:password];
  } else {
    return NO;
  }
}

- (BOOL)authenticate:(NSString *)u password:(NSString *)p {
  username = u;
  NSURL *url =
      [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/authenticate",
                                                      serverUrl]];
  NSDictionary *authDict = @{@"email" : u, @"password" : p};
  NSDictionary *res =
      [SCHttpUtils postDictRequestAsDictBLOCKING:url body:authDict];
  if (res && (jwt = res[@"result"][@"token"])) {
    [keychainItem setObject:p forKey:(__bridge id)kSecValueData];
    [keychainItem setObject:username forKey:(__bridge id)kSecAttrAccount];
    return true;
  } else {
    [self logout];
    return false;
  }
}

- (BOOL)refreshToken {
  return false;
}

- (NSString *)xAccessToken {
  return jwt;
}

- (void)logout {
}

- (NSString *)username {
  return username;
}

@end
