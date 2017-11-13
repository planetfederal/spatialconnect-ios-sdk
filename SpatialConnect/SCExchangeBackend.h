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

#import "SCAuthService.h"
#import "SCBackendProtocol.h"
#import "SCConfigService.h"
#import "SCRemoteConfig.h"
#import "SCSensorService.h"
#import "SCServiceLifecycle.h"
#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface SCExchangeBackend : NSObject <SCBackendProtocol> {
  SCRemoteConfig *remoteConfig;
  SCSensorService *sensorService;
  SCAuthService *authService;
  SCConfigService *configService;
  NSMutableArray *stores;
  NSMutableArray *forms;
}

- (id)initWithRemoteConfig:(SCRemoteConfig *)cfg;

@end
