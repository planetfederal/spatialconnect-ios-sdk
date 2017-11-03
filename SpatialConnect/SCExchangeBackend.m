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

#import <Foundation/Foundation.h>
#import "SCExchangeBackend.h"
#import "SCConfig.h"

@implementation SCExchangeBackend


- (id)initWithRemoteConfig:(SCRemoteConfig *)cfg {
    self = [super init];
    if (self){
        remoteConfig = cfg;
    }
    return self;
}

- (void)connect {
    
}

- (BOOL)start:(NSDictionary<NSString *, id<SCServiceLifecycle>> *)svcs {
    return YES;
}

- (BOOL)pause {
    return YES;
}

- (BOOL)resume {
    return YES;
}

- (BOOL)stop {
    return YES;
}

- (NSString *)backendUri {
    return nil;
}

- (RACSignal *)notifications {
    return nil;
}

- (void)updateDeviceToken:(NSString *)token {
    
}

@end
