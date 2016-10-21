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
#import "KeychainItemWrapper.h"
#import "SCService.h"
#import "SCServiceLifecycle.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

typedef NS_ENUM(NSUInteger, SCAuthStatus) {
  SCAUTH_AUTHENTICATION_FAILED = 2,
  SCAUTH_AUTHENTICATED = 1,
  SCAUTH_NOT_AUTHENTICATED = 0
};

@interface SCAuthService : SCService <SCServiceLifecycle> {
  NSString *jsonWebToken;
  RACBehaviorSubject *loginStatus;
  KeychainItemWrapper *keychainItem;
}

/*!
 *  @brief sets the token and auth status in the library for the
 *  user and pass
 *
 *  @param username user's email address
 *  @param pass clear text password
 */
- (void)authenticate:(NSString *)username password:(NSString *)pass;

/*!
 *  @brief this will void the x-access-token
 */
- (void)logout;

/*!
 *  @brief JSONWebToken from auth server
 *
 *  @return NSString
 */
- (NSString *)xAccessToken;

/*!
 *  @brief Observable that will send current status
 *  and will send updates as subscribed
 *
 *  @return RACSignal<SCAuthStatus>
 */
- (RACSignal *)loginStatus;

@end
