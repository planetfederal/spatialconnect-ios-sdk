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

#import "SCFilterLessThan.h"

@implementation SCFilterLessThan

- (NSString *)asSQL {
  NSAssert(keyPath, @"KeyPath must be set");
  return [NSString
      stringWithFormat:@"%@ < %@", (NSString *)keyPath, (NSString *)rhs];
}

- (BOOL)compareLHS:(NSObject *)lhs {
  NSAssert(lhs, @"Upper Value must be set");
  if ([lhs isKindOfClass:[NSNumber class]]) {
    NSAssert([rhs isKindOfClass:[NSNumber class]],
             @"Value should be of type NSNumber");
    NSNumber *rhsNum = (NSNumber *)rhs;
    NSNumber *lhsNum = (NSNumber *)lhs;
    NSComparisonResult cr = [lhsNum compare:rhsNum];
    if (cr == NSOrderedAscending) {
      return YES;
    } else {
      return NO;
    }
  } else if ([lhs isKindOfClass:[NSString class]]) {
    NSAssert([rhs isKindOfClass:[NSString class]],
             @"RHS should be of type NSString");
    NSString *rhsStr = (NSString *)rhs;
    NSString *lhsStr = (NSString *)lhs;
    NSComparisonResult cr = [lhsStr compare:rhsStr];
    if (cr == NSOrderedAscending) {
      return YES;
    } else {
      return NO;
    }
  }
  return NO;
}

@end
