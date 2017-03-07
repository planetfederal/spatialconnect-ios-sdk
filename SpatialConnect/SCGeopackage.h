/*!***************************************************************************
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 ******************************************************************************/

#import "SCGpkgContentsTable.h"
#import "SCGpkgExtensionsTable.h"
#import "SCGpkgFeatureSource.h"
#import "SCGpkgTileSource.h"
#import <Foundation/Foundation.h>
@interface SCGeopackage : NSObject

@property(nonatomic, strong) FMDatabasePool *pool;

/*!
 *  @brief Initializes a geopackage object with a geopackage file
 *
 *  @param filepath path to gpkg file
 *
 *  @return instance of SCGeopackage
 */
- (id)initWithFilename:(NSString *)filepath;
- (id)initEmptyGeopackageWithFilename:(NSString *)filepath;

- (void)close;

/*!
 *  @brief Array of SCGpkgContent objects
 *
 *  @return NSArray of SCGpkgContent objects
 */
- (RACSignal *)contents;

/*!
 *  @brief SCGpkgExtensions
 *
 *  @return RACSignal
 */
- (RACSignal *)extensions;

/*!
 *  @brief SCTileContent
 *
 *  @return RACSignal
 */
- (NSArray *)tileContents;

/*!
 *  @brief VectorFile
 *
 *  @return RACSignal
 */
- (NSArray *)featureContents;

- (NSArray *)auditTables;

- (SCGpkgFeatureSource *)featureSource:(NSString *)name;

- (SCGpkgTileSource *)tileSource:(NSString *)name;

- (RACSignal *)query:(SCQueryFilter *)filter;

- (RACSignal *)unSynced;

- (void)addFeatureSource:(NSString *)name withTypes:(NSDictionary *)types;
- (void)removeFeatureSource:(NSString *)name;

@end
