//
//  AdVideoAdapter.m
//  sdkIOSDemo
//
//  Created by JustinYang on 16/8/26.
//
//

#import "ZYVideoAdapter.h"

@implementation ZYVideoAdapter


- (id)init
{
    self = [super init];
    if (self) {
        _isShowLog = NO;
    }
    return self;
}


- (void)initAd
{
    NSLog(@"AdVideoAdapter_initAd");
}


- (void)getAd
{
    NSLog(@"AdVideoAdapter_getAd");
}


- (void)showVideo:(UIViewController *)viewController
{
    NSLog(@"AdVideoAdapter_showVideo");
}

- (void)showLog
{
    _isShowLog = YES;
}

@end
