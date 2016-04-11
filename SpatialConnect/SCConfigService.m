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

#import "SCConfigService.h"
#import "SCFileUtils.h"
#import "SCDataServiceStoreConfig.h"
#import "SCDataService.h"

@interface SCConfigService()
- (void)setupSignals;
@end

@implementation SCConfigService

- (id)initWithSignal:(RACSignal *)bus{
  self = [self init];
  if (self) {
    configPaths = [NSMutableArray new];
    configEvents = bus;
  }
  return self;
}

- (void)setupSignals {
  dataServiceSignals = [[configEvents filter:^BOOL(SCMessage *m) {
    switch (m.action) {
      case SCACTION_DATASERVICE_ADDSTORE:
        return YES;
      case SCACTION_DATASERVICE_REMOVESTORE:
        return YES;
      case SCACTION_DATASERVICE_UPDATESTORE:
        return YES;
      default:
        return NO;
    }
  }] map:^SCMessage*(SCMessage *m) {
    m.serviceIdentifier = kSERVICENAME;
    return m;
  }];
}

- (RACSignal*)connect:(NSString*)serviceIdent {
  if ([serviceIdent isEqualToString:kSERVICENAME]) {
    return dataServiceSignals;
  }
  return nil;
}

- (void)start {
  [super start];
  [self setupSignals];
}

- (void)stop {
  [super stop];
}



@end
