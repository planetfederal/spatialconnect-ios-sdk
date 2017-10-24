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
#import "SCGeoFilter.h"

@interface SCQueryFilter ()
@property(readwrite) NSMutableArray *predicates;
@property(readwrite) NSMutableArray *layerIds;
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
  limit = 100;
  _predicates = [NSMutableArray new];
  _layerIds = [NSMutableArray new];
  return self;
}

+ (instancetype)filterFromDictionary:(NSDictionary *)dictionary {
  __block SCQueryFilter *filter = [[SCQueryFilter alloc] init];
  [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSObject *obj,
                                                  BOOL *stop) {
    SCPredicate *p = [SCPredicate predicateType:key clause:obj];
    if (p) {
      [filter addPredicate:p];
    }
  }];
  NSNumber *l = dictionary[@"limit"];
  if (l) {
    filter.limit = l.integerValue;
  }
  [filter addLayerIds:dictionary[@"layerIds"]];
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

- (NSString *)buildWhereClause {
  __block NSMutableString *where = [NSMutableString new];
  [[self propertyFilters] enumerateObjectsUsingBlock:^(
                              SCPredicate *pred, NSUInteger idx, BOOL *stop) {
    if (idx != 0) {
      [where appendString:@" AND "];
    }
    NSString *sql = [pred.filter asSQL];
    [where appendString:sql];
  }];
  return where;
}

- (NSArray *)geometryFilters {
  NSMutableArray *arr = [NSMutableArray new];

  [self.predicates enumerateObjectsUsingBlock:^(SCPredicate *p, NSUInteger idx,
                                                BOOL *_Nonnull stop) {
    if ([p.filter isKindOfClass:[SCGeoFilter class]]) {
      [arr addObject:p];
    }
  }];

  return [NSArray arrayWithArray:arr];
}

- (NSArray *)propertyFilters {
  NSMutableArray *arr = [NSMutableArray new];

  [self.predicates enumerateObjectsUsingBlock:^(SCPredicate *p, NSUInteger idx,
                                                BOOL *_Nonnull stop) {
    if (![p.filter isKindOfClass:[SCGeoFilter class]]) {
      [arr addObject:p];
    }
  }];

  return [NSArray arrayWithArray:arr];
}

@end
