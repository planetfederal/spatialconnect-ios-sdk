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

#import "SCGpkgContent.h"
#import "SCGpkgContentsTable.h"

@interface SCGpkgContent ()

@property(strong, readwrite) NSString *tableName;
@property(strong, readwrite) NSString *dataType;
@property(strong, readwrite) NSString *identifier;
@property(strong, readwrite) NSString *desc;
@property(strong, readwrite) NSDate *lastChange;
@property(strong, readwrite) SCBoundingBox *bbox;
@property(strong, readwrite) SCGpkgContentsTable *table;
@property(readwrite) NSInteger crs;
@end

@implementation SCGpkgContent

@synthesize tableName, dataType, identifier, desc, lastChange, bbox, table, crs;

- (id)initWithResultSet:(FMResultSet *)rs {
  self = [super init];
  if (self) {
    self.tableName = [rs stringForColumn:kCTTableNameColName];
    self.dataType = [rs stringForColumn:kCTDataTypeColName];
    self.identifier = [rs stringForColumn:kCTIdentifierColName];
    self.desc = [rs stringForColumn:kCTDescriptionColName];
    self.crs = [rs intForColumn:kCTOrgCsysIdName];
    self.lastChange = [rs dateForColumn:kCTLastChangeColName];
    int minX = [rs intForColumn:kCTMinXColName];
    int minY = [rs intForColumn:kCTMinYColName];
    int maxX = [rs intForColumn:kCTMaxXColName];
    int maxY = [rs intForColumn:kCTMaxYColName];
    self.bbox = [[SCBoundingBox alloc]
        initWithCoords:@[ @(minX), @(minY), @(maxX), @(maxY) ]
                   crs:self.crs];
  }
  return self;
}

@end
