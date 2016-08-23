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

#import "Commands.h"
#import "JSONKit.h"
#import "SCBackendService.h"
#import "Scmessage.pbobjc.h"
#import "SpatialConnect.h"

@interface SCBackendService ()
@property(nonatomic, readwrite, strong) RACSignal *notifications;
@end

@implementation SCBackendService

@synthesize notifications;

- (void)start {
  [self setupSubscriptions];
}

- (void)stop {
}

- (void)setupSubscriptions {
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  SCNetworkService *ns = sc.networkService;

  NSString *ident =
      [[NSUserDefaults standardUserDefaults] stringForKey:@"UNIQUE_ID"];
  self.notifications = [ns listenOnTopic:@"/notify"];
  [[self.notifications
      merge:[ns listenOnTopic:[NSString stringWithFormat:@"/notify/%@", ident]]]
      map:^id(id value) {
        return value;
      }];
}

- (void)fetchConfigAndListen {
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  SCNetworkService *ns = sc.networkService;

  [[ns listenOnTopic:@"/config/update"] subscribeNext:^(SCMessage *msg) {
    switch (msg.action) {
    case CONFIG_ADD_STORE:
      NSLog(@"Add Store");
      break;
    case CONFIG_UPDATE_STORE:
      NSLog(@"Update Store");
      break;
    case CONFIG_REMOVE_STORE:
      NSLog(@"Remove Store");
      break;
    default:
      break;
    }
  }];
}

@end
