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
 * See the License for the specific language governing permissions and limitations under the License
 */

#import "SCKeyTuple.h"
#import "SCQueryFilter.h"
#import "SCSpatialFeature.h"

@protocol SCSpatialStore <NSObject>

@required

/**
 *  Returns SCSpatialFeature on the returned signal
 *
 *  @param filter
 *
 *  @return SCSpatialFeature
 */
- (RACSignal *)query:(SCQueryFilter *)filter;

- (RACSignal *)queryById:(SCKeyTuple *)key;

/**
 *  Returns RACSignal completion on successful creation
 *  if the layerId ivar in the feature is empty it will go
 *  to the default store.
 *
 *  @param feature SCSpatialFeature to be written to store
 *
 *  @return RACSignal - Completion
 */
- (RACSignal *)create:(SCSpatialFeature *)feature;

/**
 *  Returns RACSignal completion on successful update
 *
 *  @param feature to be updated
 *
 *  @return RACSignal - Completion
 */
- (RACSignal *)update:(SCSpatialFeature *)feature;

/**
 *  Returns RACSignal completion on successful delete
 *
 *  @param feature to be deleted
 *
 *  @return RACSignal - Completion
 */
- (RACSignal *) delete:(SCKeyTuple *)key;

/**
 *  Default layer to be used when no layer is present in
 *  SCSpatialFeature's layerId ivar
 *
 *  @return string representing layer name
 */
- (NSString *)defaultLayerName;

/**
 *  List of layers in the store
 *
 *  @return RACSignla - NSArray of strings
 */
- (RACSignal *)layerList;

@end
