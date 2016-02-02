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

#import "SCGpkgContent.h"
#import "SCGpkgFeatureSource.h"

NSString *const kCTTableName = @"gpkg_contents";
NSString *const kCTTableNameColName = @"table_name";
NSString *const kCTDataTypeColName = @"data_type";
NSString *const kCTIdentifierColName = @"identifier";
NSString *const kCTDescriptionColName = @"description";
NSString *const kCTLastChangeColName = @"last_change";
NSString *const kCTMinXColName = @"min_x";
NSString *const kCTMinYColName = @"min_y";
NSString *const kCTMaxXColName = @"max_x";
NSString *const kCTMaxYColName = @"max_y";
NSString *const kCTSRSIdColName = @"srs_id";

@implementation SCGpkgContentsTable

- (id)initWithQueue:(FMDatabaseQueue *)q {
  return [super initWithQueue:q tableName:kCTTableName];
}

- (RACSignal *)all {
  NSString *sql = [self allQueryString];
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.queue inDatabase:^(FMDatabase *db) {
          FMResultSet *resultSet = [db executeQuery:sql];
          while ([resultSet next]) {
            SCGpkgContent *c =
                [[SCGpkgContent alloc] initWithResultSet:resultSet];
            [subscriber sendNext:c];
          }
          [resultSet close];
          [subscriber sendCompleted];
        }];
        return nil;
      }];
}

- (RACSignal *)tiles {
  NSString *sql = @"SELECT * FROM gpkg_contents WHERE data_type = 'tiles'";
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.queue inDatabase:^(FMDatabase *db) {
          FMResultSet *resultSet = [db executeQuery:sql];
          while ([resultSet next]) {
            SCGpkgContent *c =
                [[SCGpkgContent alloc] initWithResultSet:resultSet];
            [subscriber sendNext:c];
          }
          [resultSet close];
          [subscriber sendCompleted];
        }];
        return nil;
      }];
}

- (NSArray *)vectors {
  NSString *sql = @"SELECT * FROM gpkg_contents WHERE data_type = 'features'";
  return
      [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.queue inDatabase:^(FMDatabase *db) {
          FMResultSet *resultSet = [db executeQuery:sql];
          while ([resultSet next]) {
            SCGpkgContent *c =
                [[SCGpkgContent alloc] initWithResultSet:resultSet];
            [subscriber sendNext:c];
          }
          [resultSet close];
          [subscriber sendCompleted];
        }];
        return nil;
      }] toArray];
}

@end
