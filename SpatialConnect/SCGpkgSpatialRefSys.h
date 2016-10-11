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

#import "FMResultSet.h"
#import <Foundation/Foundation.h>

@interface SCGpkgSpatialRefSys : NSObject

@property(strong, nonatomic, readonly) NSString *srsName;
@property(readonly) NSInteger srsId; // PK
@property(strong, nonatomic, readonly) NSString *organization;
@property(readonly) NSInteger organizationCoordSysId;
@property(strong, nonatomic, readonly) NSString *definition;
@property(strong, nonatomic, readonly) NSString *desc;

- (id)initWithResultSet:(FMResultSet *)rs;

@end
