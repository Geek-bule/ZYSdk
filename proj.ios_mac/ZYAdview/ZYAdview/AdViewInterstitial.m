 //
//  AdViewInterstitial.cpp
//  AdsMogoCocos2dxSample
//
//  Created by Castiel on 2015-3-26
//
//

#import "AdViewInterstitial.h"



@implementation InterstitialObj

+ (InterstitialObj *)sharedInterstitialObj {
    static InterstitialObj *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

-(AdInstlManager*)createInterstitial:(NSString*)mogoid isManualRefresh:(BOOL) ismanualrefresh{
    if (self.interstitial) {
        self.interstitial.delegate = nil;
        self.interstitial = nil;
    }
    m_ismanualrefresh = !ismanualrefresh;
    //常规初始化
    self.interstitial= [AdInstlManager managerWithAdInstlKey:mogoid WithDelegate:self];

    if (m_ismanualrefresh) {
        [self loadInterstitial];
    }
    
    _isShowLog= NO;
    
    return self.interstitial;
}


-(void)loadInterstitial{
    if (self.interstitial) {
        [self.interstitial loadAdInstlView:[self viewControllerView]];
    }
}


-(BOOL)showInter{
    if (self.interstitial.isReady) {
        BOOL bRet = [self.interstitial showAdInstlView:[self viewControllerView]];
        if (!bRet) {
            if(_isShowLog)NSLog(@"快有聚合插屏：展示失败");
            return NO;
        }else{
            return YES;
        }
    }else{
        if (m_ismanualrefresh) {
            if(_isShowLog)NSLog(@"快有聚合插屏自动刷新：自动加载广告");
            [self loadInterstitial];
        }
    }
    return NO;
}


- (void)showInterstitial
{
    [[InterstitialObj sharedInterstitialObj] showInter];
}


-(void)showLog{
    _isShowLog = YES;
}


#pragma mark  -AdMoGoInterstitialDelegate
/*
 Return to advertising （rootViewController old code）
 */
- (UIViewController *)viewControllerView{
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


-(void)adInstlManager:(AdInstlManager*)manager didGetEvent: (InstlEventType)eType error:(NSError*)error
{
    switch (eType) {
        case InstlEventType_DidLoadAd:
            if(_isShowLog)NSLog(@"快有聚合插屏：加载成功");
            break;
        case InstlEventType_FailLoadAd:
            if(_isShowLog)NSLog(@"快有聚合插屏：加载失败%@",error);
            break;
        case InstlEventType_DidShowAd:
            if(_isShowLog)NSLog(@"快有聚合插屏：展示成功");
            break;
        case InstlEventType_DidClickAd:
            if(_isShowLog)NSLog(@"快有聚合插屏：点击成功");
            break;
        case InstlEventType_WillPresentAd:
            if (m_ismanualrefresh) {
                [self loadInterstitial];
                if(_isShowLog)NSLog(@"快有聚合插屏自动刷新：自动加载广告");
            }
            break;
        case InstlEventType_DidDismissAd:
        case InstlEventType_WillPresentModal:    //like inline browser view
        case InstlEventType_DidDismissModal:
        default:
        break;
    }
}
- (BOOL)adInstlTestMode {
    return NO;
}
- (BOOL)adInstlLogMode {
    return _isShowLog;
}


@end

