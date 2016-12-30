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
#include "platform/ios/CCEAGLView-ios.h"    //cocos2dx 3.x
//#include "EAGLView.h"                       //cocos2dx 2.x
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
            int reward = 0;
            for (id value in awardDic) {
                ZYAwardInfo *info = [[ZYAwardInfo alloc] initWithDictionary:value];
                reward += info.reward.intValue;
                NSLog(@"%d",reward);
            }
            
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:nil
                                                         message:@"领取奖励成功"
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
            [av show];
            [av release];
        }
    }];
    //umeng的初始化
    uMeng::initUmeng();
    
    //wxpay;
    [[ZYWXApiManager sharedManager] setCallBack:^(WXTradeBody *Recharge) {
        //微信支付充值成功回调
    }];
    
#ifdef ZYTOOLS_ADVIEW
    //初始化adviewConfig
    ZYTools::initConfig();
#endif
}

void ZYTools::initAdSdk()
{
    //cocos2dx 2.x
//    EAGLView *eaglview = [EAGLView sharedEGLView];
    //cocos2dx 3.x
    auto view = cocos2d::Director::getInstance()->getOpenGLView();
    CCEAGLView *eaglview = (CCEAGLView *) view->getEAGLView();
    //添加互推
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
//    [[ZYParamOnline shareParam] showLog];   // 在线参数
//    [[ZYGameServer shareServer] showLog]; //互推
//    [[ZYIosRateApp shareRate] showLog];     //评论
//    [[ZYAdview shareAdview] showBannerLog];   //横幅
//    [[ZYAdview shareAdview] showInterlLog];   //插屏
//    [[ZYVideoManager sharedManager] showLog]; //视频
}

bool ZYTools::isCanRate()
{
    //判断是不是可以弹出评论
    if ([[ZYIosRateApp shareRate] isCanRateApp]) {
        return true;
    }else{
        return false;
    }
}

void ZYTools::rateWithTip()
{
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
}

void ZYTools::rateWithUrl()
{
    //可以弹出评论就弹出评论
    [[ZYIosRateApp shareRate] RateWithUrlAndBlock:^{
        //评论成功的回调 TODO：
    }];
}

void ZYTools::setAdCircle(bool isShow, cocos2d::Vec2 pot, float scale)
{
    //设置互推功能显示与否
    if (isShow) {
        //设置互推图片的位置和大小
        //这个设置根据自己的需求来修改
        [[ZYAdGameShow shareShow] showCircle:CGPointMake(pot.x, pot.y) Scale:scale];
    }else{
        [[ZYAdGameShow shareShow] hideCircle];
    }
}

void ZYTools::setAdTriangle(bool isShow, float scale)
{
    if (isShow) {
        [[ZYAdGameShow shareShow] showTriangle:TRIANGLE_TOP_RIGHT Scale:scale];
    }else{
        [[ZYAdGameShow shareShow] hideTriangle];
    }
}

void ZYTools::showBigPic()
{
    [[ZYAdGameShow shareShow] showDirect];
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
    //设置消费结构体
    WXTradeBody* body = [[WXTradeBody alloc] init];
    if (true) {
        body.price = [NSNumber numberWithFloat:6];
        body.productId = @"jinbi";
        body.productNum = [NSNumber numberWithInt:30];
    }
    //调用微信支付
    [[ZYWXApiManager sharedManager] sendWxPay:@"天天爱消除-游戏充值" body:body];
}
void ZYTools::queryWxpay()
{
//    [[ZYWXApiManager sharedManager] sendQueryPay:@"20161102174100097363708"];
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
    //cocos2dx 2.x
//    EAGLView *eaglview = [EAGLView sharedEGLView];
    //cocos2dx 3.x
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
