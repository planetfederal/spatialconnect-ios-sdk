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

#import "SCDataStore.h"

@implementation SCDataStore

@synthesize storeId = _storeId;
@synthesize name = _name;
@synthesize style = _style;
@synthesize type = _type;
@synthesize version = _version;
@synthesize key = _key;

- (id)init {
  self = [super init];
  if (!self) {
    return nil;
  }
  _storeId = [[NSUUID UUID] UUIDString];
  return self;
}

- (id)initWithStoreConfig:(SCStoreConfig *)config {
  self = [self init];
  if (!self) {
    return nil;
  }
  _storeId = config.uniqueid;
  _name = config.name;
  return self;
}

- (id)initWithStoreConfig:(SCStoreConfig *)config withStyle:(SCStyle *)style {
  self = [self initWithStoreConfig:config];
  if (!self) {
    return nil;
  }
  _style = style;
  return self;
}

- (NSString *)key {
  NSAssert(_type, @"Store Type for Store has not been set");
  NSAssert(_version > 0, @"Adapter Version for Adapter is not valid. Value:%ld",
           (long)_version);
  if (!_key) {
    _key = [NSString stringWithFormat:@"%@.%ld", _type, (long)_version];
  }
  return _key;
}

- (NSDictionary *)dictionary {
  return @{
    @"storeId" : self.storeId,
    @"name" : self.name,
    @"style" : self.style,
    @"type" : self.type,
    @"version" : [NSNumber numberWithLong:self.version],
    @"key" : self.key
  };
}

#pragma mark -
#pragma mark Class Methods

+ (NSString *)versionKey {
  NSAssert(NO, @"This is an abstract method and should be overridden");
  return nil;
}

@end
