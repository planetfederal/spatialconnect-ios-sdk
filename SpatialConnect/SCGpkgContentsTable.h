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

#import "SCBoundingBox.h"
#import "SCGpkgTable.h"
#import "SCGpkgTableProtocol.h"

extern NSString *const kCTTableNameColName;
extern NSString *const kCTDataTypeColName;
extern NSString *const kCTIdentifierColName;
extern NSString *const kCTDescriptionColName;
extern NSString *const kCTLastChangeColName;
extern NSString *const kCTMinXColName;
extern NSString *const kCTMinYColName;
extern NSString *const kCTMaxXColName;
extern NSString *const kCTMaxYColName;
extern NSString *const kCTSRSIdColName;

@interface SCGpkgContentsTable : SCGpkgTable <SCGpkgTableProtocol>
- (id)initWithPool:(FMDatabasePool *)pool;
- (NSArray *)tiles;
- (NSArray *)vectors;
@end