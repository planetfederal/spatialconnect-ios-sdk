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

NSString *storeId = @"a5d93796-5026-46f7-a2ff-e5dec85heh6b";

+ (RACSignal *)loadGPKGDataStore:(SpatialConnect *)sc {
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {

        RACMulticastConnection *c = sc.dataService.storeEvents;
        [c connect];
        RACSignal *evts = [c.signal filter:^BOOL(SCStoreStatusEvent *evt) {
          if ([evt.storeId isEqualToString:storeId] &&
              evt.status == SC_DATASTORE_RUNNING) {
            return YES;
          } else {
            return NO;
          }
        }];

        [evts subscribeNext:^(SCStoreStatusEvent *evt) {
          SCDataStore *ds = [sc.dataService storeByIdentifier:storeId];
          [subscriber sendNext:ds];
          [subscriber sendCompleted];
        }];

        return nil;
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
            NSLog(@"Saving GPKG to %@", path);
            [data writeToFile:path atomically:YES];
            [subscriber sendNext:path];
            [subscriber sendCompleted];
          }
              error:^(NSError *error) {
                NSLog(@"%@", error.description);
                [subscriber sendError:error];
              }];
        }
        return nil;
      }];
}

@end
