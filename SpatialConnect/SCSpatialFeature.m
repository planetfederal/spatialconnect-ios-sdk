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

@interface SCSpatialFeature (PrivateMethods)
- (BOOL)isClean:(NSString *)str;
@end

@implementation SCSpatialFeature

@synthesize identifier = _identifier;
@synthesize date;
@synthesize properties;
@synthesize style;
@synthesize storeId;
@synthesize layerId;

- (id)init {
  if (self = [super init]) {
    properties = [NSMutableDictionary new];
  }
  return self;
}

- (NSString *)identifier {
  if (!_identifier) {
    _identifier = [[NSUUID UUID] UUIDString];
  }
  return _identifier;
}

- (void)setLayerId:(NSString *)lId {
  NSAssert([self isClean:lId], @"Id Cannot contain illegal chars");
  self.layerId = lId;
}

- (void)setStoreId:(NSString *)sId {
  NSAssert([self isClean:sId], @"Id cannot contain illegal characters");
  self.storeId = sId;
}

- (SCKeyTuple *)key {
  return [[SCKeyTuple alloc] initWithStoreId:storeId
                                     layerId:layerId
                                   featureId:self.identifier];
  ;
}

@end
