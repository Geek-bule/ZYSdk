//
//  AdVideoClassWrapper.m
//  sdkIOSDemo
//
//  Created by JustinYang on 16/9/20.
//
//

#import "ZYVideoClassWrapper.h"

@implementation ZYVideoClassWrapper

@synthesize theClass;
@synthesize theEnable;
@synthesize theHide;

- (id)initWithClass:(Class)c {
    self = [super init];
    if (self != nil) {
        theClass = c;
        theEnable = YES;
        theHide = NO;
    }
    return self;
}

@end
