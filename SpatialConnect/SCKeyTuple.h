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

#import <Foundation/Foundation.h>

@interface SCKeyTuple : NSObject

@property(readonly, nonatomic) NSString *storeId;
@property(readonly, nonatomic) NSString *layerId;
@property(readonly, nonatomic) NSString *featureId;
@property(readonly, nonatomic) NSString *encodedCompositeKey;

/**
 *  Creates an SCKeyTuple from a base64 encoded key
 *
 *  @param cKey format is <base64>.<base64>.<base64>
 *
 *  @return <#return value description#>
 */
+ (instancetype)tupleFromEncodedCompositeKey:(NSString *)cKey;

- (id)initWithStoreId:(NSString *)s
              layerId:(NSString *)l
            featureId:(NSString *)f;

@end
