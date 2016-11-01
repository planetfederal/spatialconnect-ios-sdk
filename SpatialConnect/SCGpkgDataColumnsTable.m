/**
 * Copyright 2016 Boundless http://boundlessgeo.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License
 */

#import "SCGpkgDataColumnsTable.h"
#import "SCGpkgDataColumn.h"

NSString *const kDCTableName = @"gpkg_data_columns";
NSString *const kDCTableNameColName = @"table_name";
NSString *const kDCColumnNameColName = @"column_name";
NSString *const kDCNameColName = @"name";
NSString *const kDCTitleColName = @"title";
NSString *const kDCDescriptionColName = @"description";
NSString *const kDCMimeTypeColName = @"mime_type";
NSString *const kDCConstraintNameColName = @"constraint_name";

@implementation SCGpkgDataColumnsTable

- (id)initWithPool:(FMDatabasePool *)pool {
  return [super initWithPool:pool tableName:kDCTableName];
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
            SCGpkgDataColumn *e =
                [[SCGpkgDataColumn alloc] initWithResultSet:resultSet];
            [subscriber sendNext:e];
          }
          [resultSet close];
          [subscriber sendCompleted];
        }];
        return nil;
      }];
}

@end
