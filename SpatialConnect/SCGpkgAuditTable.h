//
//  SCGpkgAuditTable.h
//  SpatialConnect
//
//  Created by Frank Rowe on 3/6/17.
//  Copyright © 2017 Boundless Spatial. All rights reserved.
//

#import <SpatialConnect/SpatialConnect.h>

@interface SCGpkgAuditTable : NSObject

@property(strong, readonly) NSString *auditTableName;

- (id)initWithResultSet:(FMResultSet *)rs;
- (RACSignal *)unsynced;

@end
