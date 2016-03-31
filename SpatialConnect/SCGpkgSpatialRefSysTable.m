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

#import "SCGpkgSpatialRefSys.h"
#import "SCGpkgSpatialRefSysTable.h"

NSString *const kSRSTableName = @"gpkg_spatial_ref_sys";

NSString *const kSRSSrsNameColName = @"srs_name";
NSString *const kSRSSrsIdColName = @"srs_id";
NSString *const kSRSOrganizationColName = @"organization";
NSString *const kSRSOrganizationCoordSysIdColName = @"organization_coordsys_id";
NSString *const kSRSDefinitionColName = @"definition";
NSString *const kSRSDescriptionColName = @"description";

@implementation SCGpkgSpatialRefSysTable

- (id)initWithQueue:(FMDatabaseQueue *)q {
  return [super initWithQueue:q tableName:kSRSTableName];
}

- (NSString *)allQueryString {
  return [NSString stringWithFormat:@"SELECT * FROM %@", kTableName];
}

- (RACSignal *)all {
  NSString *sql = [self allQueryString];
  @weakify(self);
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        [self.queue inDatabase:^(FMDatabase *db) {
          FMResultSet *resultSet = [db executeQuery:sql];
          while ([resultSet next]) {
            SCGpkgSpatialRefSys *e =
                [[SCGpkgSpatialRefSys alloc] initWithResultSet:resultSet];
            [subscriber sendNext:e];
          }
          [resultSet close];
          [subscriber sendCompleted];
        }];
        return nil;
      }];
}

@end
