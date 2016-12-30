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
 *  @brief  是否可以评论
 */
- (BOOL)isCanRateApp;

/**
 *  @brief  直接跳转评论界面
 *  @param  rateCall        评论成功回调
 */
- (void)RateWithUrlAndBlock:(rateBack) rateCall;

/**
 *  @brief  弹出提示框提示玩家是否进行评论
 *  @param  rateCall        评论成功回调
 */
- (void)RateWithTipAndBlock:(rateBack) rateCall;

/**
 *  @brief  展示log
 */
- (void)showLog;

@end