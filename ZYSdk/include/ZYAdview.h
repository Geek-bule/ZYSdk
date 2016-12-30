//
//  ZYAdview.h
//  ZYAdview
//
//  Created by JustinYang on 16/9/1.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AdViewView.h"



@interface ZYAdview : NSObject<AdViewDelegate>
@property (nonatomic, assign)BOOL isShowLog;

+ (ZYAdview*)shareAdview;



/**
 adview sdk的初始化（必须）
 */
- (void)initAdView;


/**
 开平创建
 */
- (void)createSplash;

- (void)showSplashLog;


/**
 banner 创建
 */
- (void)createBanner:(UIView*)view;

- (void)showBanner;

- (void)hideBanner;

- (void)setAdPosition:(CGPoint) point;

- (void)showBannerLog;


/**
 插屏创建
 */
- (void)createInstl;

- (void)showInstl;

- (void)showInterlLog;




@end
