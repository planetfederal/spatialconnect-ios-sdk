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

#import "SCSpatialFeature.h"
#import "SpatialConnect.h"

@interface SCSpatialFeature (PrivateMethods)
@end

@implementation SCSpatialFeature

@synthesize location;
@synthesize author;
@synthesize deviceId;
@synthesize createdAt;
@synthesize identifier = _identifier;
@synthesize date;
@synthesize properties = _properties;
@synthesize style;
@synthesize storeId;
@synthesize layerId;

- (id)init {
  if (self = [super init]) {
    _properties = [NSMutableDictionary new];
    createdAt = [NSDate dateWithTimeIntervalSinceNow:0];
  }
  return self;
}

- (NSString *)identifier {
  if (!_identifier) {
    _identifier = [[NSUUID UUID] UUIDString];
  }
  return _identifier;
}

- (NSMutableDictionary *)properties {
  if (!_properties) {
    _properties = [NSMutableDictionary new];
  }
  return _properties;
}

- (SCKeyTuple *)key {
  return [[SCKeyTuple alloc] initWithStoreId:storeId
                                     layerId:layerId
                                   featureId:self.identifier];
  ;
}

// convert date objects to strings for json serialization
- (NSDictionary *)dateToString:(NSMutableDictionary *)dict {
  NSDateFormatter *df = [NSDateFormatter new];
  [df setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
  [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
    if ([obj isKindOfClass:NSDate.class]) {
      [dict setObject:[df stringFromDate:obj] forKey:key];
    }
    if ([obj isKindOfClass:NSDictionary.class]) {
      [dict setObject:[self dateToString:obj] forKey:key];
    }
  }];
  
  return dict;
}

- (NSDictionary *)JSONDict {
  NSMutableDictionary *dict = [NSMutableDictionary new];
  NSDateFormatter *df = [NSDateFormatter new];
  [df setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
  dict[@"type"] = @"Feature";
  dict[@"id"] = self.identifier;

  if (self.properties) {
    dict[@"properties"] = [self dateToString:self.properties];
  } else {
    dict[@"properties"] = [NSNull null];
  }

  dict[@"metadata"] = [NSMutableDictionary new];
  dict[@"metadata"][@"created_at"] = [df stringFromDate:self.createdAt];
  dict[@"metadata"][@"client"] =
      [[SpatialConnect sharedInstance] deviceIdentifier];
  dict[@"metadata"][@"storeId"] = self.storeId;
  dict[@"metadata"][@"layerId"] = self.layerId;
  return [NSDictionary dictionaryWithDictionary:dict];
}

@end
