//
//  AdViewSplashAds.cpp
//  AdsMogoCocos2dxSample
//
//  Created by Castiel on 2015-3-26
//
//

#include "AdViewSplashAds.h"



@implementation SplashAdsObj

+ (SplashAdsObj *)sharedSplashAdsObj {
    static SplashAdsObj *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}


-(void)createSplashAds:(NSString*)mogoid
{
    UIWindow *topWindow = [[UIApplication sharedApplication] keyWindow];
    self.splashAds = [AdSpreadScreenManager managerWithAdSpreadScreenKey:mogoid WithDelegate:self];

    [self.splashAds requestAdSpreadScreenView:topWindow.rootViewController];
    
    _isShowLog= NO;
    
}

-(void)showLog{
    _isShowLog = YES;
}

#pragma mark -
#pragma mark ADMOGO splashads management

/**
 * 信息回调 */
-(void)adSpreadScreenManager:(AdSpreadScreenManager*)manager didGetEvent:(SpreadScreenEventType)eType error:(NSError*)error
{
    switch (eType) {
        case SpreadScreenEventType_DidLoadAd:
            if(_isShowLog)NSLog(@"快有聚合开屏：加载成功");
            break;
        case SpreadScreenEventType_FailLoadAd:
            if(_isShowLog)NSLog(@"快有聚合开屏：加载失败%@",error);
            break;
        case SpreadScreenEventType_DidShowAd:
            if(_isShowLog)NSLog(@"快有聚合开屏：展示成功");
            break;
        case SpreadScreenEventType_DidClickAd:
            if(_isShowLog)NSLog(@"快有聚合开屏：点击成功");
            break;
        default:
            break;
    }
}

/**
 * 取得配置的回调通知
 */
- (void)adSpreadScreenDidReceiveConfig:(AdSpreadScreenManager*)manager
{
    if(_isShowLog)NSLog(@"快有聚合开屏：取得配置成功");
}

/**
 * 配置全部 效或为空的通知
*/ -(void)adSpreadScreenReceivedNotificationAdsAreOff: (AdSpreadScreenManager*)manager
{
    if(_isShowLog)NSLog(@"快有聚合开屏：取得配置失败");
}

/**
 * 是否打开测试模式,缺省为NO
 */
- (BOOL)adSpreadScreenTestMode
{
    return NO;
}

/**
 * 是否打开 志模式,缺省为NO 
 */

- (BOOL)adSpreadScreenLogMode
{
    return _isShowLog;
}

/**
 * 是否获取地理位置,缺省为NO
*/
- (BOOL)adSpreadScreenOpenGps
{
    return NO;
}

/**
 * 是否使 html5 告,缺省为NO 
 */

- (BOOL)adSpreadScreenUsingHtml5
{
    return NO;
}

- (UIWindow *)adSpreadScreenWindow {
    UIWindow *topWindow = [[UIApplication sharedApplication] keyWindow];
    return topWindow;
}

- (NSString *)adSpreadScreenLogoImgName
{
    return @"Adview_Logo.jpg";
}

- (UIColor *)adSpreadScreenBackgroundColor
{
    return [UIColor whiteColor];
}


@end


//
//
//
//AdViewSplashAds * AdViewSplashAds ::sharedInterstitial(){
//    static AdViewSplashAds * banner=NULL;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken,^{
//        banner= new AdViewSplashAds;
//    });
//    return banner;
//}
//void AdViewSplashAds::loadSplashAds(const char* appid){
//    std::string adviewKey = cocos2d::CCUserDefault::sharedUserDefault()->getStringForKey(ADVIEWIDKey);
//    if (strcmp(adviewKey.c_str(), "") == 0) {
//        adviewKey = appid;
//    }
//    NSString *mogo_id = [[[NSString alloc] initWithCString:adviewKey.c_str()
//                                                 encoding:NSASCIIStringEncoding] autorelease];
//    
//    //For advertising
//    SplashAdsObj  * inter_obj= [SplashAdsObj sharedSplashAdsObj];
//    [inter_obj createInterstitial:mogo_id];
//}
//
