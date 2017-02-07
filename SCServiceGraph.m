/**
 * Copyright 2017 Boundless http://boundlessgeo.com
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
 * See the License for the specific language governing permissions and limitations under the License
 */

#import "SCServiceGraph.h"
#import "SCDataStore.h"

@interface SCServiceGraph ()
@property(readwrite, nonatomic, strong) RACSubject *serviceEventSubject;
- (id<SCServiceLifecycle>)nodeById;
@end

@implementation SCServiceGraph

@synthesize serviceEventSubject = _serviceEventSubject;
@synthesize serviceEvents = _serviceEvents;

- (instancetype)init
{
  self = [super init];
  if (self) {
    serviceNodes = [NSMutableArray new];
    _serviceEventSubject = [RACSubject new];
    _serviceEvents = [self.serviceEventSubject publish];
  }
  return self;
}

- (void)addService:(id<SCServiceLifecycle>)s {
  NSArray *requires = [s requires];
  NSArray<SCServiceNode*>* deps = nil;
  if (requires) {
    deps = [[requires.rac_sequence map:^SCServiceNode*(NSString *serviceId) {
      return [self nodeById:serviceId];
    }] array];
  }

  SCServiceNode *sn = [[SCServiceNode alloc] initWithService:s andDependencies:deps];
  if (deps) {
    [deps enumerateObjectsUsingBlock:^(SCServiceNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
      [obj addRecipient:sn];
    }];
  }

  [serviceNodes addObject:sn];
}

- (void)removeService:(NSString *)serviceId {
  SCServiceNode *serviceNode = [self nodeById:serviceId];
  if (!serviceNode) {
    return;
  }

  if (serviceNode.recipients) {
    [serviceNode.recipients enumerateObjectsUsingBlock:^(SCServiceNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
      [self removeService:[obj.service.class serviceId]];
    }];
  }

  [serviceNodes removeObject:serviceNode];
}

- (SCServiceNode *)nodeById:(NSString*)serviceId {
  __block SCServiceNode *node = nil;
  [serviceNodes enumerateObjectsUsingBlock:^(SCServiceNode *obj, NSUInteger idx, BOOL *stop) {
    BOOL matched = [[obj.service.class serviceId] isEqualToString:serviceId];
    if (matched) {
      *stop = YES;
      node = obj;
    }
  }];
  return node;
}

- (void)startAllServices {
  [serviceNodes enumerateObjectsUsingBlock:^(SCServiceNode *n, NSUInteger idx, BOOL * _Nonnull stop) {
    BOOL started = [self startService:[n.service.class serviceId]];
    if (started) {
      [self.serviceEventSubject sendNext:[SCServiceStatusEvent fromEvent:SC_SERVICE_EVT_RUNNING andServiceName:[n.service.class serviceId]]];
    } else {
      [self.serviceEventSubject sendNext:[SCServiceStatusEvent fromEvent:SC_SERVICE_EVT_ERROR andServiceName:[n.service.class serviceId]]];
    }
  }];
}


- (BOOL)startService:(NSString *)serviceId {
  SCServiceNode *node = [self nodeById:serviceId];
  if([node.service status] == SC_SERVICE_RUNNING) {
    return YES;
  }

  // Get all the dependencies and recursively pass them into this method
  NSArray *depsStarts = nil;
  if (node.dependencies) {
    depsStarts = [[node.dependencies.rac_sequence filter:^BOOL(SCServiceNode *e) {
      if ([e.service status] == SC_SERVICE_RUNNING) {
        return YES;
      } else {
        return [self startService:[e.service.class serviceId]];
      }
    }] array];
  }

  //No Deps, just start it
  if (!depsStarts) {
    return [node.service start:nil];
  } else {
    if (node.dependencies.count != depsStarts.count) {
      DDLogError(@"Not all of the dependencies started");
      return NO;
    }
    NSArray<NSString*>* keys = [[node.dependencies.rac_sequence map:^NSString*(SCServiceNode *n) {
      return [((SCService*)n.service).class serviceId];
    }] array];
    NSArray *deps = [[node.dependencies.rac_sequence map:^id<SCServiceLifecycle>(SCServiceNode *n) {
      return n.service;
    }] array];
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:deps forKeys:keys];
    return [node.service start:dict];
  }
}

- (void)stopAllServices {
  [serviceNodes enumerateObjectsUsingBlock:^(SCServiceNode *n, NSUInteger idx, BOOL * _Nonnull stop) {
    BOOL stopped = [self stopService:[n.service.class serviceId]];
    if (stopped) {
      [self.serviceEventSubject sendNext:[SCServiceStatusEvent fromEvent:SC_SERVICE_EVT_STOPPED andServiceName:[n.service.class serviceId]]];
    } else {
      [self.serviceEventSubject sendNext:[SCServiceStatusEvent fromEvent:SC_SERVICE_EVT_ERROR andServiceName:[n.service.class serviceId]]];
    }
  }];
}

- (BOOL)stopService:(NSString *)serviceId {
  SCServiceNode *node = [self nodeById:serviceId];

  if ([node.service status] == SC_SERVICE_STOPPED) {
    return YES;
  }

  NSArray *recipsStops = nil;
  if (node.recipients) {
    recipsStops = [[node.recipients.rac_sequence filter:^BOOL(SCServiceNode *e) {
      if ([e.service status] == SC_SERVICE_STOPPED) {
        return YES;
      } else {
        return [self stopService:[e.service.class serviceId]];
      }
    }] array];
  }

  if (!recipsStops) {
    return [node.service stop];
  } else {
    if (node.recipients.count != recipsStops.count) {
      DDLogError(@"Not all of the dependencies started");
      return NO;
    } else {
      return [node.service stop];
    }
  }
}

@end
