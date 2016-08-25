/*****************************************************************************
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

#import <Foundation/Foundation.h>
#import "SCSpatialStore.h"
#import "SCDataStore.h"
#import "GeoJSONAdapter.h"

extern const NSString *kTYPE;
extern const int *kVERSON;
extern const NSString *kSTORE_NAME;
extern NSString *const SCGeoJsonErrorDomain;

typedef NS_ENUM(NSInteger, SCGeoJsonError) {
  SC_GEOJSON_FILENOTFOUND = 1,
  SC_GEOJSON_ERRORDOWNLOADING = 2
};

@interface GeoJSONStore : SCDataStore <SCSpatialStore, SCDataStoreLifeCycle> {
  GeoJSONAdapter *adapter;
}

@end
