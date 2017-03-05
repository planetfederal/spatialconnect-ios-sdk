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
 * See the License for the specific language governing permissions and limitations under the License
 */

#import <Foundation/Foundation.h>
#import "SCServiceLifecycle.h"
#import "SCServiceNode.h"

@interface SCServiceGraph : NSObject {
  NSMutableArray *serviceNodes;
}

@property(readonly) RACMulticastConnection *serviceEvents;

- (void)addService:(id<SCServiceLifecycle>)s;
- (void)removeService:(NSString *)serviceId;
- (SCServiceNode*)nodeById:(NSString*)serviceId;

- (void)startAllServices;
- (BOOL)startService:(NSString *)serviceId;
- (void)stopAllServices;
- (BOOL)stopService:(NSString *)serviceId;
- (void)restartAllServices;

@end
