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
  [[serviceNodes.rac_sequence.signal flattenMap:^RACStream *(SCServiceNode *sn) {
    return [self startService:[sn.service.class serviceId]];
  }] subscribeError:^(NSError *error) {
    DDLogError(@"StartAllServices Error:%@",error.description);
  } completed:^{
    DDLogInfo(@"StartAllServices Complete");
  }];
}

- (RACSignal *)checkAndStartService:(id<SCServiceLifecycle>)service withDeps:(NSDictionary *)dict {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    if ([service status] == SC_SERVICE_STARTED || [service status] == SC_SERVICE_RUNNING) {
      [subscriber sendCompleted];
      return nil;
    }
    //We need to subscribe to the start to send events on the Service Event Subject
    [[service start:dict] subscribeError:^(NSError *error) {
      [self.serviceEventSubject sendNext:[SCServiceStatusEvent fromEvent:SC_SERVICE_EVT_ERROR andServiceName:[service.class serviceId]]];
      [subscriber sendError:error];
    } completed:^{
      [self.serviceEventSubject sendNext:[SCServiceStatusEvent fromEvent:SC_SERVICE_EVT_RUNNING andServiceName:[service.class serviceId]]];
      [subscriber sendCompleted];
    }];
    return nil;
  }];
}

- (RACSignal *)startService:(NSString *)serviceId {
  SCServiceNode *node = [self nodeById:serviceId];

  SCServiceStatus status = [node.service status];
  // Terminal Case
  if(status == SC_SERVICE_RUNNING) {
    return [RACSignal empty];
  }

  // Get all the dependencies and recursively pass them into this method
  RACSignal *dep$ = nil;
  if (node.dependencies) {
    dep$ = [node.dependencies.rac_sequence.signal flattenMap:^RACStream *(SCServiceNode *e) {
      if ([e.service status] == SC_SERVICE_STARTED || [e.service status] == SC_SERVICE_RUNNING) {
        return [RACSignal empty];
      } else {
        return [self startService:[e.service.class serviceId]];
      }
    }];
  }

  //No Deps, just start it
  if (!dep$) {
    return [self checkAndStartService:node.service withDeps:nil];
  } else {
    return [[[dep$ materialize] filter:^BOOL(RACEvent *evt) {
      return evt.eventType == RACEventTypeError ||
        evt.eventType == RACEventTypeCompleted;
    }] flattenMap:^RACStream *(RACEvent *evt) {
      if (evt.eventType == RACEventTypeError) {
        return [RACSignal error:evt.error];
      } else {
        NSArray<NSString*>* keys = [[node.dependencies.rac_sequence map:^NSString*(SCServiceNode *n) {
          return [((SCService*)n.service).class serviceId];
        }] array];
        NSArray *deps = [[node.dependencies.rac_sequence map:^id<SCServiceLifecycle>(SCServiceNode *n) {
          return n.service;
        }] array];
        NSDictionary *dict = [NSDictionary dictionaryWithObjects:deps forKeys:keys];
        return [self checkAndStartService:node.service withDeps:dict];
      }
    }];
  }
}

- (void)stopAllServices {
  [[serviceNodes.rac_sequence.signal flattenMap:^RACStream *(SCServiceNode *sn) {
    return [self stopService:[sn.service.class serviceId]];
  }] subscribeError:^(NSError *error) {
    DDLogError(@"StartAllServices Error:%@",error.description);
  } completed:^{
    DDLogInfo(@"StartAllServices Complete");
  }];
}

- (RACSignal *)stopService:(NSString *)serviceId {
  SCServiceNode *node = [self nodeById:serviceId];

  if ([node.service status] == SC_SERVICE_STOPPED) {
    return [RACSignal empty];
  }

  RACSignal *rec$ = nil;
  if (node.recipients) {
    rec$ = [node.recipients.rac_sequence.signal flattenMap:^RACStream *(SCServiceNode *e) {
      return [self stopService:[e.service.class serviceId]];
    }];
  }

  //No Recips, just start it
  if (!rec$) {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
      //We need to subscribe to the start to send events on the Service Event Subject
      [[node.service stop] subscribeError:^(NSError *error) {
        [self.serviceEventSubject sendNext:[SCServiceStatusEvent fromEvent:SC_SERVICE_EVT_ERROR andServiceName:[node.service.class serviceId]]];
        [subscriber sendError:error];
      } completed:^{
        [self.serviceEventSubject sendNext:[SCServiceStatusEvent fromEvent:SC_SERVICE_EVT_STOPPED andServiceName:[node.service.class serviceId]]];
        [subscriber sendCompleted];
      }];
      return nil;
    }];
  } else {
    return [[[rec$ materialize] filter:^BOOL(RACEvent *evt) {
      return evt.eventType == RACEventTypeError ||
      evt.eventType == RACEventTypeCompleted;
    }] flattenMap:^RACStream *(RACEvent *evt) {
      if (evt.eventType == RACEventTypeError) {
        return [RACSignal error:evt.error];
      } else {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
          //We need to subscribe to the start to send events on the Service Event Subject
          [[node.service stop] subscribeError:^(NSError *error) {
            [self.serviceEventSubject sendNext:[SCServiceStatusEvent fromEvent:SC_SERVICE_EVT_ERROR andServiceName:[node.service.class serviceId]]];
            [subscriber sendError:error];
          } completed:^{
            [self.serviceEventSubject sendNext:[SCServiceStatusEvent fromEvent:SC_SERVICE_EVT_STOPPED andServiceName:[node.service.class serviceId]]];
            [subscriber sendCompleted];
          }];
          return nil;
        }];
      }
    }];
  }
}

@end
