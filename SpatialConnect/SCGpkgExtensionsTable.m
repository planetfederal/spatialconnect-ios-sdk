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

#import "SCGpkgExtensionsTable.h"

NSString *const kETTableName = @"gpkg_extensions";
NSString *const kETTableNameColName = @"table_name";
NSString *const kETColumnNameColName = @"column_name";
NSString *const kETExtensionNameColName = @"extension_name";
NSString *const kETDefinitionColName = @"definition";
NSString *const kETScopeColName = @"scope";

@implementation SCGpkgExtensionsTable

- (id)initWithQueue:(FMDatabaseQueue *)q {
  return [super initWithQueue:q tableName:kETTableName];
}

- (RACSignal *)all {
  NSString *sql = [self allQueryString];
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.queue inDatabase:^(FMDatabase *db) {
          FMResultSet *resultSet = [db executeQuery:sql];
          while ([resultSet next]) {
            SCGpkgExtension *e =
                [[SCGpkgExtension alloc] initWithResultSet:resultSet];
            [subscriber sendNext:e];
          }
          [resultSet close];
          [subscriber sendCompleted];
        }];
        return nil;
      }];
}

@end
