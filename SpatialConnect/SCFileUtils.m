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

#import "SCFileUtils.h"
#import "JSONKit.h"
@implementation SCFileUtils

/**
 *  UTF-8 Only Encoding JSON parser
 *
 *  @param filepath full path to file. Not relative to bundle or docs dir
 *  @param err      parsing error
 *
 *  @return NSDictionary from valid JSON Object
 */
+ (NSDictionary *)jsonStringToDict:(NSString *)string error:(NSError **)err {
  NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
  NSDictionary *dict = [[JSONDecoder decoder] objectWithData:data error:err];
  return dict;
}

+ (NSDictionary *)jsonFileToDict:(NSString *)filepath error:(NSError **)err {
  BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:filepath];
  if (fileExist) {
    NSData *data = [NSData dataWithContentsOfFile:filepath
                                          options:NSDataReadingMappedIfSafe
                                            error:err];
    NSDictionary *dictContent =
        [[JSONDecoder decoder] objectWithData:data error:err];
    if (!dictContent) {
      DDLogError(@"Check that your JSON is not malformed for file:%@",
                 filepath);
      DDLogError(@"%@", [*err description]);
      return nil;
    }
    if (dictContent) {
      return dictContent;
    }
  }
  return nil;
}

+ (NSString *)filePathFromDocumentsDirectory:(NSString *)fileName {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  return [documentsDirectory stringByAppendingPathComponent:fileName];
}

+ (NSString *)filePathFromSelfBundle:(NSString *)fileName {
  NSArray *strs = [fileName componentsSeparatedByString:@"."];
  NSString *filePrefix;
  if (strs.count == 2) {
    filePrefix = strs.firstObject;
  } else {
    filePrefix = [[strs
        objectsAtIndexes:[NSIndexSet
                             indexSetWithIndexesInRange:NSMakeRange(
                                                            0, strs.count - 2)]]
        componentsJoinedByString:@"."];
  }
  NSString *extension = [strs lastObject];
  NSString *filePath =
      [[NSBundle bundleForClass:[self class]] pathForResource:filePrefix
                                                       ofType:extension];
  return filePath;
}

+ (NSString *)filePathFromMainBundle:(NSString *)fileName {
  NSArray *strs = [fileName componentsSeparatedByString:@"."];
  NSString *filePrefix;
  if (strs.count == 2) {
    filePrefix = strs.firstObject;
  } else {
    if (strs.count < 2) {
      return nil;
    }
    filePrefix = [[strs
                   objectsAtIndexes:[NSIndexSet
                                     indexSetWithIndexesInRange:NSMakeRange(
                                                                            0, strs.count - 2)]]
                  componentsJoinedByString:@"."];
  }
  NSString *extension = [strs lastObject];
  NSString *filePath =
      [[NSBundle mainBundle] pathForResource:filePrefix ofType:extension];
  return filePath;
}

+ (NSString *)filePathFromNSHomeDirectory:(NSString *)fileName {
  NSString *path = NSHomeDirectory();
  return [NSString stringWithFormat:@"%@/%@", path, fileName];
}

+ (NSURL *)applicationDocumentsDirectory {
  return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                 inDomains:NSUserDomainMask]
      lastObject];
}

+ (BOOL)isTesting {
  NSDictionary *environment = [[NSProcessInfo processInfo] environment];
  return [environment objectForKey:@"TEST"] != nil;
}

@end
