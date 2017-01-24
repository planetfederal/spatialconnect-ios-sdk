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

#import "SCConfigService.h"
#import "SCDataService.h"
#import "SCNotification.h"
#import "SCRemoteConfig.h"
#import "SCService.h"
#import "SCServiceLifecycle.h"
#import "Scmessage.pbobjc.h"
#import <MQTTFramework/MQTTFramework.h>
#import <MQTTFramework/MQTTSessionManager.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <UserNotifications/UserNotifications.h>

@interface SCBackendService
    : SCService <SCServiceLifecycle, UNUserNotificationCenterDelegate> {
  NSString *mqttEndpoint;
  NSString *mqttPort;
  NSString *mqttProtocol;
  NSString *httpProtocol;
  NSString *httpEndpoint;
  NSString *httpPort;
  MQTTSessionManager *sessionManager;
  RACSignal *multicast;
  SCConfigService *configService;
  SCDataService *dateService;
}

/*!
 Endpoint running SpatialConnect Server
 */
@property(readonly, strong) NSString *backendUri;

/*!
 Observable emiting SCNotifications
 */
@property(readonly, strong) RACSignal *notifications;

/*!
 Behavior Observable emitting YES when the SpatialConnect SCConfig has been
 received
 */
@property(readonly, strong) RACBehaviorSubject *configReceived;

/*!
 Behavior Observable emitting YES when Connected, NO when the Connection is down
 */
@property(readonly, strong) RACBehaviorSubject *connectedToBroker;

- (id)initWithRemoteConfig:(SCRemoteConfig *)cfg;

/*!
 Publishes an SCMessage to the SpatialConnect Server

 @param msg SCMessage to be sent
 @param topic MQTT destination topic
 */
- (void)publish:(SCMessage *)msg onTopic:(NSString *)topic;

/*!
 Publishes an SCMessage to the SpatialConnect Server with At Most Once Delivery
 QoS 0

 @param msg SCMessage to be sent
 @param topic MQTT destination topic
 */
- (void)publishAtMostOnce:(SCMessage *)msg onTopic:(NSString *)topic;

/*!
 Publishes an SCMessage to the SpatialConnect Server with At Least Once Delivery
 QoS 1

 @param msg SCMessage to be sent
 @param topic MQTT destination topic
 */
- (void)publishAtLeastOnce:(SCMessage *)msg onTopic:(NSString *)topic;

/*!
 Publishes an SCMessage to the SpatialConnect Server with Exactly Once Delivery
 QoS 2

 @param msg SCMessage to be sent
 @param topic MQTT destination topic
 */
- (void)publishExactlyOnce:(SCMessage *)msg onTopic:(NSString *)topic;

/*!
 Publishes a message with a reply-to observable returned for creating a request
 reply with the server.

 @param msg SCMessage to be sent
 @param topic MQTT destination topic
 @return Observable the message will be received on
 */
- (RACSignal *)publishReplyTo:(SCMessage *)msg onTopic:(NSString *)topic;

/*!
 Subscribes to an MQTT Topic

 @param topic to Listen on
 @return Observable filtered to only receive messages from the stated topic
 */
- (RACSignal *)listenOnTopic:(NSString *)topic;

@end
