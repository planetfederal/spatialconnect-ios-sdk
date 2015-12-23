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

#import "SCPredicate.h"
#import "SCJavascriptCommands.h"
#import "SCFilter.h"
#import "SCFilterBetween.h"
#import "SCFilterGreaterThan.h"
#import "SCFilterGreaterThanEqual.h"
#import "SCFilterIn.h"
#import "SCFilterLessThan.h"
#import "SCFilterLessThanEqual.h"
#import "SCFilterLike.h"
#import "SCFilterNotBetween.h"
#import "SCFilterNotEqual.h"
#import "SCFilterNotIn.h"
#import "SCFilterNotLike.h"
#import "SCFIlterEqual.h"
#import "SCGeoFilterContains.h"
#import "SCGeoFilterDisjoint.h"
#import "SCGeoJSON.h"

@interface SCPredicate (Private)
- (void)setComparator:(NSInteger)c;
- (BOOL)checkWithin:(id)value;
@end

@implementation SCPredicate

@synthesize filter = _filter;

+ (instancetype)predicateFromDict:(NSDictionary *)d {
  NSDictionary *dict;
  if ((dict = d[SCJS_GEO_CONTAINS])) {
    SCGeometry *g = [SCGeoJSON parseDict:dict[@"geometry"]];
    NSString *k = dict[@"key"];
    SCGeoFilterContains *f =
        [[SCGeoFilterContains alloc] initWithGeometry:g andKeyPath:k];
    return [[SCPredicate alloc] initWithFilter:f];
  } else if ((dict = d[SCJS_GEO_DISJOINT])) {
    SCGeometry *g = [SCGeoJSON parseDict:dict[@"geometry"]];
    NSString *k = dict[@"key"];
    SCGeoFilterDisjoint *f =
        [[SCGeoFilterDisjoint alloc] initWithGeometry:g andKeyPath:k];
    return [[SCPredicate alloc] initWithFilter:f];
  } else if ((dict = d[SCJS_GREATER_THAN])) {
    NSObject *o = dict[@"value"];
    NSString *k = dict[@"key"];
    SCFilterGreaterThan *f =
        [[SCFilterGreaterThan alloc] initWithValue:o andKeyPath:k];
    return [[SCPredicate alloc] initWithFilter:f];
  } else if ((dict = d[SCJS_GREATER_THAN_EQUAL])) {
    NSObject *o = dict[@"value"];
    NSString *k = dict[@"key"];
    SCFilterGreaterThanEqual *f =
        [[SCFilterGreaterThanEqual alloc] initWithValue:o andKeyPath:k];
    return [[SCPredicate alloc] initWithFilter:f];
  } else if (dict[SCJS_LESS_THAN]) {
    NSObject *o = dict[@"value"];
    NSString *k = dict[@"key"];
    SCFilterLessThan *f =
        [[SCFilterLessThan alloc] initWithValue:o andKeyPath:k];
    return [[SCPredicate alloc] initWithFilter:f];
  } else if (dict[SCJS_LESS_THAN_EQUAL]) {
    NSObject *o = dict[@"value"];
    NSString *k = dict[@"key"];
    SCFilterLessThanEqual *f =
        [[SCFilterLessThanEqual alloc] initWithValue:o andKeyPath:k];
    return [[SCPredicate alloc] initWithFilter:f];
  } else if (dict[SCJS_EQUAL]) {
    NSObject *o = dict[@"value"];
    NSString *k = dict[@"key"];
    SCFilterEqual *f = [[SCFilterEqual alloc] initWithValue:o andKeyPath:k];
    return [[SCPredicate alloc] initWithFilter:f];
  } else if (dict[SCJS_NOT_EQUAL]) {
    NSObject *o = dict[@"value"];
    NSString *k = dict[@"key"];
    SCFilterNotEqual *f =
        [[SCFilterNotEqual alloc] initWithValue:o andKeyPath:k];
    return [[SCPredicate alloc] initWithFilter:f];
  } else if (dict[SCJS_BETWEEN]) {
    NSString *k = dict[@"key"];
    NSObject *upper = dict[@"upper"];
    NSObject *lower = dict[@"lower"];
    SCFilterBetween *f =
        [[SCFilterBetween alloc] initWithUpper:upper lower:lower andKeyPath:k];
    return [[SCPredicate alloc] initWithFilter:f];
  } else if (dict[SCJS_NOT_BETWEEN]) {
    NSString *k = dict[@"key"];
    NSObject *upper = dict[@"upper"];
    NSObject *lower = dict[@"lower"];
    SCFilterNotBetween *f = [[SCFilterNotBetween alloc] initWithUpper:upper
                                                                lower:lower
                                                           andKeyPath:k];

    return [[SCPredicate alloc] initWithFilter:f];
  } else if (dict[SCJS_IN]) {
    NSString *k = dict[@"key"];
    NSArray *values = [dict[@"values"] array];
    SCFilterIn *f = [[SCFilterIn alloc] initWithArray:values andKeyPath:k];
    return [[SCPredicate alloc] initWithFilter:f];
  } else if (dict[SCJS_NOT_IN]) {
    NSString *k = dict[@"key"];
    NSArray *values = [dict[@"values"] array];
    SCFilterNotIn *f =
        [[SCFilterNotIn alloc] initWithArray:values andKeyPath:k];
    return [[SCPredicate alloc] initWithFilter:f];
  } else if (dict[SCJS_LIKE]) {
    NSString *k = dict[@"key"];
    NSString *value = [dict[@"value"] stringValue];
    SCFilterLike *f = [[SCFilterLike alloc] initWithValue:value andKeyPath:k];
    return [[SCPredicate alloc] initWithFilter:f];
  } else if (dict[SCJS_NOT_LIKE]) {
    NSString *k = dict[@"key"];
    NSString *value = [dict[@"value"] stringValue];
    SCFilterLike *f = [[SCFilterLike alloc] initWithValue:value andKeyPath:k];
    return [[SCPredicate alloc] initWithFilter:f];
  }
  return nil;
}

- (id)init {
  if (self = [super init]) {
    return self;
  }
  return nil;
}

- (id)initWithFilter:(id<SCFilterProtocol>)filter {
  self = [self init];
  if (self) {
    _filter = filter;
  }
  return self;
}

- (BOOL)compare:(id)val {
  return [self.filter compareLHS:val];
}

@end
