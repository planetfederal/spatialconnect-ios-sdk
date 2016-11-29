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

#import "SCNotification.h"
#import "JSONKit.h"

@interface SCNotification ()
@property(nonatomic, readwrite, strong) NSString *to;
@property(nonatomic, readwrite, strong) NSString *priority;
@property(nonatomic, readwrite, strong) NSString *icon;
@property(nonatomic, readwrite, strong) NSString *title;
@property(nonatomic, readwrite, strong) NSString *body;
@property(nonatomic, readwrite, strong) NSDictionary *payload;
@end

@implementation SCNotification

@synthesize to = _to, priority = _priority, title = _title,
            body = _body, payload = _payload;

- (id)initWithMessage:(SCMessage *)m {
  self = [super init];
  if (self) {
    NSDictionary *d = [m.payload objectFromJSONString];
    self.to = d[@"to"];
    self.priority = d[@"priority"];
    self.title = d[@"title"];
    self.body = d[@"body"];
    self.payload = d[@"payload"];
  }
  return self;
}

- (NSDictionary *)dictionary {
  return @{
    @"to" : self.to,
    @"priority" : self.priority,
    @"body" : self.body,
    @"title" : self.title,
    @"payload" : self.payload
  };
}

@end
