//
//  SCNoAuthMethod.m
//  SpatialConnect
//
//  Created by Frank Rowe on 7/14/17.
//  Copyright © 2017 Boundless Spatial. All rights reserved.
//

#import "SCNoAuthMethod.h"

@implementation SCNoAuthMethod

- (BOOL)authFromCache {
  return YES;
}

- (BOOL)authenticate:(NSString *)u password:(NSString *)p {
  return YES;
}

- (NSString *)xAccessToken {
  return nil;
}

- (void)logout {
}

- (NSString *)username {
  return nil;
}

@end
