//
//  IosRateApp.h
//  sdkIOSDemo
//
//  Created by JustinYang on 16/8/24.
//
//

#import <Foundation/Foundation.h>

typedef void (^rateBack)();

@interface ZYIosRateApp : NSObject


+ (ZYIosRateApp*)shareRate;


/**
 是否可以评论
 */
- (BOOL)isCanRateApp;

/**
 直接跳转评论界面
 */
- (void)RateWithUrlAndBlock:(rateBack) rateCall;

/**
 弹出提示框提示玩家是否进行评论
 */
- (void)RateWithTipAndBlock:(rateBack) rateCall;

/**
 展示log
 */
- (void)showLog;

@end