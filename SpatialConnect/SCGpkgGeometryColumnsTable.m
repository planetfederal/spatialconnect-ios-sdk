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

#import "SCGpkgGeometryColumn.h"
#import "SCGpkgGeometryColumnsTable.h"

NSString *const kGCTableName = @"gpkg_geometry_columns";
NSString *const kGCTableNameColName = @"table_name";
NSString *const kGCColumnNameColName = @"column_name";
NSString *const kGCGeometryTypeNameColName = @"geometry_type_name";
NSString *const kGCSrsIdColName = @"srs_id";
NSString *const kGCZColName = @"z";
NSString *const kGCMColName = @"m";

@implementation SCGpkgGeometryColumnsTable

- (id)initWithPool:(FMDatabasePool *)p {
  return [super initWithPool:p tableName:kGCTableName];
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
            SCGpkgGeometryColumn *gc =
                [[SCGpkgGeometryColumn alloc] initWithResultSet:resultSet];
            [subscriber sendNext:gc];
          }
          [resultSet close];
          [subscriber sendCompleted];
        }];
        return nil;
      }];
}

@end
