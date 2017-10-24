//
//  EXTConcreteProtocolTest.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2010-11-09.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "EXTConcreteProtocol.h"
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

@protocol MyProtocol <NSObject>
@concrete + (NSUInteger)meaningfulNumber;
- (NSString *)getSomeString;
@end

@protocol SubProtocol <MyProtocol>
@concrete - (void)additionalMethod;
@end

@interface EXTConcreteProtocolTest : XCTestCase {
}

- (void)testImplementations;
- (void)testSimpleInheritance;
- (void)testClassInheritanceWithProtocolInheritance;

@end
