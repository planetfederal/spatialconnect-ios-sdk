/*****************************************************************************
* Licensed to the Apache Software Foundation (ASF) under one
* or more contributor license agreements.  See the NOTICE file
* distributed with this work for additional information
* regarding copyright ownership.  The ASF licenses this file
* to you under the Apache License, Version 2.0 (the
* "License"); you may not use this file except in compliance
* with the License.  You may obtain a copy of the License at
*
*   http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing,
* software distributed under the License is distributed on an
* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
* KIND, either express or implied.  See the License for the
* specific language governing permissions and limitations
* under the License.
******************************************************************************/

#import "SCAuthService.h"
#import "SCBackendService.h"
#import "SCCache.h"
#import "SCConfigService.h"
#import "SCDataService.h"
#import "SCFileUtils.h"
#import "SCGeoJSON.h"
#import "SCJavascriptCommands.h"
#import "SCLineString.h"
#import "SCRCTBridge.h"
#import "SCRasterStore.h"
#import "SCSensorService.h"
#import "SCService.h"
#import "SCSimplePoint.h"
#import "SCSpatialStore.h"
#import "SCSpatialStore.h"
#import "SCStoreStatusEvent.h"
#import "WebViewJavascriptBridge.h"
#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface SpatialConnect : NSObject {
  NSMutableArray *filepaths;
}

@property(readonly, strong) NSMutableDictionary *services;
@property(readonly, strong) SCDataService *dataService;
@property(readonly, strong) SCSensorService *sensorService;
@property(readonly, strong) SCConfigService *configService;
@property(readonly, strong) SCAuthService *authService;
@property(readonly, strong) SCBackendService *backendService;
@property(readonly, strong) SCCache *cache;

@property(readonly) RACMulticastConnection *serviceEvents;

+ (id)sharedInstance;

- (void)startAllServices;
- (void)stopAllServices;
- (void)restartAllServices;

- (void)addService:(SCService *)service;
- (void)removeService:(NSString *)serviceId;
- (SCService *)serviceById:(NSString *)ident;
- (void)startService:(NSString *)serviceId;
- (void)stopService:(NSString *)serviceId;
- (void)restartService:(NSString *)serviceId;
- (void)connectBackend:(SCRemoteConfig *)r;
- (NSString *)deviceIdentifier;
- (RACSignal *)serviceStarted:(NSString *)serviceId;

@end
