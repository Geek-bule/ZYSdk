//
//  ZYAdGameShow.h
//  sdkIOSDemo
//
//  Created by JustinYang on 16/9/6.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ZYAdGameShow : NSObject



+ (ZYAdGameShow*)shareShow;

- (void)showAdGame:(UIView*)mainView;

- (void)setAdHide:(BOOL)isHide Page:(int)page;

- (void)setAdPot:(CGPoint)pot Scale:(CGFloat)scale;

@end
