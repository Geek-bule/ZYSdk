//
//  IosTools.h
//  sdkIOSDemo
//
//  Created by JustinYang on 16/8/30.
//
//

#import <Foundation/Foundation.h>
#import "ZYAppDelegate.h"
#import "ZYAppDelegateProxy.h"

@interface ZYIosTools : NSObject

@property(nonatomic,assign)ZYAppDelegateProxy *proxy;

+ (ZYIosTools*)shareTools;


/**
 初始化推送功能
 */
- (void)initWithMessage:(NSDictionary *)launchOptions;



@end
