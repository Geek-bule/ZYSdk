//
//  NABAppDelegate.m
//  sdkIOSDemo
//
//  Created by JustinYang on 16/8/30.
//
//

#import "ZYAppDelegate.h"
#import "UMessage.h"

@implementation ZYAppDelegate


- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSLog(@"%@, %@", application, notification);
    // ＳＤＫ在这里，可以做自己想做的事
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [UMessage didReceiveRemoteNotification:userInfo];
}

@end
