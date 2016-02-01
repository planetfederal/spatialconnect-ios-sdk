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

+ (RACSignal*)loadGPKGDataStore:(SpatialConnect*)sc {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {

    RACMulticastConnection *c = sc.manager.dataService.storeEvents;
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
      SCDataStore *ds = [sc.manager.dataService storeByIdentifier:storeId];
      [subscriber sendNext:ds];
      [subscriber sendCompleted];
    }];

    return nil;
  }];
}

@end
