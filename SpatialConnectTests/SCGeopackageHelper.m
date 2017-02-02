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

#import "SCGeopackageHelper.h"
#import "SCStoreStatusEvent.h"

@implementation SCGeopackageHelper

NSString *vectorStoreId = @"f6dcc750-1349-46b9-a324-0223764d46d1";
NSString *rasterStoreId = @"ba293796-5026-46f7-a2ff-e5dec85heh6b";

+ (RACSignal *)loadGPKGDataStore:(SpatialConnect *)sc {
  return [[sc.dataService storeStarted:vectorStoreId]
      map:^SCDataStore *(SCStoreStatusEvent *evt) {
        SCDataStore *ds = [sc.dataService storeByIdentifier:vectorStoreId];
        return ds;
      }];
}

+ (RACSignal *)loadGPKGRasterStore:(SpatialConnect *)sc {
  return [[sc.dataService storeStarted:rasterStoreId]
      map:^SCDataStore *(id value) {
        return [sc.dataService storeByIdentifier:rasterStoreId];
      }];
}

+ (RACSignal *)downloadGpkgFile {
  NSURL *URL = [NSURL URLWithString:@"https://s3.amazonaws.com"];
  [NSURLRequest
          .class performSelector:NSSelectorFromString(
                                     @"setAllowsAnyHTTPSCertificate:forHost:")
                      withObject:NSNull.null // Just need to pass non-nil here
                      // to appear as a BOOL YES, using
                      // the NSNull.null singleton is
                      // pretty safe
                      withObject:[URL host]];

  NSString *url = @"https://s3.amazonaws.com/test.spacon/haiti4mobile.gpkg";
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        BOOL saveToDocsDir = ![SCFileUtils isTesting];
        NSString *dbName = @"haiti4mobile.gpkg";
        NSString *path;
        if (saveToDocsDir) {
          NSArray *paths = NSSearchPathForDirectoriesInDomains(
              NSDocumentDirectory, NSUserDomainMask, YES);
          NSString *documentsDirectory = [paths objectAtIndex:0];
          path = [documentsDirectory stringByAppendingPathComponent:dbName];
        } else {
          path = [SCFileUtils filePathFromNSHomeDirectory:dbName];
        }
        BOOL b = [[NSFileManager defaultManager] fileExistsAtPath:path];

        if (b) {
          [subscriber sendNext:path];
          [subscriber sendCompleted];
        } else {

          NSURLRequest *request =
              [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
          RACSignal *s = [[NSURLConnection rac_sendAsynchronousRequest:request]
              reduceEach:^id(NSURLResponse *response, NSData *data) {
                return data;
              }];
          [s subscribeNext:^(NSData *data) {
            DDLogInfo(@"Saving GPKG to %@", path);
            [data writeToFile:path atomically:YES];
            [subscriber sendNext:path];
            [subscriber sendCompleted];
          }
              error:^(NSError *error) {
                DDLogError(@"%@", error.description);
                [subscriber sendError:error];
              }];
        }
        return nil;
      }];
}

@end
