//
//  AdVideoManager.h
//  sdkIOSDemo
//
//  Created by JustinYang on 16/8/26.
//
//

#import "ZYVideoAdapter.h"


typedef void (^beginPlay)();
typedef void (^pausePlay)();
typedef void (^finishPlay)();
typedef void (^isHasVideo)(BOOL isHas);


@interface ZYVideoManager : NSObject<videoDelegate>
{
//    AdVideoAdapter *nextAdapter;
    //回调
    beginPlay   _beginPlay;
    pausePlay   _pausePlay;
    finishPlay  _finishPlay;
    isHasVideo  _isHasCall;
    int         _repeatTimes;
    BOOL        _isLock;
}



+ (ZYVideoManager *)sharedManager;

- (void)loadVideoConfig;

- (void)showVideo:(UIViewController *)viewController begin:(beginPlay)begin pause:(pausePlay)pause finish:(finishPlay)finish;

- (void)isHasVideo:(isHasVideo)isHasBack;

- (void)showLog;

@end
