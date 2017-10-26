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
#import "SpatialConnect.h"

#define TOKEN @"service.auth.token"
#define REFRESH_TOKEN @"service.auth.refresh.token"
#define TOKEN_EXPIRATION @"service.auth.token.expire"
#define TOKEN_TIMESTAMP @"service.auth.token.timestamp"
#define EXPIRE_INTERVAL 3600 // seconds

@implementation SCExchangeAuthMethod

- (id)initWithDictionary:(NSDictionary *)d {
  self = [super init];
  if (self) {
    serverUrl = d[@"server_url"];
    clientId = d[@"client_id"];
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

    SpatialConnect *sc = [SpatialConnect sharedInstance];
    NSNumber *expire = (NSNumber *)[sc.cache valueForKey:TOKEN_EXPIRATION];
    NSDate *tokenTimestamp = [sc.cache valueForKey:TOKEN_TIMESTAMP];
    NSDate *tokenExpiration =
        [tokenTimestamp dateByAddingTimeInterval:[expire doubleValue]];
    NSDate *currentTimestamp = [NSDate date];
    NSTimeInterval secondsBeforeExpiration =
        [tokenExpiration timeIntervalSinceDate:currentTimestamp];

    // current timestamp is later than token expiration or less than an 1 hour
    // before the token expires refresh token.
    if ([currentTimestamp compare:tokenExpiration] == NSOrderedDescending ||
        secondsBeforeExpiration < 3600) { // seconds
      return [self refreshToken];
    } else {
      return YES;
    }
  } else {
    return NO;
  }
}

- (BOOL)authenticate:(NSString *)u password:(NSString *)p {
  username = u;
  NSURL *url = [NSURL
      URLWithString:[NSString stringWithFormat:@"%@/o/token/", serverUrl]];
  NSString *auth = [NSString
      stringWithFormat:@"grant_type=password&username=%@&password=%@", u, p];
  NSData *authBody = [auth dataUsingEncoding:NSUTF8StringEncoding];

  NSString *oauthCreds = [NSString stringWithFormat:@"%@:", clientId];
  NSData *nsdata = [oauthCreds dataUsingEncoding:NSUTF8StringEncoding];
  NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
  NSString *authHeader = [NSString stringWithFormat:@"Basic %@", base64Encoded];
  NSDictionary *res = [SCHttpUtils postDataRequestAsDictBLOCKING:url
                                                            body:authBody
                                                            auth:authHeader
                                                     contentType:XML];
  if (res && (jwt = res[@"access_token"])) {
    SpatialConnect *sc = [SpatialConnect sharedInstance];
    SCCache *c = sc.cache;
    [c setValue:jwt forKey:TOKEN];
    [c setValue:res[@"refresh_token"] forKey:REFRESH_TOKEN];
    [c setValue:res[@"expires_in"] forKey:TOKEN_EXPIRATION];
    [c setValue:[NSDate date] forKey:TOKEN_TIMESTAMP];

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

- (BOOL)refreshToken {

  @try {
    SCCache *c = [[SpatialConnect sharedInstance] cache];
    NSString *refreshToken = [c valueForKey:REFRESH_TOKEN];
    NSURL *url = [NSURL
        URLWithString:[NSString stringWithFormat:@"%@/o/token/", serverUrl]];
    NSString *auth =
        [NSString stringWithFormat:@"grant_type=refresh_token&refresh_token=%@",
                                   refreshToken];
    NSData *authBody = [auth dataUsingEncoding:NSUTF8StringEncoding];

    NSString *oauthCreds = [NSString stringWithFormat:@"%@:", clientId];
    NSData *nsdata = [oauthCreds dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
    NSString *authHeader =
        [NSString stringWithFormat:@"Basic %@", base64Encoded];
    NSDictionary *res = [SCHttpUtils postDataRequestAsDictBLOCKING:url
                                                              body:authBody
                                                              auth:authHeader
                                                       contentType:XML];
    if (res && (jwt = res[@"access_token"])) {
      SpatialConnect *sc = [SpatialConnect sharedInstance];
      SCCache *c = sc.cache;
      [c setValue:jwt forKey:TOKEN];
      [c setValue:res[@"refresh_token"] forKey:REFRESH_TOKEN];
      [c setValue:res[@"expires_in"] forKey:TOKEN_EXPIRATION];
      [c setValue:[NSDate date] forKey:TOKEN_TIMESTAMP];
      return true;
    } else {
      if (res[@"error"]) {
        NSString *e = res[@"error"];
        DDLogInfo(@"error trying to refresh token: %@", e);
      }
      [self logout];
      return false;
    }
    return false;
  } @catch (NSException *e) {
    // deal with the exception
    DDLogInfo(@"ERROR %@", e.reason);
  }
}

@end
