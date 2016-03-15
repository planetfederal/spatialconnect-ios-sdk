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
#import "SCStoreConfig.h"

@implementation SCConfigService

- (id)init {
  self = [super init];
  if (self) {
    configPaths = [NSMutableArray new];
    [self sweepDataDirectory];
  }
  return self;
}

- (id)initWithFilepath:(NSString *)filepath {
  self = [super init];
  if (self) {
    configPaths = [NSMutableArray new];
    [configPaths addObject:filepath];
  }

  return self;
}

- (id)initWithFilepaths:(NSArray *)filepaths {
  self = [super init];
  if (self) {
    configPaths = [NSMutableArray new];
    [configPaths addObjectsFromArray:filepaths];
  }
  return self;
}

- (RACSignal *)load {
  return
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [configPaths enumerateObjectsUsingBlock:^(NSString *fp, NSUInteger idx,
                                                  BOOL *_Nonnull stop) {
          NSError *error;
          NSDictionary *cfg = [SCFileUtils jsonFileToDict:fp error:&error];
          if (error) {
            [subscriber sendError:error];
          }

          [cfg[@"stores"] enumerateObjectsUsingBlock:^(NSDictionary *d,
                                                       NSUInteger i, BOOL *s) {
            SCStoreConfig *cfg = [[SCStoreConfig alloc] initWithDictionary:d];
            RACTuple *tuple =
                [RACTuple tupleWithObjects:@(SC_CONFIG_DATASERVICE_STORE_ADDED),
                                           cfg, nil];
            [subscriber sendNext:tuple];
          }];

          [subscriber sendCompleted];
        }];
        return nil;
      }];
}

- (void)start {
  [super start];
}

- (void)stop {
  [super stop];
}

#pragma mark -
#pragma mark Private

- (void)sweepDataDirectory {
  NSString *path = [NSSearchPathForDirectoriesInDomains(
      NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  NSArray *dirs =
      [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path
                                                          error:NULL];

  [[[dirs.rac_sequence filter:^BOOL(NSString *filename) {
    if ([filename.pathExtension.lowercaseString isEqualToString:@"scfg"]) {
      return YES;
    } else {
      return NO;
    }
  }] signal] subscribeNext:^(NSString *cfgFileName) {
    [configPaths
        addObject:[NSString stringWithFormat:@"%@/%@", path, cfgFileName]];

  }];
}

@end
