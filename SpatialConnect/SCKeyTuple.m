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

#import "SCKeyTuple.h"

@interface SCKeyTuple (private)
@property(readwrite, nonatomic, strong) NSString *storeId;
@property(readwrite, nonatomic, strong) NSString *layerId;
@property(readwrite, nonatomic, strong) NSString *featureId;
+ (NSString *)encodeString:(NSString *)s;
+ (NSString *)decodeString:(NSString *)s;
@end

@implementation SCKeyTuple

@synthesize storeId, layerId, featureId;

+ (instancetype)tupleFromEncodedCompositeKey:(NSString *)cKey {
  NSArray *strs = [cKey componentsSeparatedByString:@"."];
  NSString *store = [SCKeyTuple decodeString:strs[0]];
  NSString *layer = [SCKeyTuple decodeString:strs[1]];
  NSString *feat = [SCKeyTuple decodeString:strs[2]];
  NSAssert(strs.count == 3, @"CompKey contains 3 keys");
  SCKeyTuple *kt =
      [[SCKeyTuple alloc] initWithStoreId:store layerId:layer featureId:feat];

  return kt;
}

- (id)initWithStoreId:(NSString *)s
              layerId:(NSString *)l
            featureId:(NSString *)f {
  if (self = [super init]) {
    self.storeId = s;
    self.layerId = l;
    self.featureId = f;
  }
  return self;
}

- (void)setStoreId:(NSString *)s {
  NSParameterAssert(![s containsString:@"."]);
  storeId = s;
}

- (void)setLayerId:(NSString *)l {
  NSParameterAssert(![l containsString:@"."]);
  layerId = l;
}

- (void)setFeatureId:(NSString *)f {
  NSParameterAssert(![f containsString:@"."]);
  featureId = f;
}

/**
 *  This is used to encode strings as base64. This allows
 *  for keys to have '.' within them.
 *
 *  @param s
 *
 *  @return base64 string
 */
+ (NSString *)encodeString:(NSString *)s {
  return [[s dataUsingEncoding:NSUTF8StringEncoding]
      base64EncodedStringWithOptions:0];
}

+ (NSString *)decodeString:(NSString *)s {
  NSData *nsdataFromBase64String =
      [[NSData alloc] initWithBase64EncodedString:s options:0];
  return [[NSString alloc] initWithData:nsdataFromBase64String
                               encoding:NSUTF8StringEncoding];
}

- (NSString *)encodedCompositeKey {
  return
      [NSString stringWithFormat:@"%@.%@.%@", [SCKeyTuple encodeString:storeId],
                                 [SCKeyTuple encodeString:layerId],
                                 [SCKeyTuple encodeString:featureId]];
}

@end
