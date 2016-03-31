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

#import "SCGpkgExtension.h"
#import "SCGpkgExtensionsTable.h"

@interface SCGpkgExtension ()

@property(strong, nonatomic, readwrite) NSString *tableName;
@property(strong, nonatomic, readwrite) NSString *columnName;
@property(strong, nonatomic, readwrite) NSString *extensionName;
@property(strong, nonatomic, readwrite) NSString *definition;
@property(strong, nonatomic, readwrite) NSString *scope;

@end

@implementation SCGpkgExtension

- (id)initWithResultSet:(FMResultSet *)rs {
  self = [super init];
  if (self) {
    self.tableName = [rs stringForColumn:kETTableNameColName];
    self.columnName = [rs stringForColumn:kETColumnNameColName];
    self.extensionName = [rs stringForColumn:kETExtensionNameColName];
    self.definition = [rs stringForColumn:kETDefinitionColName];
    self.scope = [rs stringForColumn:kETScopeColName];
  }
  return self;
}

@end
