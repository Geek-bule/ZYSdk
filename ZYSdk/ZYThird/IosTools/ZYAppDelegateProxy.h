//
//  NABAppDelegateProxy.h
//  sdkIOSDemo
//
//  Created by JustinYang on 16/8/30.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ZYAppDelegateProxy : NSProxy <UIApplicationDelegate>
- (id)init;
@property (nonatomic, strong) NSObject<UIApplicationDelegate> *naAppDelegate;
@property (nonatomic, strong) NSObject<UIApplicationDelegate> *originalAppDelegate;
@end
