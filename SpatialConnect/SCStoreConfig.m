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
#import "SCStoreConfig.h"
#import "JSONKit.h"
#import "SCDataService.h"

static NSString *const STORE_TYPE = @"store_type";
static NSString *const VERSION = @"version";
static NSString *const IDENT = @"id";
static NSString *const URI = @"uri";
static NSString *const NAME = @"name";
static NSString *const DEFAULT_LAYERS = @"default_layers";
static NSString *const STYLE = @"style";

@implementation SCStoreConfig

@synthesize type = _type;
@synthesize version = _version;
@synthesize uniqueid = _uniqueid;
@synthesize uri = _uri;
@synthesize defaultLayers = _defaultLayers;
@synthesize name = _name;
@synthesize style = _style;

- (id)initWithDictionary:(NSDictionary *)dict {
  self = [super init];
  if (self) {
    _type = dict[STORE_TYPE];
    _version = dict[VERSION];
    _uniqueid = dict[IDENT] == nil ? [[NSUUID UUID] UUIDString] : dict[IDENT];
    _uri = dict[URI];
    NSArray *layers = dict[DEFAULT_LAYERS];
    _defaultLayers = [layers isKindOfClass:[NSNull class]]
                         ? [NSArray new]
                         : dict[DEFAULT_LAYERS];
    _name = dict[NAME];
    _style = dict[STYLE];
  }
  return self;
}

- (NSDictionary *)dictionary {
  return @{
    STORE_TYPE : _type,
    VERSION : _version,
    IDENT : _uniqueid,
    URI : _uri,
    DEFAULT_LAYERS : _defaultLayers ? _defaultLayers : @[],
    NAME : _name,
    STYLE : _style == nil || [_style isKindOfClass:[NSNull class]] ? @{}
                                                                   : _style
  };
}

- (NSString *)description {
  return self.dictionary.JSONString;
}

@end
