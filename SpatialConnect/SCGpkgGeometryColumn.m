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
@interface SCGpkgGeometryColumn ()

@property(strong, nonatomic, readwrite) NSString *tableName;
@property(strong, nonatomic, readwrite) NSString *columnName;
@property(strong, nonatomic, readwrite) NSString *geometryTypeName;
@property(nonatomic, readwrite) NSInteger srsId;
@property(nonatomic, readwrite) NSInteger z;
@property(nonatomic, readwrite) NSInteger m;

@end

@implementation SCGpkgGeometryColumn

- (id)initWithResultSet:(FMResultSet *)rs {
  self = [super init];
  if (self) {
    self.tableName = [rs stringForColumn:kGCTableNameColName];
    self.columnName = [rs stringForColumn:kGCColumnNameColName];
    self.geometryTypeName = [rs stringForColumn:kGCGeometryTypeNameColName];
    self.srsId = [rs intForColumn:kGCSrsIdColName];
    self.z = [rs intForColumn:kGCZColName];
    self.m = [rs intForColumn:kGCMColName];
  }
  return self;
}

@end
