/*!
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

#import "Msg.pbobjc.h"
#import "SCAuthService.h"
#import "SCBackendProtocol.h"
#import "SCConfigService.h"
#import "SCDataService.h"
#import "SCNotification.h"
#import "SCRemoteConfig.h"
#import "SCSensorService.h"
#import "SCService.h"
#import "SCServiceLifecycle.h"
#import <MQTTFramework/MQTTFramework.h>
#import <MQTTFramework/MQTTSessionManager.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <UserNotifications/UserNotifications.h>

@interface SCBackendService : SCService <SCServiceLifecycle> {
    SCConfigService *configService;
    SCAuthService *authService;
    SCDataService *dataService;
    SCSensorService *sensorService;
    id<SCBackendProtocol> backend;
}

/*!
 Upon initialization you will inject the server type to use for your
 application
 
 @param bp any banckend server that implements the SCBackendServiceProtocol
 @return id Instance of SCBackendService
 */
- (id)initWithBackend:(id<SCBackendProtocol>)bp;

/*!
 A way to register/update a device token required for push notificaiton
 
 @param token device token required for push notificaitons
 */
- (void)updateDeviceToken:(NSString *)token;

/*!
 Endpoint running backend Server
 */
@property(readonly, strong) NSString *backendUri;

/*!
 Observable emiting SCNotifications
 */
@property(readonly, strong) RACSignal *notifications;

/*!
 Behavior subject return YES for Internet access, NO for offline
 */
@property(nonatomic, readonly) RACBehaviorSubject *isConnected;


@end
