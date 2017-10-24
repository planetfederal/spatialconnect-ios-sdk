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
#import "SCBoundingBox.h"
#import "SCFIlterEqual.h"
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
#import "SCGeoFilterContains.h"
#import "SCGeoFilterDisjoint.h"
#import "SCGeoJSON.h"
#import "SCJavascriptCommands.h"

@interface SCPredicate (Private)
- (void)setComparator:(NSInteger)c;
- (BOOL)checkWithin:(id)value;
@end

@implementation SCPredicate

@synthesize filter = _filter;

+ (instancetype)predicateType:(NSString *)type clause:(NSObject *)clause {
  if ([type isEqualToString:SCJS_GEO_CONTAINS]) {
    NSArray *coords = (NSArray *)clause;
    SCBoundingBox *bbox = [[SCBoundingBox alloc] initWithCoords:coords];
    SCGeoFilterContains *f = [[SCGeoFilterContains alloc] initWithBBOX:bbox];
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
