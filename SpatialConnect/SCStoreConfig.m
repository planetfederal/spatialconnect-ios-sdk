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
#import "SCStoreConfig.h"
#import "SCMessage.h"

@implementation SCStoreConfig

@synthesize type;
@synthesize version;
@synthesize uniqueid;
@synthesize uri;
@synthesize isMainBundle;

- (id)initWithDictionary:(NSDictionary *)dict {
  self = [super init];
  if (self) {
    self.type = dict[@"store_type"];
    self.version = dict[@"version"];
    self.uniqueid =
        dict[@"id"] == nil ? [[NSUUID UUID] UUIDString] : dict[@"id"];
    self.uri = dict[@"uri"];
    self.isMainBundle = [dict[@"isMainBundle"] boolValue];
    if (!self.isMainBundle) {
      self.isMainBundle = NO;
    }
    self.defaultLayer = dict[@"default_layer"];
    self.name = dict[@"name"];
  }
  return self;
}

@end
