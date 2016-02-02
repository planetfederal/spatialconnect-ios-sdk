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

#import "SCGpkgDataColumn.h"
#import "SCGpkgDataColumnsTable.h"

@interface SCGpkgDataColumn ()

@property(strong, nonatomic, readwrite) NSString *columnName;
@property(strong, nonatomic, readwrite) NSString *name;
@property(strong, nonatomic, readwrite) NSString *title;
@property(strong, nonatomic, readwrite) NSString *constraintName;
@property(strong, nonatomic, readwrite) NSString *desc;
@property(strong, nonatomic, readwrite) NSString *mimeType;

@end

@implementation SCGpkgDataColumn

- (id)initWithResultSet:(FMResultSet *)rs {
  self = [super init];
  if (self) {
    tableName = [rs stringForColumn:kDCTableNameColName];
    self.columnName = [rs stringForColumn:kDCColumnNameColName];
    self.name = [rs stringForColumn:kDCNameColName];
    self.title = [rs stringForColumn:kDCTitleColName];
    self.desc = [rs stringForColumn:kDCDescriptionColName];
    self.mimeType = [rs stringForColumn:kDCMimeTypeColName];
  }
  return self;
}

@end
