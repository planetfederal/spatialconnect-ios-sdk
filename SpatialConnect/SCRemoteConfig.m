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

#import "SCRemoteConfig.h"

static NSString *const HTTP_PROTOCOL = @"http_protocol";
static NSString *const HTTP_HOST = @"http_host";
static NSString *const HTTP_PORT = @"http_port";
static NSString *const MQTT_PROTOCOL = @"mqtt_protocol";
static NSString *const MQTT_HOST = @"mqtt_host";
static NSString *const MQTT_PORT = @"mqtt_port";

@implementation SCRemoteConfig

@synthesize httpProtocol = _httpProtocol;
@synthesize httpHost = _httpHost;
@synthesize httpPort = _httpPort;
@synthesize mqttProtocol = _mqttProtocol;
@synthesize mqttHost = _mqttHost;
@synthesize mqttPort = _mqttPort;

- (id)initWithDict:(NSDictionary *)d {
  self = [super init];
  if (self) {
    _httpProtocol = d[HTTP_PROTOCOL];
    _httpHost = d[HTTP_HOST];
    _httpPort = d[HTTP_PORT];
    _mqttProtocol = d[MQTT_PROTOCOL];
    _mqttHost = d[MQTT_HOST];
    _mqttPort = d[MQTT_PORT];
  }
  return self;
}

@end
