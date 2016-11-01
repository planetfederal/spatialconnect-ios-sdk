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

#import "SCWebAppZipLoader.h"

@implementation SCWebAppZipLoader

+ (NSString *)unzipFile:(NSString *)zipFilePath {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  NSURL *path = [[NSURL fileURLWithPath:[paths objectAtIndex:0]]
      URLByAppendingPathComponent:@"webapps"];
  [fileManager createDirectoryAtURL:path
        withIntermediateDirectories:YES
                         attributes:nil
                              error:nil];
  NSError *error;
  ZZArchive *archive =
      [ZZArchive archiveWithURL:[NSURL fileURLWithPath:zipFilePath]
                          error:&error];
  if (error) {
    DDLogError(@"%@", error.debugDescription);
  }
  NSString *indexHTMLPath = nil;
  for (ZZArchiveEntry *entry in archive.entries) {
    NSURL *targetPath = [path URLByAppendingPathComponent:entry.fileName];

    if (entry.fileMode & S_IFDIR)
      // check if directory bit is set
      [fileManager createDirectoryAtURL:targetPath
            withIntermediateDirectories:YES
                             attributes:nil
                                  error:nil];
    else {
      // Some archives don't have a separate entry for each directory
      // and just include the directory's name in the filename.
      // Make sure that directory exists before writing a file into it.
      [fileManager createDirectoryAtURL:[targetPath
                                            URLByDeletingLastPathComponent]
            withIntermediateDirectories:YES
                             attributes:nil
                                  error:nil];

      if ([[targetPath path] containsString:@"index.html"]) {
        indexHTMLPath = [targetPath path];
      }

      [[entry newDataWithError:nil] writeToURL:targetPath atomically:YES];
    }
  }
  return indexHTMLPath;
}
@end
