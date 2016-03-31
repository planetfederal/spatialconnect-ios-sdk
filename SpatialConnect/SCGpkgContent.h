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

#import "SCBoundingBox.h"
#import "SCGpkgContentsTable.h"
#import "SCQueryFilter.h"

@interface SCGpkgContent : NSObject

@property(strong, readonly) NSString *tableName; // PK
@property(strong, readonly) NSString *dataType;
@property(strong, readonly) NSString *identifier;
@property(strong, readonly) NSString *desc;
@property(strong, readonly) NSDate *lastChange;
@property(strong, readonly) SCBoundingBox *bbox;
@property(readonly) NSInteger srsId; // FK
@property(strong, readonly) SCGpkgContentsTable *table;

- (id)initWithResultSet:(FMResultSet *)rs;

@end
