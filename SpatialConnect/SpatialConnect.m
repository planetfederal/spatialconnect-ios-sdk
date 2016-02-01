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

#import "SCDataService.h"
#import "SCLoggingAssertionHandler.h"
#import "SCNetworkService.h"
#import "SpatialConnect.h"

@interface SpatialConnect ()

- (void)startAssertionHandler;

@end

@implementation SpatialConnect

- (id)init {
  if (self = [super init]) {
    self.manager = [[SCServiceManager alloc] init]; // TODO sweep common dirs
    [self startAssertionHandler];
  }
  return self;
}

- (id)initWithFilepath:(NSString *)filepath {
  self = [super init];
  if (!self) {
    return nil;
  }
  self.manager = [[SCServiceManager alloc] initWithFilepath:filepath];
  [self startAssertionHandler];
  return self;
}

- (id)initWithFilepaths:(NSArray *)filepaths {
  self = [super init];
  if (!self) {
    return nil;
  }
  self.manager = [[SCServiceManager alloc] initWithFilepaths:filepaths];
  [self startAssertionHandler];
  return self;
}

- (void)startAllServices {
  [self.manager startAllServices];
}

- (void)stopAllServices {
  [self.manager stopAllServices];
}

- (void)startAssertionHandler {
  NSAssertionHandler *assertionHandler =
      [[SCLoggingAssertionHandler alloc] init];
  [[[NSThread currentThread] threadDictionary] setValue:assertionHandler
                                                 forKey:NSAssertionHandlerKey];
}

@end
