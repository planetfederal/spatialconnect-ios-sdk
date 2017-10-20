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

#import "SCExchangeAuthMethod.h"
#import "SCHttpUtils.h"

@implementation SCExchangeAuthMethod

- (id)initWithDictionary:(NSDictionary *)d {
  self = [super init];
  if (self) {
    serverUrl = d[@"server_url"];
    clientId = d[@"client_id"];
    clientSecret = d[@"client_secret"];
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
  [NSURL URLWithString:[NSString stringWithFormat:@"%@/o/token",
                        serverUrl]];
  NSDictionary *authDict = @{ @"grant_type": @"password", @"username" : u, @"password" : p };
  NSString *oauthCreds = [NSString stringWithFormat:@"%@:%@", clientId, clientSecret];
  NSData *nsdata = [oauthCreds dataUsingEncoding:NSUTF8StringEncoding];
  NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
  NSString *auth = [NSString stringWithFormat:@"Basic %@", base64Encoded];
  NSDictionary *res =
  [SCHttpUtils postDictRequestAsDictBLOCKING:url body:authDict auth:auth];
  if (res && (jwt = res[@"result"][@"token"])) {
    [keychainItem setObject:p forKey:(__bridge id)kSecValueData];
    [keychainItem setObject:username forKey:(__bridge id)kSecAttrAccount];
    return true;
  } else {
    [self logout];
    return false;
  }
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

