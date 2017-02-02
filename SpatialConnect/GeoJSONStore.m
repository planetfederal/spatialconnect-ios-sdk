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

#import "GeoJSONStore.h"
#import "SCFileUtils.h"
#import "SCGeoJSON.h"
#import "SCGeometry+GeoJSON.h"
#import "SCGeometryCollection+GeoJSON.h"
#import "SCHttpUtils.h"
#import "SCQueryFilter.h"

#ifndef TEST
BOOL const isUnitTesting = NO;
#else
BOOL const isUnitTesting = YES;
#endif

NSString *const SCGeoJsonErrorDomain = @"SCGeoJsonErrorDomain";

@interface GeoJSONStore ()
@property(readwrite, nonatomic, strong) NSString *uri;
@end

@implementation GeoJSONStore

const int kVERSION = 1;
const NSString *kTYPE = @"geojson";
const NSString *kSTORE_NAME = @"GeoJSONStore";

- (id)initWithStoreConfig:(SCStoreConfig *)config {
  self = [super initWithStoreConfig:config];
  if (!self) {
    return nil;
  }
  self.name = config.name;
  self.uri = config.uri;
  geojsonFilePath = nil;
  filename = nil;
  return self;
}

- (id)initWithStoreConfig:(SCStoreConfig *)config withStyle:(SCStyle *)style {
  self = [self initWithStoreConfig:config];
  if (!self) {
    return nil;
  }
  self.style = style;
  return self;
}

- (NSString *)storeType {
  return [NSString stringWithFormat:@"%@", kTYPE];
}

- (NSInteger)version {
  return kVERSION;
}

- (NSArray *)layers {
  return self.vectorLayers;
}

- (NSArray *)vectorLayers {
  return @[ @"default" ];
}

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
        DDLogError(@"%@", writeError.localizedFailureReason);
        if (writeError) {
          [subscriber sendError:writeError];
        } else {
          [subscriber sendCompleted];
        }
        return nil;
      }];
}

- (NSString *)path {
  if (geojsonFilePath) {
    return geojsonFilePath;
  }
  NSString *path = nil;
  NSString *dbName = [NSString stringWithFormat:@"%@.geojson", self.storeId];
  BOOL saveToDocsDir = ![SCFileUtils isTesting];
  if (saveToDocsDir) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    path = [documentsDirectory stringByAppendingPathComponent:dbName];
  } else {
    path = [SCFileUtils filePathFromNSHomeDirectory:dbName];
  }
  return path;
}

- (void)write:(NSString *)str error:(NSError *)error {
  [str writeToFile:str
        atomically:YES
          encoding:NSUnicodeStringEncoding
             error:&error];
}

- (NSDictionary *)read:(NSError **)error {
  return [SCFileUtils jsonFileToDict:filename error:error];
}

#pragma mark -
#pragma mark SCSpatialStore
- (RACSignal *)query:(SCQueryFilter *)filter {
  return [
      [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSError *readError = nil;
        NSDictionary *dict = [self read:&readError];
        if (readError) {
          [subscriber sendError:readError];
        }
        if (dict) {
          SCGeometry *geom = [SCGeoJSON parseDict:dict];
          if (geom) {
            [subscriber sendNext:geom];
          }
        }
        [subscriber sendCompleted];
        return nil;
      }] flattenMap:^RACStream *(SCGeometry *g) {
        return [RACSignal
            createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
              if ([g isKindOfClass:SCGeometryCollection.class]) {
                SCGeometryCollection *scgc = (SCGeometryCollection *)g;
                for (SCGeometry *geom in scgc.geometries) {
                  geom.layerId = @"default";
                  geom.storeId = [NSString stringWithString:self.storeId];
                  if (!geom.style) {
                    [geom.style addMissing:self.defaultStyle];
                  }
                  [subscriber sendNext:geom];
                }
              } else {
                [subscriber sendNext:g];
              }
              [subscriber sendCompleted];
              return nil;
            }];
      }] filter:^BOOL(SCGeometry *value) {
        for (SCPredicate *p in filter.predicates) {
          if (![p compare:value]) {
            return NO;
          }
        }
        return YES;
      }] map:^SCGeometry *(SCGeometry *g) {
        g.layerId = self.layers[0];
        g.storeId = self.storeId;
        return g;
      }];
}

- (RACSignal *)queryById:(SCKeyTuple *)key {
  return nil;
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
        }
            completed:^{
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
            [geomc.geometries enumerateObjectsUsingBlock:^(
                                  SCGeometry *g, NSUInteger idx, BOOL *stop) {
              if ([feature.identifier isEqual:g.identifier]) {
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
        }
            completed:^{
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
        }
            completed:^{
              [subscriber sendCompleted];
            }];
        return nil;
      }];
}

#pragma mark -
#pragma mark SCDataStoreLifeCycle

- (RACSignal *)start {
  self.status = SC_DATASTORE_STARTED;
  if (self.uri != nil && [self.uri.lowercaseString containsString:@"http"]) {
    NSString *path = [self path];
    BOOL b = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (b) {
      self.status = SC_DATASTORE_RUNNING;
      filename = path;
      return [RACSignal empty];
    }

    return
        [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
          [[[super download:self.uri to:path]
              subscribeOn:[RACScheduler mainThreadScheduler]]
              subscribeNext:^(id x) {
                [subscriber sendNext:x];
              }
              error:^(NSError *error) {
                [subscriber sendError:error];
              }
              completed:^{
                filename = path;
                [subscriber sendCompleted];
              }];
          return nil;
        }];
  } else {
    NSString *filePath = nil;
    NSString *bundlePath = [SCFileUtils filePathFromMainBundle:self.uri];
    NSString *documentsPath =
        [SCFileUtils filePathFromDocumentsDirectory:self.uri];
    if (geojsonFilePath) {
      filePath = geojsonFilePath;
    } else if ([[NSFileManager defaultManager] fileExistsAtPath:bundlePath]) {
      filePath = bundlePath;
    } else if ([[NSFileManager defaultManager]
                   fileExistsAtPath:documentsPath]) {
      filePath = documentsPath;
    }
    return
        [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
          if (filePath != nil &&
              [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            filename = filePath;
            self.status = SC_DATASTORE_RUNNING;
            [subscriber sendCompleted];
          } else {
            NSError *err = [NSError errorWithDomain:SCGeoJsonErrorDomain
                                               code:SC_GEOJSON_FILENOTFOUND
                                           userInfo:nil];
            self.status = SC_DATASTORE_STOPPED;
            [subscriber sendError:err];
          }
          return nil;
        }];
  }
  return [RACSignal empty];
}

- (void)stop {
  self.status = SC_DATASTORE_STOPPED;
}

- (void)pause {
  self.status = SC_DATASTORE_PAUSED;
}

- (void)resume {
  self.status = SC_DATASTORE_RUNNING;
}

- (void)destroy {
  [super deleteFile:[self path]];
}

+ (NSString *)versionKey {
  return [NSString stringWithFormat:@"%@.%d", kTYPE, kVERSION];
}

@end
