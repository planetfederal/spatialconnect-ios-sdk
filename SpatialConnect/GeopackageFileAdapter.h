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

#import "SCGeopackage.h"
#import "SCQueryFilter.h"
#import "SCStoreConfig.h"
#import <Foundation/Foundation.h>

@class GeopackageStore;

#ifndef TEST
#define UNITTESTING YES;
#endif

@interface GeopackageFileAdapter : NSObject

@property(readonly, nonatomic, strong) NSString *uri;
@property(readonly, nonatomic, strong) NSString *filepath;
@property(readonly, nonatomic, strong) SCGeopackage *gpkg;
@property(nonatomic, weak) GeopackageStore *parentStore;

- (id)initWithFileName:(NSString *)dbname andURI:(NSString *)u;
- (RACSignal *)connect;
- (void)connectBlocking;
- (void)disconnect;

- (RACSignal *)query:(SCQueryFilter *)filter;
- (RACSignal *)queryById:(SCKeyTuple *)key;
- (RACSignal *)createFeature:(SCSpatialFeature *)feature;
- (RACSignal *)deleteFeature:(SCKeyTuple *)tuple;
- (RACSignal *)updateFeature:(SCSpatialFeature *)feature;
- (void)addLayer:(NSString *)name typeDefs:(NSDictionary *)t;
- (void)removeLayer:(NSString *)name;
- (NSArray *)layers;
- (NSArray *)rasterList;
- (NSString *)defaultLayerName;
- (MKTileOverlay *)overlayFromLayer:(NSString *)layer
                            mapview:(MKMapView *)mapView;
- (SCPolygon *)coverage:(NSString *)layer;

@end
