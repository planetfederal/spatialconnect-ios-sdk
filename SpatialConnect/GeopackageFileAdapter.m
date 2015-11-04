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

@interface GeopackageFileAdapter (PrivateMethods)
- (BOOL)checkFile;
- (RACSignal *)attemptFileDownload;
@end

@implementation GeopackageFileAdapter

- (id)initWithStoreConfig:(SCStoreConfig *)cfg {
  if (self = [super init]) {
    uri = cfg.uri;
    storeId = cfg.uniqueid;
    filepath = nil;
  }
  return self;
}

- (RACSignal *)connect {
  NSString *dbName = storeId;
  NSString *fp =
      [[NSUserDefaults standardUserDefaults] stringForKey:self.filepathKey];
  if ([[NSFileManager defaultManager] fileExistsAtPath:fp]) {
    return [RACSignal empty];
  } else if ([uri.lowercaseString containsString:@"http"]) {
    NSURL *url = [[NSURL alloc] initWithString:uri];
    return
        [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
          [[self attemptFileDownload:url] subscribeNext:^(NSData *data) {
            NSString *dbPath =
                [SCFileUtils filePathFromDocumentsDirectory:dbName];
            [data writeToFile:dbPath atomically:YES];
            [self setFilepathPreference:dbPath];
            [subscriber sendCompleted];
          }];
          return nil;
        }];
  }
  NSError *err =
      [NSError errorWithDomain:@"gpkgConnect"
                          code:-1
                      userInfo:nil]; // TODO add connect codes to parent
  return [RACSignal error:err];
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
  return [NSString stringWithFormat:@"%@.%@", storeId, @"filepath"];
}

- (void)setFilepathPreference:(NSString *)dbPath {
  [[NSUserDefaults standardUserDefaults] setObject:dbPath
                                            forKey:self.filepathKey];
}

@end
