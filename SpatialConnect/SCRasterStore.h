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
#import <MapKit/MapKit.h>

@protocol SCRasterStore <NSObject>

/**
 Binds a raster layer to a Tile Renderer used by Apple's MapKit

 @param layer name of the raster layer
 @param mapView Reference to a MKMapView instance
 @return MKTileOverlay for MKMapkit usage
 */
- (MKTileOverlay *)overlayFromLayer:(NSString *)layer
                            mapview:(MKMapView *)mapView;

/**
 Returns the coverage polygon for a raster layer

 @param layer Raster layer name
 @return Returns an SCPolygon the represents the imagery footprint
 */
- (SCPolygon *)coverage:(NSString *)layer;

/**
 Retrieves a list of Raster Layers

 @return List of raster layer names
 */
- (NSArray<NSString *> *)rasterLayers;

@end
