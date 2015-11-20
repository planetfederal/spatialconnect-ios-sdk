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

#import <Foundation/Foundation.h>
#import "SCService.h"
#import "SCDataService.h"
#import "SCSensorService.h"
#import "SCNetworkService.h"
#import "SCRasterService.h"

@interface SCServiceManager : NSObject

@property(nonatomic, readonly, strong) NSMutableDictionary *services;
@property(nonatomic, readonly, strong) SCDataService *dataService;
@property(nonatomic, readonly, strong) SCNetworkService *networkService;
@property(nonatomic, readonly, strong) SCSensorService *sensorService;
@property(nonatomic, readonly, strong) SCRasterService *rasterService;

- (instancetype)initWithFilepath:(NSString *)filepath;
- (instancetype)initWithFilepaths:(NSArray *)filepaths;

- (void)addService:(SCService *)service;
- (void)removeService:(NSString *)serviceId;

- (void)startService:(NSString *)serviceId;
- (void)stopService:(NSString *)serviceId;
- (void)restartService:(NSString *)serviceId;
- (void)startAllServices;
- (void)stopAllServices;
- (void)restartAllServices;

@end
