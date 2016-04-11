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
#import "SCDataServiceStoreConfig.h"
#import "SCMessage.h"

@implementation SCDataServiceStoreConfig

@synthesize type;
@synthesize version;
@synthesize uniqueid;
@synthesize uri;
@synthesize isMainBundle;

- (id)initWithDictionary:(NSDictionary*)dict
{
  self = [super init];
  if (self) {
    self.type = dict[@"type"];
    self.version = [dict[@"version"] integerValue];
    self.uniqueid = dict[@"id"] == nil ? [[NSUUID UUID] UUIDString] : dict[@"id"];
    self.uri = dict[@"uri"];
    self.isMainBundle = [dict[@"isMainBundle"] boolValue];
    if (!self.isMainBundle) {
      self.isMainBundle = NO;
    }
    self.defaultLayer = dict[@"default"];
    self.name = dict[@"name"];
  }
  return self;
}

- (SCMessage*)message {
  NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
  [d setObject:self.type forKey:@"type"];
  [d setObject:@(self.version) forKey:@"version"];
  [d setObject:self.uniqueid forKey:@"id"];
  [d setObject:self.uri forKey:@"uri"];
  [d setObject:@(self.isMainBundle) forKey:@"isMainBundle"];
  [d setObject:self.name forKey:@"name"];

  SCMessage *msg = [SCMessage new];
  msg.serviceIdentifier = @"DATASERVICE";
  msg.action = SCACTION_DATASERVICE_ADDSTORE;
  msg.payload = d;
  return msg;
}

@end
