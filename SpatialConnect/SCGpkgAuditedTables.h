//
//  SCGpkgAuditedTables.h
//  SpatialConnect
//
//  Created by Frank Rowe on 3/6/17.
//  Copyright © 2017 Boundless Spatial. All rights reserved.
//
#import "SCBoundingBox.h"
#import "SCGpkgTable.h"
#import "SCGpkgTableProtocol.h"
#import <SpatialConnect/SpatialConnect.h>

extern NSString *const kCTTableName;
extern NSString *const kCTAuditTableNameColName;

@interface SCGpkgAuditedTables : SCGpkgTable  <SCGpkgTableProtocol>
- (id)initWithPool:(FMDatabasePool *)pool;
@end
