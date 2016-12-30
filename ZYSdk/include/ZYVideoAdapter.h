//
//  AdVideoAdapter.h
//  sdkIOSDemo
//
//  Created by JustinYang on 16/8/26.
//
//

#import "ZYVideoType.h"
#import <UIKit/UIKit.h>
#import "ZYVideoAdRegistry.h"

@class ZYVideoAdapter;
@protocol videoDelegate <NSObject>

@required
- (void)success:(ZYVideoAdapter*)adapter withType:(ZYVideoType)type;


- (void)failure:(ZYVideoAdapter*)adapter withType:(ZYVideoType)type;


- (void)play:(ZYVideoAdapter*)adapter withType:(ZYVideoType)type;


- (void)pause:(ZYVideoAdapter*)adapter withType:(ZYVideoType)type;


- (void)finish:(ZYVideoAdapter*)adapter withType:(ZYVideoType)type;

@end


@interface ZYVideoAdapter : NSObject
{
    
}

@property(nonatomic, weak) id<videoDelegate> delegate;
@property(nonatomic, retain) NSString* appid;
@property(nonatomic, retain) NSString* appsrec;
@property(nonatomic)    BOOL isShowLog;


- (void)initAd;

- (void)getAd;

- (void)showVideo:(UIViewController *)viewController;

- (void)showLog;

@end
