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

#import "SCRemoteDataStore.h"
#import "SCSpatialStore.h"
#import <SpatialConnect/SpatialConnect.h>

@interface WFSDataStore : SCRemoteDataStore <SCSpatialStore>

@property(readonly) NSString *baseUri;

/**
 Layers configured by the SpatialConnect server/SCConfig default_layers to be
 the default layers that are queried unless they are have and SCQueryFilter that
 overrides them with the filter.layerIds array.
 */
@property(readonly) NSArray *defaultLayers;

@end
