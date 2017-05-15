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

@interface SCNotification : NSObject

@property(nonatomic, readonly) NSString *to;
@property(nonatomic, readonly) NSString *priority;
@property(nonatomic, readonly) NSString *title;
@property(nonatomic, readonly) NSString *body;
@property(nonatomic, readonly) NSDictionary *payload;

- (id)initWithMessage:(Msg *)m;
- (NSDictionary *)dictionary;

@end
