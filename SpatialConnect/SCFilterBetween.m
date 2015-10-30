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

#import "SCFilterBetween.h"

@implementation SCFilterBetween

- (id)initWithUpper:(NSObject *)u
              lower:(NSObject *)l
         andKeyPath:(NSString *)keypath {
  self = [super init];
  if (!self) {
    return nil;
  }
  keyPath = keypath;
  upper = u;
  lower = l;
  return self;
}

- (NSString *)asSQL {
  NSAssert(keyPath, @"KeyPath must be set");
  return [NSString stringWithFormat:@"%@ BETWEEN %@ AND %@",
                                    (NSString *)keyPath, lower, upper];
}

- (BOOL)compareLHS:(NSObject *)v {
  NSAssert(upper, @"Upper Value must be set");
  NSAssert(lower, @"Lower Value must be set");
  if ([v isKindOfClass:[NSNumber class]]) {
    NSAssert([upper isKindOfClass:[NSNumber class]],
             @"Upper should be of type NSNumber");
    NSAssert([lower isKindOfClass:[NSNumber class]],
             @"Lower should be of type NSNumber");
    NSNumber *u = (NSNumber *)upper;
    NSNumber *l = (NSNumber *)lower;
    NSNumber *val = (NSNumber *)v;
    NSComparisonResult c1 = [val compare:u];
    NSComparisonResult c2 = [val compare:l];
    if (c1 == NSOrderedAscending && c2 == NSOrderedDescending) {
      return YES;
    } else {
      return NO;
    }
  } else if ([v isKindOfClass:[NSString class]]) {
    NSAssert([upper isKindOfClass:[NSString class]],
             @"Upper should be of type NSString");
    NSAssert([lower isKindOfClass:[NSString class]],
             @"Lower should be of type NSString");
    NSString *u = (NSString *)upper;
    NSString *l = (NSString *)lower;
    NSString *val = (NSString *)v;
    NSComparisonResult c1 = [val compare:u];
    NSComparisonResult c2 = [val compare:l];
    if (c1 == NSOrderedAscending && c2 == NSOrderedDescending) {
      return YES;
    } else {
      return NO;
    }
  }

  return NO;
}

- (NSObject *)upper {
  return upper;
}

- (NSObject *)lower {
  return lower;
}

@end
