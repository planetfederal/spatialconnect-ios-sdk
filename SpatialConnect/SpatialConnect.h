/*!***************************************************************************
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
#import "SCRasterStore.h"
#import "SCSensorService.h"
#import "SCService.h"
#import "SCServiceGraph.h"
#import "SCSimplePoint.h"
#import "SCSpatialStore.h"
#import "SCStoreStatusEvent.h"
#import "WebViewJavascriptBridge.h"
#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface SpatialConnect : NSObject

@property(readonly) SCSensorService *sensorService;
@property(readonly) SCDataService *dataService;
@property(readonly) SCConfigService *configService;
@property(readonly) SCAuthService *authService;
@property(readonly) SCBackendService *backendService;

@property(readonly, strong) SCCache *cache;

/*!
 @description This singleton of SpatialConnect is shared across your app.

 @return instance of SpatialConnect
 */
+ (id)sharedInstance;

/*!
 @discussion This starts all the services in the order they were added. Data,
 Sensor, Config, and Auth are all started. Backend Service waits for the Config
 service to find a remote backend.

 @brief Starts all the services
 */
- (void)startAllServices;

/*!
 @discussion Stops all the services in the order they were added to the services
 dictionary.

 @brief Stops the services
 */
- (void)stopAllServices;

/*!
 @description Stops all the services and then restarts them in the order they
 are added to the dictionary.

 @brief Restarts the services
 */
- (void)restartAllServices;

/*!
 @description Adds an instantiated instance of Service that extends the
 SCService class. The 'service' must extend the SCService class.

 @brief Adds a service to the SpatialConnect instance

 @param service instance of SCService class
 */
- (void)addService:(SCService *)service;

/*!
 @description This stops and removes a service from the SpatialConnect instance.

 @brief Removes a service from the SpatialConnect instance

 @param serviceId Service's unique identifier
 */
- (void)removeService:(NSString *)serviceId;

/*!
 @discussion This is the preferred way to start a service.

 @warning Do not call service start on the service instance. Use this method to
 start a service.

 @brief Starts a single service

 @param serviceId the unique id of the service.
 */
- (void)startService:(NSString *)serviceId;

/*!
 @discussion This is the preferred way to stop a service.

 @warning Do not call service stop on the service instance. Use this method to
 stop a service.

 @brief Stops a single service

 @param serviceId the unique id of the service.
 */
- (void)stopService:(NSString *)serviceId;

/*!
 @discussion This is the preferred way to restart a service.

 @warning Do not call service restart on the service instance. Use this method
 to start a service.

 @brief Restarts a single service

 @param serviceId the unique id of the service.
 */
- (void)restartService:(NSString *)serviceId;

/*!
 @discussion If you have an instance of SpatialConnect Server, this is how you
 would register it. Passing in a remote configuration object will use the info
 to start the connection to the backend.

 @brief Connects to SpatialConnect Server

 @param r remote configuration
 */
- (void)connectBackend:(SCRemoteConfig *)r;

/*!
 @discussion Regier backend. Passing in a remote configuration object and backend type will use the info
 to start the connection to the backend.
 
 @brief Connects to a backend server
 
 @param r remote configuration
 @param bp backend protocol
 */
- (void)connectBackend:(id<SCBackendProtocol>)bp remote:(SCRemoteConfig *)r;

/*

 */
- (void)connectAuth:(id<SCAuthProtocol>)ap;

- (void)updateDeviceToken:(NSString *)token;

/*!
 @discussion this is the unique identifier that is App Store compliant and used
 to uniquely identify the installation id which is unique per install on a
 device. ID's tied to the hardware are not allowed to be used by the app store

 @brief unique identifier

 @return UUID string of the install id.
 */
- (NSString *)deviceIdentifier;

/*!
 @description emits an SCServiceStatusEvent when the service is running. If the
 service isn't started, this will wait until it is started. This can be used by
 your
 app to start wiring up functionality waiting for it to occur. This is the best
 way to know if a service is started. If the service is already started, it will
 return an event immediately. You can also receive errors in the subscribe's
 error block. The observable will complete when the store is confirmed to have
 started.

 @brief An observable to listen for store start

 @param serviceId a services unique id

 @return RACSignal that emits when the service is running
 */
- (RACSignal *)serviceRunning:(NSString *)serviceId;

- (SCService *)serviceById:(NSString *)serviceId;

- (SCDataService *)dataService;
- (SCConfigService *)configService;
- (SCAuthService *)authService;
- (SCBackendService *)backendService;
- (SCSensorService *)sensorService;

@end
