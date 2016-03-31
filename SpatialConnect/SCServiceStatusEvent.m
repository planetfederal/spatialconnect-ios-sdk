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

#import "SCServiceStatusEvent.h"

@implementation SCServiceStatusEvent

@synthesize status = _status;
@synthesize serviceName = _serviceName;

+ (instancetype)fromEvent:(SCServiceStatus)s andServiceName:(NSString *)sName {
  SCServiceStatusEvent *evt =
      [[SCServiceStatusEvent alloc] initWithEvent:s andStoreName:sName];
  return evt;
}

- (id)initWithEvent:(SCServiceStatus)s andStoreName:(NSString *)sName {
  if (self = [super init]) {
    _status = s;
    _serviceName = sName;
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%ld,%@", (long)self.status, self.serviceName];
}
@end
