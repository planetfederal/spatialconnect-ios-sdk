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

#import "GeoJSONAdapter.h"
#import "SCQueryFilter.h"
#import "SCGeoJSON.h"
#import "SCGeometry+GeoJSON.h"
#import "SCGeometryCollection+GeoJSON.h"

#define ADAPTER_TYPE @"geojson"
#define ADAPTER_VERSION 1

@interface GeoJSONAdapter (Private)
- (RACSignal *)writeGeometryToFile:(SCGeometry *)geom;
@end

@implementation GeoJSONAdapter

@synthesize connector;

- (id)initWithFilePath:(NSString *)filepath {
  if (self = [super init]) {
    if (!filepath) {
      NSLog(@"Whoa");
    }
    geojsonFilePath = filepath;
  }
  return self;
}

- (void)connect {
  self.connector =
      [[GeoJSONStorageConnector alloc] initWithFileName:geojsonFilePath];
}

- (void)supportedQueries {
}

- (NSString *)adapterType {
  return ADAPTER_TYPE;
}

- (int)adapterVersion {
  return ADAPTER_VERSION;
}

- (NSString *)name {
  return self.name;
}

- (NSArray *)layerList {
  return nil;
}

- (RACSignal *)query:(SCQueryFilter *)filter {
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSError *readError = nil;
        NSDictionary *dict = [self.connector read:&readError];
        if (readError) {
          [subscriber sendError:readError];
        }
        SCGeometry *geom = [SCGeoJSON parseDict:dict];
        if (!geom.style) {
          [geom.style addMissing:self.defaultStyle];
        }
        [subscriber sendNext:geom];
        [subscriber sendCompleted];
        return nil;
      }];
}

- (RACSignal *)create:(SCSpatialFeature *)feature {
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        RACSignal *write =
            [[[self query:nil] map:^SCGeometry *(SCGeometry *geom) {
              SCGeometry *geomToWrite;
              if ([geom isKindOfClass:SCGeometryCollection.class]) {
                SCGeometryCollection *geomc = (SCGeometryCollection *)geom;
                [geomc.geometries addObject:feature];
                geomToWrite = geomc;
              } else {
                geomToWrite = [[SCGeometryCollection alloc]
                    initWithGeometriesArray:@[ geom, feature ]];
              }
              return geomToWrite;
            }] flattenMap:^RACStream *(SCGeometry *geomToWrite) {
              return [self writeGeometryToFile:geomToWrite];
            }];

        [write subscribeError:^(NSError *error) {
          [subscriber sendError:error];
        } completed:^{
          [subscriber sendCompleted];
        }];
        return nil;
      }];
}

- (RACSignal *)update:(SCSpatialFeature *)feature {
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [[[[self query:nil] map:^SCGeometry *(SCGeometry *geom) {
          if ([geom isKindOfClass:SCGeometryCollection.class]) {
            SCGeometryCollection *geomc = (SCGeometryCollection *)geom;
            [geomc.geometries
                enumerateObjectsUsingBlock:^(SCGeometry *g, NSUInteger idx,
                                             BOOL *stop) {
                  if ([feature.identifier isEqualToString:g.identifier]) {
                    g = (SCGeometry *)feature;
                    *stop = YES;
                  }
                }];
          }
          return geom;
        }] flattenMap:^RACStream *(SCGeometry *g) {
          return [self writeGeometryToFile:g];
        }] subscribeError:^(NSError *error) {
          [subscriber sendError:error];
        } completed:^{
          [subscriber sendCompleted];
        }];
        return nil;
      }];
}

- (RACSignal *) delete:(SCSpatialFeature *)feature {
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        RACSignal *write =
            [[[self query:nil] map:^SCGeometry *(SCGeometry *geom) {
              SCGeometry *geomToWrite;
              if ([geom isKindOfClass:SCGeometryCollection.class]) {
                SCGeometryCollection *geomc = (SCGeometryCollection *)geom;
                [geomc.geometries removeObject:feature];
                geomToWrite = geomc;
              } else {
                geomToWrite = [[SCGeometry alloc] init];
              }
              return geomToWrite;
            }] flattenMap:^RACStream *(SCGeometry *geomToWrite) {
              return [self writeGeometryToFile:geomToWrite];
            }];

        [write subscribeError:^(NSError *error) {
          [subscriber sendError:error];
        } completed:^{
          [subscriber sendCompleted];
        }];
        return nil;
      }];
}

#pragma mark -
#pragma mark Private Methods

- (RACSignal *)writeGeometryToFile:(SCGeometry *)geom {
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSString *string =
            [NSString stringWithFormat:@"%@", geom.geoJSONString];
        NSError *writeError = nil;
        [string writeToFile:geojsonFilePath
                 atomically:YES
                   encoding:NSUTF8StringEncoding
                      error:&writeError];
        NSLog(@"%@", writeError.localizedFailureReason);
        if (writeError) {
          [subscriber sendError:writeError];
        } else {
          [subscriber sendCompleted];
        }
        return nil;
      }];
}

@end
