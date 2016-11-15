//
//  ZYAdGameShow.h
//  sdkIOSDemo
//
//  Created by JustinYang on 16/9/6.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>



#define TRIANGLE_TOP_LEFT           1
#define TRIANGLE_TOP_RIGHT          2
#define TRIANGLE_BOTTOM_LEFT        3
#define TRIANGLE_BOTTOM_RIGHT       4



@interface ZYAdGameShow : NSObject



+ (ZYAdGameShow*)shareShow;

/**
 *  @brief  设置互推界面显示的View
 *  @param  mainView    互推显示view
 */
- (void)showAdGame:(UIView*)mainView;

/**
 *  @brief  直接显示互推大图
 */
- (void)showDirect;

/**
 *  @brief  显示圆形按钮并设定大小和位置
 *  @param  pot         view界面的百分比位置，如（0.2，0.5）
 *  @param  scale       圆形按钮的缩放比例
 */
- (void)showCircle:(CGPoint)pot Scale:(CGFloat)scale;

/**
 *  @brief  隐藏圆形按钮
 */
- (void)hideCircle;

/**
 *  @brief  显示三角按钮并设定大小和位置
 *  @param  potType     三角按钮的位置，分为屏幕的4个角
 *  @param  scale       三角按钮的大小
 */
- (void)showTriangle:(int)potType Scale:(CGFloat)scale;

/**
 *  @brief  隐藏三角按钮
 */
- (void)hideTriangle;



@end
