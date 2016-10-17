//
//  IosTools.m
//  sdkIOSDemo
//
//  Created by JustinYang on 16/8/30.
//
//

#import "ZYIosTools.h"


//for idfa
#import <AdSupport/AdSupport.h>
#import <Foundation/Foundation.h>
//for mac
#import <sys/socket.h>
#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>

//umeng message
#import "UMessage.h"


@implementation ZYIosTools


+ (ZYIosTools*)shareTools
{
    static ZYIosTools* s_share = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_share = [[ZYIosTools alloc] init];
    });
    return s_share;
}


- (id)init{
    self = [super init];
    if (self) {
        
        _proxy = [[ZYAppDelegateProxy alloc] init];
        
        @synchronized ([UIApplication sharedApplication]) {
            _proxy.naAppDelegate = [[ZYAppDelegate alloc] init];
            _proxy.originalAppDelegate = [UIApplication sharedApplication].delegate;
            [UIApplication sharedApplication].delegate = _proxy;// 这句最为重要
        }
        
        
        
        
        
        
    }
    return  self;
}


- (void)initWithMessage:(NSDictionary *)launchOptions
{
    //设置 AppKey 及 LaunchOptions
    [UMessage startWithAppkey:NSLocalizedString(@"UMENG_ID", nil) launchOptions:launchOptions];
    
    //1.3.0版本开始简化初始化过程。如不需要交互式的通知，下面用下面一句话注册通知即可。
    [UMessage registerForRemoteNotifications];
}




























@end
