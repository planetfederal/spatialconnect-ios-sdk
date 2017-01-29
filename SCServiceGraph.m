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
#import "SCServiceNode.h"
#import "SCServiceEdge.h"
#import "SCDataStore.h"

@interface SCServiceGraph (Private)
- (id<SCServiceLifecycle>)nodeById;
@end

@implementation SCServiceGraph

- (instancetype)init
{
  self = [super init];
  if (self) {
    serviceNodes = [NSMutableArray new];
  }
  return self;
}

- (void)addService:(id<SCServiceLifecycle>)s deps:(NSArray<id<SCServiceLifecycle>>*)deps{
  NSMutableArray<SCServiceEdge*>* edges = nil;
  if (deps) {
    edges = [NSMutableArray new];
    [deps enumerateObjectsUsingBlock:^(id<SCServiceLifecycle> dep, NSUInteger idx, BOOL * _Nonnull stop) {
      [edges addObject:[SCServiceEdge withNode:s dep:dep]];
    }];
  }
  SCServiceNode *sn = [[SCServiceNode alloc] initWithService:s andEdges:edges];
  [serviceNodes addObject:sn];
}

- (void)removeService:(NSString *)serviceId {
  SCServiceNode *serviceNode = [self nodeById:serviceId];
  [serviceNode.edges enumerateObjectsUsingBlock:^(SCServiceEdge *edge, NSUInteger idx, BOOL *stop) {
    [self removeService:[edge.dep.service.class serviceId]];
  }];
  [serviceNode.service stop];
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

- (RACSignal *)startAllServices {
  return [serviceNodes.rac_sequence.signal flattenMap:^RACStream *(SCServiceNode *sn) {
    return [self startService:[sn.service.class serviceId]];
  }];
}

- (RACSignal *)startService:(NSString *)serviceId {
  SCServiceNode *node = [self nodeById:serviceId];

  if ([node.service status] == SC_SERVICE_RUNNING) {
    return [RACSignal empty];
  }

  RACSignal *dep$ = nil;
  if (node.edges) {
    dep$ = [node.edges.rac_sequence.signal flattenMap:^RACStream *(SCServiceEdge *e) {
      return [self startService:[e.node.service.class serviceId]];
    }];
  }

  //No Deps, just start it
  if (!dep$) {
    return [node.service start];
  } else {
    return [[[dep$ materialize] filter:^BOOL(RACEvent *evt) {
      return evt.eventType == RACEventTypeError ||
        evt.eventType == RACEventTypeCompleted;
    }] flattenMap:^RACStream *(RACEvent *evt) {
      if (evt.eventType == RACEventTypeError) {
        return [RACSignal error:evt.error];
      } else {
        return [node.service start];
      }
    }];
  }
}

- (RACSignal *)stopAllServices {
  return nil;
}

- (RACSignal *)stopService:(NSString *)serviceId {
  SCServiceNode *node = [self nodeById:serviceId];
  return nil;
}

@end
