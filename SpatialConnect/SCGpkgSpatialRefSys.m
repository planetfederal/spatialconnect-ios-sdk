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

#import "SCGpkgSpatialRefSys.h"
#import "SCGpkgSpatialRefSysTable.h"

NSString *const kTableName = @"gpkg_spatial_ref_sys";

@interface SCGpkgSpatialRefSys ()

@property(strong, readwrite) NSString *srsName;
@property(readwrite) NSInteger srsId; // PK
@property(strong, readwrite) NSString *organization;
@property(readwrite) NSInteger organizationCoordSysId;
@property(strong, readwrite) NSString *definition;
@property(strong, readwrite) NSString *desc;

@end

@implementation SCGpkgSpatialRefSys

- (id)initWithResultSet:(FMResultSet *)rs {
  self = [super init];
  if (self) {
    self.srsName = [rs stringForColumn:kSRSSrsNameColName];
    self.srsId = [rs intForColumn:kSRSSrsIdColName];
    self.organization = [rs stringForColumn:kSRSOrganizationColName];
    self.organizationCoordSysId =
        [rs intForColumn:kSRSOrganizationCoordSysIdColName];
    self.definition = [rs stringForColumn:kSRSDefinitionColName];
    self.desc = [rs stringForColumn:kSRSDescriptionColName];
  }
  return self;
}

@end
