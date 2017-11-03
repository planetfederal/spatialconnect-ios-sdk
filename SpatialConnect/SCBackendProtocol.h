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

#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "SCServiceLifecycle.h"
#import "SCRemoteConfig.h"

@protocol SCBackendProtocol <NSObject>

- (void)initWithRemoteConfig:(SCRemoteConfig *)remoteConfig;

- (BOOL)start:(NSDictionary<NSString *, id<SCServiceLifecycle>> *)svcs;

- (BOOL)pause;

- (BOOL)resume;

- (BOOL)stop;

- (NSString *)backendUri;

- (RACSignal *)notifications;

- (void)updateDeviceToken:(NSString *)token;

@end

