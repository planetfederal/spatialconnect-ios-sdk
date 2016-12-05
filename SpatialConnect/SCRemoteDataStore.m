/**
 * Copyright 2016 Boundless http://boundlessgeo.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License
 */

#import "SCRemoteDataStore.h"

@implementation SCRemoteDataStore

- (RACSignal *)start {
  [self listenForConnection];
  return RACSignal.empty;
}

- (void)listenForConnection {
  SCSensorService *ss = [[SpatialConnect sharedInstance] sensorService];
  [[[ss.isConnected filter:^BOOL(NSNumber *x) {
    return x.boolValue;
  }] take:1] subscribeNext:^(NSNumber *x) {
    self.status = SC_DATASTORE_RUNNING;
  }];
}

- (void)resume {
  [self listenForConnection];
}

- (void)pause {
  self.status = SC_DATASTORE_PAUSED;
}

- (void)stop {
  self.status = SC_DATASTORE_STOPPED;
}

- (void)destroy {
    
}

@end
