//
//  tools.cpp
//  SpriteSheet
//
//  Created by JustinYang on 15/8/15.
//
//

#include "tools.h"
#include "sdkConfig.h"
#include "toolsKt.hpp"
#include "GameParam.hpp"
#include "AdViewBanner.h"

#import "AppController.h"
#import "RootViewController.h"
#import "GeneralizeServer.h"
#import "KTPlay.h"
#import "ZYParamOnline.h"
#import "MobClick.h"
#import "MobClickGameAnalytics.h"
#import "MobClickSocialAnalytics.h"
#import "VersionAgent.h"
#import "Toast+UIView.h"
#import "NotificateHelper.h"
#import "SVWebViewController.h"
#import "Reachability.h"
#import "AdViewConfigStore.h"
#import "IOSInfo.h"
#import "ZYIosTools.h"
#import <ShareSDK/ShareSDK.h>
#import "WXApi.h"
#import "ZYIosRateApp.h"

#ifdef IOSAPDATE_UN
#import "InMobi.h"
#endif


#define isPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)


#ifdef IOSAPDATE
#endif


std::string statusPage = "空";

bool tools::s_isReviewVersion = true;

void gameParamCallBack(paramMap param)
{
    //检查是否是审核版本
    std::string newVersion = GameParam::getInstance().getParam(UM_VERSION);
    std::string curVersion = IOSInfo::getVersion();
    
    if (atof(newVersion.c_str()) >= atof(curVersion.c_str())) {
        tools::s_isReviewVersion = false;
    }
    
    tools::InitKtplay();
}


void tools::Init()
{
#ifdef IOSAPDATE
    
#endif
    //获取在线参数
    [[ZYParamOnline shareParam] initWithParamBack:^(NSDictionary *dict){
        
    }];
    
    [[ZYParamOnline shareParam] checkNewVersion];
    
    //推荐游戏信息获取
    GeneralizeServer::create(APPID_IOS);
    
    //adview的必需出实话
    std::vector<std::string> adviewKeyVec;
    adviewKeyVec.push_back(ADVIEW_KEY);
//    adviewKeyVec.push_back(ADVIEW_KEY1);
    AdViewBanner::sharedBanner()->startAdviewConfig(adviewKeyVec);
    
    
    
    //能量提醒初始化
    [NotificateHelper ShareHelper];
}

void tools::InitKtplay()
{
#ifdef IOSAPDATE
    [KTPlay startWithAppKey:KTPLAY_APPID appSecret:KTPLAY_SECRET];
    toolsKtAccount::getInstance().setLoginStatus();
    toolsKtPlay::getInstance().setDidDispatchRewards();
    toolsKtPlay::getInstance().setActivityStatus();
    toolsKtPlay::getInstance().setKTAvailabilityStatus();
#endif
}

bool tools::IsIPad()
{  
#ifdef IOSAPDATE
    return isPad;
#endif
}

//
////苹果计费部分
//

bool tools::IsNotAppReview()
{
    return !tools::s_isReviewVersion;
}

//
////ios评论
//

//直接跳转评论
void tools::RateGameUrl()
{
#ifdef IOSAPDATE
    if ([[ZYIosRateApp shareRate] isCanRateApp]) {
        [[ZYIosRateApp shareRate] RateWithUrlAndBlock:^{
            //给玩家的奖励并提醒玩家
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"award tip", nil)
                                                         message:NSLocalizedString(@"award msg", nil)
                                                        delegate:nil       //委托给Self，才会执行上面的调用
                                               cancelButtonTitle:NSLocalizedString(@"award ok", nil)
                                               otherButtonTitles:nil];
            [av show];
            [av release];
        }];
    }else{
        NSLog(@"评论：不能评论了");
    }
#endif
}
//弹出评论提示
void tools::RateGameTip()
{
#ifdef IOSAPDATE
    if ([[ZYIosRateApp shareRate] isCanRateApp]) {
        [[ZYIosRateApp shareRate] RateWithTipAndBlock:^{
            //给玩家的奖励并提醒玩家
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"award tip", nil)
                                                         message:NSLocalizedString(@"award msg", nil)
                                                        delegate:nil       //委托给Self，才会执行上面的调用
                                               cancelButtonTitle:NSLocalizedString(@"award ok", nil)
                                               otherButtonTitles:nil];
            [av show];
            [av release];
        }];
    }else{
        NSLog(@"评论：不能评论了");
    }
#endif
}



void tools::Toast(std::string msg)
{
    /* 安卓部分填出下面提示条的代码
     static void Toast(String message) {
     Toast.makeText(activity, message,Toast.LENGTH_LONG).show();
     }
     */
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    JniMethodInfo minfo;//定义Jni函数信息结构体
    bool isHave;
    isHave = JniHelper::getStaticMethodInfo(minfo,"com/zongyi/identifier/javaName","Toast", "(Ljava/lang/String;)V");
    
    jstring stringArg2 = t.env->NewStringUTF(msg);
    if (!isHave) {
        CCLog("jni:openUrl此函数不存在");
    }else{
        CCLog("jni:openUrl此函数存在");
        //调用此函数
        minfo.env->CallStaticVoidMethod(minfo.classID, minfo.methodID, stringArg2);
    }
    CCLog("jni-java函数执行完毕");
#endif
#ifdef IOSAPDATE
    NSString *message = [NSString stringWithUTF8String:msg.c_str()];
    AppController *delegate = (AppController* ) [UIApplication sharedApplication].delegate;
    [delegate.viewController.view makeToast:message];
#endif
}


void tools::openUrlInApp(std::string url)
{
#ifdef IOSAPDATE
    AppController *delegate = (AppController* ) [UIApplication sharedApplication].delegate;
    NSURL *URL = [NSURL URLWithString:[NSString stringWithUTF8String:url.c_str()]];
    SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithURL:URL];
    webViewController.modalPresentationStyle = UIModalPresentationPageSheet;
    [delegate.viewController presentViewController:webViewController animated:YES completion:NULL];
#endif
}

void tools::openUrl(std::string url)
{
#ifdef IOSAPDATE
    NSURL *urlOS= [NSURL URLWithString:[NSString stringWithUTF8String:url.c_str()]];
    [[UIApplication sharedApplication] openURL:urlOS];
#endif
}

void tools::openDeepLink()
{
#ifdef IOSAPDATE
    NSURL *url = [NSURL URLWithString:@"http://fm.p0y.cn/m/d/mdpl.html?scheme=meilapp%3A%2F%2Furl%2Fhttp%253A%252F%252Fdev.meilapp.com%253A10001%252Fware%252Fpwnm%252F%253Futm_channel%253Dpinyou&url=https://itunes.apple.com/cn/app/id624943498"];
    if ([[UIApplication sharedApplication] canOpenURL:url])
    {
        [[UIApplication sharedApplication] openURL:url];
    }
#endif
}

void tools::OpenMoreGameList()
{
    tools::openUrlInApp("http://www.zongyigame.com/web/");
}



void tools::uMengPayCoin(double cash, int source, double coin)
{
#ifdef IOSAPDATE
    [MobClickGameAnalytics pay:cash source:source coin:coin];
#endif
}

void tools::uMengPayProps(double cash, int source, std::string item, int amount, double price)
{
#ifdef IOSAPDATE
    NSString *_item = [NSString stringWithUTF8String:item.c_str()];
    [MobClickGameAnalytics pay:cash source:source item:_item amount:amount price:price];
#endif
}

void tools::uMengBuyProps(std::string item, int amount, double price)
{
#ifdef IOSAPDATE
    NSString *_item = [NSString stringWithUTF8String:item.c_str()];
    [MobClickGameAnalytics buy:_item amount:amount price:price];
#endif
}

void tools::uMengUseProps(std::string item, int amount, double price)
{
#ifdef IOSAPDATE
    NSString *_item = [NSString stringWithUTF8String:item.c_str()];
    [MobClickGameAnalytics use:_item amount:amount price:price];
#endif
}

void tools::uMengStartLevel(std::string level)
{
#ifdef IOSAPDATE
    NSString *_level = [NSString stringWithUTF8String:level.c_str()];
    [MobClickGameAnalytics startLevel:_level];
#endif
}

void tools::uMengFinishLevel(std::string level)
{
#ifdef IOSAPDATE
    NSString *_level = [NSString stringWithUTF8String:level.c_str()];
    [MobClickGameAnalytics finishLevel:_level];
#endif
}

void tools::uMengFailLevel(std::string level)
{
#ifdef IOSAPDATE
    NSString *_level = [NSString stringWithUTF8String:level.c_str()];
    [MobClickGameAnalytics failLevel:_level];
#endif
}

void tools::uMengBonusCoin(double coin, int source)
{
#ifdef IOSAPDATE
    [MobClickGameAnalytics bonus:coin source:source];
#endif
}

void tools::uMengBonusPorps(std::string item, int amount, double price, int source)
{
#ifdef IOSAPDATE
    NSString *_item = [NSString stringWithUTF8String:item.c_str()];
    [MobClickGameAnalytics bonus:_item amount:amount price:price source:source];
#endif
}

void tools::uMengUserLevel(int level)
{
#ifdef IOSAPDATE
    [MobClickGameAnalytics setUserLevelId:level];
#endif
}

void tools::uMengPageInfo(std::string page)
{
#ifdef IOSAPDATE
    NSString *strLable = [NSString stringWithUTF8String:page.c_str()];
    [MobClick event:@"page" label:strLable];
#endif
}

void tools::uMengBug()
{
#ifdef IOSAPDATE
    int bug = GameParam::getInstance().getParamInt(UM_BUG);
    if (bug == 1 && tools::IsNotAppReview()) {
        CCDirector::getInstance()->end();
        exit(0);
    }
#endif
}

//
//// notification
//

int tools::getNotificateSecond()
{
    int nTime = 5;
    return nTime;//设置多久之后进行提醒
}

bool tools::getNotificateStatus()
{
#ifdef IOSAPDATE
    return [[NotificateHelper ShareHelper] getNotificate];
#endif
}

void tools::setNotificateStatus(bool isOpen)
{
#ifdef IOSAPDATE
    [[NotificateHelper ShareHelper] setNotificate:isOpen];
#endif
}

//
////
//

void tools::cleanVideoCache()
{
#ifdef IOSAPDATE
    int kt = GameParam::getInstance().getParamInt(UM_CACHE);
    if (kt == 1) {
        tools::deleteLibraryCache("/Caches/IVCache");
        tools::deleteLibraryCache("/videoHNSDK");
    }
#endif
}

void tools::deleteLibraryCache(std::string path)
{
#ifdef IOSAPDATE
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask, YES);
    NSString *libPath = [paths lastObject];
    NSString *ivCache = [libPath stringByAppendingString:[NSString stringWithUTF8String:path.c_str()]];
    NSLog(@"%@ \n %@",ivCache,libPath);
    /**
        NSDictionary *attrDic = [fm attributesOfItemAtPath:ivCache error:nil];
        NSNumber *fileSize = [attrDic objectForKey:NSFileSize];
        float fileSize = tools::getPathSize([ivCache UTF8String]);
        NSLog(@"library size = %@",fileSize);
     */
    if([fm fileExistsAtPath:ivCache])
    {
        NSError **error;
        if ([fm removeItemAtPath:ivCache error:error])
        {
            NSLog(@"remove success");
        }else{
            NSLog(@"error %@",*error);
        }
    }
#endif
}

void tools::deleteDocumentCache(std::string path)
{
#ifdef IOSAPDATE
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *libPath = [paths lastObject];
    NSString *ivCache = [libPath stringByAppendingString:[NSString stringWithUTF8String:path.c_str()]];
    NSLog(@"%@ \n %@",ivCache,libPath);
    /**
     NSDictionary *attrDic = [fm attributesOfItemAtPath:ivCache error:nil];
     NSNumber *fileSize = [attrDic objectForKey:NSFileSize];
     float fileSize = tools::getPathSize([ivCache UTF8String]);
     NSLog(@"library size = %@",fileSize);
     */
    if([fm fileExistsAtPath:ivCache])
    {
        NSError **error;
        if ([fm removeItemAtPath:ivCache error:error])
        {
            NSLog(@"remove success");
        }else{
            NSLog(@"error %@",*error);
        }
    }
#endif
}


//遍历文件夹获得文件夹大小，返回多少M
float tools::getPathSize(std::string filePath)
{
#ifdef IOSAPDATE
    NSString *folderPath = [NSString stringWithUTF8String:filePath.c_str()];
    NSFileManager* manager = [NSFileManager defaultManager];
    
    if (![manager fileExistsAtPath:folderPath]) return 0;
    
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    
    NSString* fileName;
    
    long long folderSize = 0;
    
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        std::string absolutePath = [fileAbsolutePath UTF8String];
        folderSize += tools::getPathSize(absolutePath);
        
    }
    
    return folderSize/(1024.0*1024.0);
#endif
}

//额外部分
int tools::checkReachable()
{
#ifdef IOSAPDATE
    Reachability *r = [Reachability reachabilityWithHostName:@"www.apple.com"];
    switch ([r currentReachabilityStatus]) {
        case NotReachable:
            // 没有网络连接
            return 0;
        case ReachableViaWWAN:
            // 使用3G网络
            return 1;
        case ReachableViaWiFi:
            // 使用WiFi网络
            return 2;
            default:
            return 0;
    }
#endif
}
