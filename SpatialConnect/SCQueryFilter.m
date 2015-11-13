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

#import "SCQueryFilter.h"

@interface SCQueryFilter (Private)

@end

@implementation SCQueryFilter

@synthesize limit;
@synthesize predicates = _predicates;
@synthesize layerIds = _layerIds;

- (id)init {
  self = [super init];
  if (!self) {
    return nil;
  }
  _predicates = [NSMutableArray new];
  _layerIds = [NSMutableArray new];
  return nil;
}

+ (instancetype)filterFromDictionary:(NSDictionary *)dictionary {
  SCQueryFilter *filter = [[SCQueryFilter alloc] init];
  NSArray *filters = dictionary[@"filters"];
  [filter addPredicates:[[filters.rac_sequence
                            map:^SCPredicate *(NSDictionary *dictionary) {
                              return [SCPredicate predicateFromDict:dictionary];
                            }] array]];
  return filter;
}

+ (instancetype)filterFromDictionaryArray:(NSArray *)arr {
  SCQueryFilter *filter = [[SCQueryFilter alloc] init];
  [filter addPredicates:[[arr.rac_sequence
                            map:^SCPredicate *(NSDictionary *dictionary) {
                              return [SCPredicate predicateFromDict:dictionary];
                            }] array]];
  return filter;
}

- (void)addPredicate:(SCPredicate *)pred {
  [self.predicates addObject:pred];
}

- (void)addPredicates:(NSArray *)preds {
  [self.predicates addObjectsFromArray:preds];
}

- (void)addLayerId:(NSString *)layerId {
  [self.layerIds addObject:layerId];
}

- (void)addLayerIds:(NSArray *)lIds {
  [self.layerIds addObjectsFromArray:lIds];
}

- (BOOL)testValue:(id)value {
  __block BOOL allTrue = YES;
  [self.predicates enumerateObjectsUsingBlock:^(SCPredicate *pred,
                                                NSUInteger idx, BOOL *stop) {
    if (![pred compare:value]) {
      allTrue = NO;
      *stop = YES;
    }
  }];
  return allTrue;
}

@end
