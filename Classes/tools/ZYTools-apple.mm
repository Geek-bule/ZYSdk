//
//  ZYTools-apple.cpp
//  sdkIOSDemo
//
//  Created by JustinYang on 16/9/30.
//
//

#include "ZYTools.h"
#include "ZYGameServer.h"
#include "ZYParamOnline.h"
#include "ZYAdGameShow.h"
#include "platform/ios/CCEAGLView-ios.h"
#include "ZYIosRateApp.h"
#include "ZYAwardInfo.h"
#include "HelloWorldScene.h"
#include "WeChatApi.h"
#include "uMeng.h"
#ifdef ZYTOOLS_ADVIEW
#include "ZYAdview.h"
#endif
#ifdef ZYTOOLS_VIDEO
#include "ZYVideoManager.h"
#endif


void ZYTools::init()
{
    //开启log
    ZYTools::showLog();
    
    //初始化在线参数
    [[ZYParamOnline shareParam] initParamBack:^(NSDictionary *dict) {
     
     }];
    //初始化版本提醒
    [[ZYParamOnline shareParam] checkNewVersion];
    //初始化互推游戏
    [[ZYGameServer shareServer] loadGameServer];
    
    //游戏互推奖励
    [[ZYGameServer shareServer] setAward:nil andGive:^(NSArray *awardDic) {
        //TODO:在这里给玩家奖励
        if (awardDic.count > 0) {
            for (ZYAwardInfo *info in awardDic) {
                
            }
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:nil
                                                         message:@"领取互推奖励成功"
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
            [av show];
            [av release];
        }
    }];
    //umeng的初始化
    uMeng::initUmeng();
    
#ifdef ZYTOOLS_ADVIEW
    //初始化adviewConfig
    ZYTools::initConfig();
#endif
}

void ZYTools::initAdSdk()
{
    //添加互推
    auto view = cocos2d::Director::getInstance()->getOpenGLView();
    CCEAGLView *eaglview = (CCEAGLView *) view->getEAGLView();
    [[ZYAdGameShow shareShow] showAdGame:eaglview];
#ifdef ZYTOOLS_ADVIEW
    //初始化横幅
    ZYTools::initBannerView();
    //初始化插屏
    ZYTools::initInterstitial();
#endif
#ifdef ZYTOOLS_VIDEO
    //初始化视频sdk
    ZYTools::initVideoSdk();
#endif
}


std::string ZYTools::getParamOf(std::string key)
{
    NSString* paramKey = [NSString stringWithUTF8String:key.c_str()];
    NSString* paramValue = [[ZYParamOnline shareParam] getParamOf:paramKey];
    return [paramValue UTF8String];
}


void ZYTools::showLog()
{
    //需要显示的日志打开即可
    [[ZYParamOnline shareParam] showLog];
    [[ZYGameServer shareServer] showLog];
//    [[ZYIosRateApp shareRate] showLog];
//    [[ZYAdview shareAdview] showBannerLog];
//    [[ZYAdview shareAdview] showInterlLog];
    [[ZYVideoManager sharedManager] showLog];
}


void ZYTools::rateWithTip()
{
    //判断是不是可以弹出评论
    if ([[ZYIosRateApp shareRate] isCanRateApp]) {
        //可以弹出评论就弹出评论
        [[ZYIosRateApp shareRate] RateWithTipAndBlock:^{
            //评论成功的回调 TODO：
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:nil
                                                         message:@"评论成功"
                                                        delegate:nil       //委托给Self，才会执行上面的调用
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
            [av show];
            [av release];
         }];
    }else{
        //不可以弹出评论的时候进行处理
    }
}

void ZYTools::rateWithUrl()
{
    //判断是不是可以弹出评论
    if ([[ZYIosRateApp shareRate] isCanRateApp]) {
        //可以弹出评论就弹出评论
        [[ZYIosRateApp shareRate] RateWithUrlAndBlock:^{
            //评论成功的回调 TODO：
         }];
    }else{
        //不可以弹出评论的时候进行处理
    }
}

void ZYTools::setAdGame(bool isShow)
{
    //设置互推功能显示与否
    [[ZYAdGameShow shareShow] setAdHide:!isShow Page:0];
}

void ZYTools::setAdGamePos()
{
    //设置互推图片的位置和大小
    //这个设置根据自己的需求来修改
    [[ZYAdGameShow shareShow] setAdPot:CGPointMake(0.2, 0.9) Scale:1.0];
}

void ZYTools::registerTest()
{
    [[ZYGameServer shareServer] registerTest];
}

void ZYTools::reviewPort()
{
    //审核接口（每次根据策划指定的位置调用函数，同以前的umengbug函数一样）
    [[ZYParamOnline shareParam] reviewPort];
}


bool ZYTools::isReviewStatus()
{
    //判断审核状态，可用于审核时隐藏部分功能（将在线参数中的 ZYVersion 填写成与当前审核版本号相同即进入审核状态）
    return [[ZYParamOnline shareParam] isReviewStatus];
}


void ZYTools::startWxPay()
{
    [[WXApiManager sharedManager] sendWxPay:@"天天爱消除-游戏充值" price:1 back:^(PayResp* resp){
        switch (resp.errCode) {
            case WXSuccess:
                //支付成功，给玩家物品
                NSLog(@"微信支付：支付成功－PaySuccess，retcode = %d", resp.errCode);
                break;
                
            default:
                NSLog(@"微信支付：支付结果：失败！retcode = %d, retstr = %@", resp.errCode,resp.errStr);
                break;
        }
    }];
}
void ZYTools::queryWxpay()
{
//    [[WXApiManager sharedManager] sendQueryPay:@"20161102174100097363708"];
}


    //==========ZYAdview sdk接入==========
#ifdef ZYTOOLS_ADVIEW
void ZYTools::initConfig()
{
    [[ZYAdview shareAdview] initAdView];
}

//init banner
void ZYTools::initBannerView()
{
    auto view = cocos2d::Director::getInstance()->getOpenGLView();
    CCEAGLView *eaglview = (CCEAGLView *) view->getEAGLView();
    [[ZYAdview shareAdview] createBanner:eaglview];
    [[ZYAdview shareAdview] setAdPosition:CGPointMake(-1, -2)];//banner位置 0:上 -1:中 -2:下
}

//showBanner
void ZYTools::showBannerView()
{
    [[ZYAdview shareAdview] showBanner];
}

//hideBanner
void ZYTools::hideBannerView()
{
    [[ZYAdview shareAdview] hideBanner];
}

//init interstitial
void ZYTools::initInterstitial()
{
    [[ZYAdview shareAdview] createInstl];
}
//show interstitial
void ZYTools::showInterstitial()
{
    [[ZYAdview shareAdview] showInstl];
}

//show splash
void ZYTools::showSplash()
{
    [[ZYAdview shareAdview] createSplash];
}
#endif






    //==========ZYVideo sdk接入==========
#ifdef ZYTOOLS_VIDEO
bool ZYTools::_isHasVideoNow = false;
ccVideoCallback ZYTools::_videoPlayFinish;
std::vector<ccStatusCallback> ZYTools::_videoStatusVec;
//init video
void ZYTools::initVideoSdk()
{
    ZYVideoManager*manager = [ZYVideoManager sharedManager];
    [manager loadVideoConfig];
    [manager isHasVideo:^(BOOL isHas) {
        //根据视频是否存在来设定视频按钮显示与隐藏
        //TODO:
        _isHasVideoNow = isHas;
        for (auto iter : _videoStatusVec) {
            ccStatusCallback &isHasVide = iter;
            if (isHasVide) {
                isHasVide(isHas);
            }
        }
     }];
}

void ZYTools::setVideoStatus(const ccStatusCallback &isHasVide)
{
    if (isHasVide) {
        _videoStatusVec.push_back(isHasVide);
    }
}

//show video
void ZYTools::showVideo(const ccVideoCallback &videoPlayFinish)
{
    UIViewController *result = nil;
    UIWindow *topWindow = [[UIApplication sharedApplication] keyWindow];
    if (topWindow.windowLevel != UIWindowLevelNormal){
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(topWindow in windows){
            if (topWindow.windowLevel == UIWindowLevelNormal){
                break;
            }
        }
    }
    UIView *rootView = [[topWindow subviews] objectAtIndex:0];
    id nextResponder = [rootView nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]]){
        result = nextResponder;
    }else if ([topWindow respondsToSelector:@selector(rootViewController)] && topWindow.rootViewController != nil){
        result = topWindow.rootViewController;
    }
    _videoPlayFinish = videoPlayFinish;
    
    [[ZYVideoManager sharedManager] showVideo:result begin:^{
        //暂停音乐 TODO:
     } pause:^{
         //开启音乐 TODO:
     } finish:^{
         //开启音乐 TODO:
         //视频播放成功之后给玩家奖励
         if (_videoPlayFinish) {
             _videoPlayFinish();
         }
     }];
}
#endif
