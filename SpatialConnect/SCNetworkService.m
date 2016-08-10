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

#import "JSONKit.h"
#import "SCKeyTuple.h"
#import "SCNetworkService.h"
#import "SpatialConnect.h"

@interface SCNetworkService ()
- (void)setupMQTT;
@end

@implementation SCNetworkService

- (RACSignal *)getRequestURLAsDict:(NSURL *)url {
  return [[self getRequestURLAsData:url] flattenMap:^RACSignal *(NSData *d) {
    NSError *err;
    NSDictionary *dict = [[JSONDecoder decoder] objectWithData:d error:&err];
    if (err) {
      return [RACSignal error:err];
    }
    return [RACSignal return:dict];
  }];
}

- (NSDictionary *)getRequestURLAsDictBLOCKING:(NSURL *)url {
  NSData *data = [self getRequestURLAsDataBLOCKING:url];
  NSDictionary *dict = [[JSONDecoder decoder] objectWithData:data];
  return dict;
}

- (NSData *)getRequestURLAsDataBLOCKING:(NSURL *)url {
  NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
  NSURLResponse *response = nil;
  NSError *error = nil;
  NSData *data = [NSURLConnection sendSynchronousRequest:request
                                       returningResponse:&response
                                                   error:&error];
  return data;
}

- (RACSignal *)getRequestURLAsData:(NSURL *)url {
  NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
  return [[NSURLConnection rac_sendAsynchronousRequest:request]
      reduceEach:^id(NSURLResponse *response, NSData *data) {
        return data;
      }];
}

- (RACSignal *)postRequestAsDict:(NSURL *)url body:(NSData *)data {
  return [[self postRequestAsData:url
                             body:data] flattenMap:^RACStream *(NSData *data) {
    NSError *err;
    NSDictionary *dict = [[JSONDecoder decoder] objectWithData:data error:&err];
    if (err) {
      return [RACSignal error:err];
    } else {
      return [RACSignal return:dict];
    }
  }];
}

- (RACSignal *)postRequestAsData:(NSURL *)url body:(NSData *)data {
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
  request.HTTPMethod = @"POST";
  request.HTTPBody = data;
  return [[NSURLConnection rac_sendAsynchronousRequest:request]
      reduceEach:^id(NSURLResponse *response, NSData *data) {
        return data;
      }];
}

- (RACSignal *)postDictRequestAsDict:(NSURL *)url body:(NSDictionary *)dict {
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
  request.HTTPMethod = @"POST";
  [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  NSError *error;
  request.HTTPBody = dict.JSONData;
  if (error) {
    NSLog(@"%@", error.description);
    return [RACSignal error:error];
  }

  return [[NSURLConnection rac_sendAsynchronousRequest:request]
      reduceEach:^id(NSURLResponse *response, NSData *data) {
        return data;
      }];
}

- (NSData *)postDictRequestBLOCKING:(NSURL *)url body:(NSDictionary *)dict {
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
  request.HTTPMethod = @"POST";
  [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  NSError *err;
  NSURLResponse *response;
  request.HTTPBody = dict.JSONData;
  NSData *data = [NSURLConnection sendSynchronousRequest:request
                                       returningResponse:&response
                                                   error:&err];
  return data;
}

- (NSDictionary *)postDictRequestAsDictBLOCKING:(NSURL *)url
                                           body:(NSDictionary *)dict {
  NSData *data = [self postDictRequestBLOCKING:url body:dict];
  return [[JSONDecoder decoder] objectWithData:data];
}

- (void)start {
  [self setupMQTT];
}

- (void)setupMQTT {
  MQTTCFSocketTransport *transport = [[MQTTCFSocketTransport alloc] init];
  transport.host = @"localhost";
  transport.port = 1883;

  NSString *ident =
      [[NSUserDefaults standardUserDefaults] stringForKey:@"UNIQUE_ID"];

  session = [[MQTTSession alloc] init];
  session.transport = transport;
  session.clientId = ident;
  RACSignal *d = [self
      rac_signalForSelector:@selector(newMessage:data:onTopic:qos:retained:mid:)
               fromProtocol:@protocol(MQTTSessionDelegate)];

  multicast = [[[d publish] autoconnect] map:^SCMessage *(RACTuple *t) {
    NSData *d = (NSData *)[t second];
    NSError *err;
    SCMessage *msg = [[SCMessage alloc] initWithData:d error:&err];
    return msg;
  }];

  session.delegate = self;
  [session connectAndWaitTimeout:30];
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  [session
      subscribeTopic:[NSString stringWithFormat:@"/device/%@-replyTo",
                                                sc.configService.identifier]];
}

- (void)publish:(SCMessage *)msg onTopic:(NSString *)topic {
  if (session) {
    [session publishData:[msg data]
                 onTopic:topic
                  retain:NO
                     qos:MQTTQosLevelExactlyOnce];
  }
}

- (void)publishAtMostOnce:(SCMessage *)msg onTopic:(NSString *)topic {
  if (session) {
    [session publishData:msg.data
                 onTopic:topic
                  retain:NO
                     qos:MQTTQosLevelAtMostOnce];
  }
}

- (void)publishAtLeastOnce:(SCMessage *)msg onTopic:(NSString *)topic {
  if (session) {
    [session publishData:msg.data
                 onTopic:topic
                  retain:NO
                     qos:MQTTQosLevelAtLeastOnce];
  }
}

- (void)publishExactlyOnce:(SCMessage *)msg onTopic:(NSString *)topic {
  if (session) {
    [session publishData:msg.data
                 onTopic:topic
                  retain:NO
                     qos:MQTTQosLevelExactlyOnce];
  }
}

- (RACSignal *)publishReplyTo:(SCMessage *)msg onTopic:(NSString *)topic {
  SpatialConnect *sc = [SpatialConnect sharedInstance];
  NSTimeInterval ti = [[NSDate date] timeIntervalSince1970];
  msg.correlationId = ti;
  msg.replyTo = [NSString
      stringWithFormat:@"/device/%@-replyTo", sc.configService.identifier];
  [session subscribeTopic:msg.replyTo];
  if (session) {
    [session publishData:[msg data] onTopic:topic];
    return [multicast filter:^BOOL(SCMessage *m) {
      if (m.correlationId == msg.correlationId) {
        return YES;
      }
      return NO;
    }];
  }
  return nil;
}

- (RACSignal *)listenOnTopic:(NSString *)topic {
  [session subscribeTopic:topic];
  return multicast;
}

@end
