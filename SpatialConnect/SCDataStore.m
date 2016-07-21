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

@interface SCDataStore ()
@property(readwrite, nonatomic, strong) NSString *storeId;
@property(readwrite, nonatomic, strong) NSString *storeVersion;
@property(readwrite, nonatomic, strong) NSString *storeType;
@property(readwrite, nonatomic, strong) NSArray *layerList;
@property(readwrite, nonatomic, strong) NSArray *defaultLayers;
@end

@implementation SCDataStore

@synthesize name;
@synthesize defaultLayers = _defaultLayers;
@synthesize key = _key;
@synthesize status, permission;
@synthesize storeVersion = _storeVersion;
@synthesize storeType = _storeType;

- (id)init {
  self = [super init];
  if (!self) {
    return nil;
  }
  permission = SC_DATASTORE_READONLY;
  _layerList = [NSArray new];
  _storeId = [[NSUUID UUID] UUIDString];
  return self;
}

- (id)initWithStoreConfig:(SCStoreConfig *)config {
  self = [self init];
  if (!self) {
    return nil;
  }
  self.storeId = config.uniqueid;
  self.name = config.name;
  self.defaultLayers = config.defaultLayers;
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
  if (!_key) {
    _key = [NSString stringWithFormat:@"%@.%@", _storeType, _storeVersion];
  }
  return _key;
}

- (NSDictionary *)dictionary {
  return @{
    @"storeId" : self.storeId,
    @"name" : self.name,
    @"style" : self.style,
    @"type" : self.storeType,
    @"version" : self.storeVersion,
    @"key" : self.key,
    @"default_layers" : self.defaultLayers
  };
}

#pragma mark -
#pragma mark Class Methods

+ (NSString *)versionKey {
  NSAssert(NO, @"This is an abstract method and should be overridden. Format "
               @"for versionKey shoulde be <storename>.<versionnumber> ie "
               @"geojson.1");
  return nil;
}

@end
