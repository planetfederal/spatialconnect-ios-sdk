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




#import <Foundation/Foundation.h>

#import "SCService.h"

@interface SCService (PrivateMethods)

-(void)generateId;

@property (nonatomic,strong) NSString* identifier;
@property (nonatomic) SCServiceStatus status;

@end

@implementation SCService

@synthesize identifier = _identifier;
@synthesize status = _status;
@synthesize delegate;

- (id)init {
  self = [super init];
  if (!self) {
    return nil;
  }
  [self generateId];
  _status = SC_SERVICE_STOPPED;
  return self;
}

#pragma mark  - Service Lifecycle

- (void)start {
  _status = SC_SERVICE_RUNNING;
}

- (void)stop {
  [delegate serviceWillStop];
  _status = SC_SERVICE_STOPPED;
}

- (void)resume {
  self.status = SC_SERVICE_RUNNING;
}

- (void)pause {
  self.status = SC_SERVICE_PAUSED;
}

#pragma mark - Private

- (void)generateId {
  _identifier = [[NSUUID UUID] UUIDString];
}

@end
