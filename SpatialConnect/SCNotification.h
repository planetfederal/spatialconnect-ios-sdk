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

#import "Scmessage.pbobjc.h"

typedef NS_ENUM(NSUInteger, SCNotificationLevel) {
  SC_NOTIFICATION_INFO = 0,
  SC_NOTIFICATION_ALERT = 1,
  SC_NOTIFICATION_BACKGROUND = 2
};

@interface SCNotification : NSObject

@property(nonatomic, readonly) NSString *to;
@property(nonatomic, readonly) SCNotificationLevel priority;
@property(nonatomic, readonly) NSString *icon;
@property(nonatomic, readonly) NSString *title;
@property(nonatomic, readonly) NSString *body;
@property(nonatomic, readonly) NSDictionary *payload;

- (id)initWithMessage:(SCMessage *)m;
- (NSDictionary *)dictionary;

@end
