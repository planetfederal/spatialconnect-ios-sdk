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

#import "GeopackageFileAdapter.h"
#import "SCFileUtils.h"
#import "GeopackageStore.h"
#import "SCGeometry+GPKG.h"

@interface GeopackageFileAdapter (private)
- (BOOL)checkFile;
- (RACSignal *)attemptFileDownload;
- (GPKGGeoPackage *)openConnection;

@property(readwrite, nonatomic, strong) NSString *uri;
@property(readwrite, nonatomic, strong) NSString *filepath;
@property(readwrite, nonatomic, strong) NSString *storeId;
@property(readwrite, nonatomic, strong) GPKGGeoPackage *gpkg;

@end

@implementation GeopackageFileAdapter

@synthesize uri = _uri;
@synthesize filepath = _filepath;
@synthesize storeId = _storeId;

- (id)initWithStoreConfig:(SCStoreConfig *)cfg {
  if (self = [super init]) {
    _uri = cfg.uri;
    _storeId = cfg.uniqueid;
    _filepath = nil;
  }
  return self;
}

- (RACSignal *)connect {
  NSString *dbName = self.storeId;
  NSString *fp = self.dbFilepath;

  if ([[NSFileManager defaultManager] fileExistsAtPath:fp]) {
    self.gpkg = self.openConnection;
    return [RACSignal empty];
  } else if ([self.uri.lowercaseString containsString:@"http"]) {
    NSURL *url = [[NSURL alloc] initWithString:self.uri];
    return
        [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
          [[self attemptFileDownload:url] subscribeNext:^(NSData *data) {
            NSString *dbPath =
                [SCFileUtils filePathFromDocumentsDirectory:dbName];
            [data writeToFile:dbPath atomically:YES];
            [self setFilepathPreference:dbPath];
            self.gpkg = self.openConnection;
            [subscriber sendCompleted];
          } error:^(NSError *error) {
            NSLog(@"%@", error.description);
            [subscriber sendError:error];
          }];
          return nil;
        }];
  }
  NSError *err = [NSError errorWithDomain:SCGeopackageErrorDomain
                                     code:SC_GEOPACKAGE_FILENOTFOUND
                                 userInfo:nil];
  return [RACSignal error:err];
}

- (GPKGGeoPackage *)openConnection {
  GPKGConnection *connection =
      [[GPKGConnection alloc] initWithDatabaseFilename:self.dbFilepath];
  GPKGGeoPackage *gpkg =
      [[GPKGGeoPackage alloc] initWithConnection:connection
                                     andWritable:YES];
  return gpkg;
}

- (RACSignal *)attemptFileDownload:(NSURL *)fileUrl {
  NSURLRequest *request = [[NSURLRequest alloc] initWithURL:fileUrl];
  return [[NSURLConnection rac_sendAsynchronousRequest:request]
      reduceEach:^id(NSURLResponse *response, NSData *data) {
        return data;
      }];
}

#pragma mark -
#pragma mark SCAdapterKeyValue
- (NSString *)filepathKey {
  return [NSString stringWithFormat:@"%@.%@", self.storeId, @"filepath"];
}

- (void)setFilepathPreference:(NSString *)dbPath {
  [[NSUserDefaults standardUserDefaults] setObject:dbPath
                                            forKey:self.filepathKey];
}

- (NSString *)dbFilepath {
  return [[NSUserDefaults standardUserDefaults] stringForKey:self.filepathKey];
}

- (NSArray *)layerList {
  return self.gpkg.tables;
}

- (GPKGFeatureRow*)toFeatureRow:(SCSpatialFeature*)feature {
  
  return nil;
}

- (RACSignal*)createFeature:(SCSpatialFeature *)feature {
  GPKGFeatureRow *newRow = [self toFeatureRow:feature];
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    GPKGFeatureDao *featureDao = [self.gpkg getFeatureDaoWithTableName:feature.layerId];
    [feature.properties enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSObject  *obj, BOOL *stop) {
      [featureDao.table.columnNames enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
        if ([name isEqualToString:key]) {
          [newRow setValue:obj forKey:key];
        }
      }];
    }];
    
    if ([feature isKindOfClass:SCGeometry.class]) {
      SCGeometry *g = (SCGeometry*)feature;
      if (g) {
        [newRow setGeometry:g.wkb];
      }
    }
    
    [featureDao create:newRow];
    [subscriber sendCompleted];
    return nil;
  }];
}

- (RACSignal*)deleteFeature:(NSString *)identifier {
  return nil;
}

- (RACSignal*)updateFeature:(SCSpatialFeature *)feature {
  return nil;
}

- (RACSignal*)queryAllLayers:(SCQueryFilter *)filter {
  return nil;
}

- (RACSignal*)queryByLayerId:(NSString *)layerId withFilter:(SCQueryFilter *)filter {
  return nil;
}

@end
