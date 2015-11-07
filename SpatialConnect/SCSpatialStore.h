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
- (RACSignal *)queryAllLayers:(SCQueryFilter *)filter;

/**
 *  Returns SCSpatialFeature on the returned signal
 *
 *  @param layerId the id of the layer registered in the store
 *  @param filter used to bring back only valid data
 *
 *  @return RACSignal
 */
- (RACSignal *)queryByLayerId:(NSString *)layerId
                   withFilter:(SCQueryFilter *)filter;

/**
 *  Returns RACSignal completion on successful creation
 *  if the layerId ivar in the feature is empty it will go
 *  to the default store.
 *
 *  @param feature SCSpatialFeature to be written to store
 *
 *  @return RACSignal - Completion
 */
- (RACSignal *)createFeature:(SCSpatialFeature *)feature;

/**
 *  Returns RACSignal completion on successful update
 *
 *  @param feature to be updated
 *
 *  @return RACSignal - Completion
 */
- (RACSignal *)updateFeature:(SCSpatialFeature *)feature;

/**
 *  Returns RACSignal completion on successful delete
 *
 *  @param feature to be deleted
 *
 *  @return RACSignal - Completion
 */
- (RACSignal *)deleteFeature:(NSString *)identifier;

@optional

- (RACSignal *)layerList;

- (RACSignal *)createFeature:(SCSpatialFeature *)feature
                     inLayer:(NSString *)layerId;

- (RACSignal *)moveFeature:(SCSpatialFeature *)feature
                   toLayer:(NSString *)layerId;

- (RACSignal *)moveFeatureToDefaultLayer:(SCSpatialFeature *)feature;

- (RACSignal *)moveFeatures:(NSArray *)features toLayer:(NSString *)layerId;

- (RACSignal *)moveFeaturesToDefaultLayer:(NSArray *)features;

@end
