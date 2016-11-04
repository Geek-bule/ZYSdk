//
//  ZYAdview.m
//  ZYAdview
//
//  Created by JustinYang on 16/9/1.
//
//

#import "ZYAdview.h"
#import "AdViewConfigStore.h"
#import "AdViewSplashAds.h"
#import "AdViewInterstitial.h"
#import "AdViewController.h"


@interface ZYAdview()

@property (nonatomic,retain)    NSString *adView_Keys;
@property (nonatomic,retain)    NSString *paramKey;

@end




@implementation ZYAdview


#define ZYADVIEW_KEY    @"ZYAdviewKey"


+ (ZYAdview *)shareAdview {
    static ZYAdview *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ZYAdview alloc] init];
    });
    return instance;
}


- (id)init
{
    self = [super init];
    if (self) {
        NSString *bundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"ZYSdk.bundle"];
        NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
        NSString *plistPath = [bundle pathForResource:@"appConfig" ofType:@"plist"];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
        _adView_Keys = [dict objectForKey:@"adview_key"];
        
        _paramKey = [[NSUserDefaults standardUserDefaults] objectForKey:ZYADVIEW_KEY];
    }
    return self;
}


- (void)initAdView
{
    AdViewConfigStore *cfg = [AdViewConfigStore sharedStore];
    if (_paramKey && ![_paramKey isEqualToString:@""]) {
        _adView_Keys = _paramKey;
    }
    [cfg requestConfig:@[_adView_Keys] sdkType:AdViewSDKType_SpreadScreen];
    [cfg requestConfig:@[_adView_Keys] sdkType:AdViewSDKType_Banner];
    [cfg requestConfig:@[_adView_Keys] sdkType:AdViewSDKType_Instl];
    _isShowLog = NO;
}

/**
 开平创建
 */
- (void)createSplash
{
    [[SplashAdsObj sharedSplashAdsObj] createSplashAds:_adView_Keys];
}

- (void)showSplashLog
{
    [[SplashAdsObj sharedSplashAdsObj] showLog];
}

/**
 banner 创建
 */
- (void)createBanner:(UIView*)view
{
    AdViewController * controller = [AdViewController sharedController];
    [controller setAdViewKey:_adView_Keys];
    [controller setOrientationUp:NO Down:NO Left:NO Right:YES];
    [controller setAdBannerSize:AdviewBannerSize_Auto];
    [controller setAdRootController:[self viewControllerForPresentingModalView]];
    [controller setAdPosition:CGPointMake(-1, -2)];
    [controller loadView];
    [view addSubview:controller.adView];
}

- (void)showBanner
{
    AdViewController * controller = [AdViewController sharedController];
    [controller setAdHidden:NO];
}

- (void)hideBanner
{
    AdViewController * controller = [AdViewController sharedController];
    [controller setAdHidden:YES];
}

- (void)setAdPosition:(CGPoint) point
{
    AdViewController * controller = [AdViewController sharedController];
    [controller setAdPosition:point];
}

- (void)showBannerLog
{
    _isShowLog = YES;
    AdViewController * controller = [AdViewController sharedController];
    [controller setModeTest:YES Log:YES];
}

/**
 插屏创建
 */
- (void)createInstl
{
    [[InterstitialObj sharedInterstitialObj] createInterstitial:_adView_Keys isManualRefresh:NO];
}

- (void)showInstl
{
    [[InterstitialObj sharedInterstitialObj] showInterstitial];
}

- (void)showInterlLog
{
    [[InterstitialObj sharedInterstitialObj] showLog];
}

#pragma AdViewDelegate

/*
 Return to advertising （rootViewController old code）
 */
- (UIViewController *)viewControllerForPresentingModalView{
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
    return result;
}

/**
 *  户是否要求输出 志,以前是和adViewTestMode同步的,现在可单独启  */
- (BOOL)adViewLogMode {
    return _isShowLog;
}


/**
 * 成功收到广告的回调方法。
 */
- (void)adViewDidReceiveAd:(AdViewView *)adViewView
{
    if(_isShowLog)NSLog(@"快有聚合广告条：加载成功");
}

/**
 * 实际请求失败的回调方法，这个方法主要是为了传递错误信息。
 * 注意紧跟着这个方法可能会回调adViewStartGetAd:表示切换到下一家，
 * 如果无法切换，则可能回调adViewDidFailToReceiveAd:usingBackup:方法。
 */
- (void)adViewFailRequestAd:(AdViewView *)adViewView error:(NSError*)error
{
    if(_isShowLog)NSLog(@"快有聚合广告条：请求失败%@",error);
}

/**
 * 失败并无法切换到有效平台的回调方法，不是实际的某次请求失败的回调。
 */
- (void)adViewDidFailToReceiveAd:(AdViewView *)adViewView usingBackup:(BOOL)yesOrNo
{
    if(_isShowLog)NSLog(@"快有聚合广告条：失败并无法切换");
}

/**
 * adView成功接受到config数据时会调用这个函数。
 */
- (void)adViewDidReceiveConfig:(AdViewView *)adViewView
{
    if(_isShowLog)NSLog(@"快有聚合广告条：接收到config数据");
}

@end
