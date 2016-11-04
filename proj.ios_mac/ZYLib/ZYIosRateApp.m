//
//  IosRateApp.m
//  sdkIOSDemo
//
//  Created by JustinYang on 16/8/24.
//
//

#import "ZYIosRateApp.h"
#import <UIKit/UIKit.h>
#import "ZYParamOnline.h"


#define ZYRATE_APP          @"zongyirate"


@interface ZYIosRateApp()
{
    //对于跳转之后的计时，达到10秒的才算做玩家评论了
    long        m_timeCheck;
    rateBack    m_rateCall;
}
@property (retain) NSString *strAppID;
@property(nonatomic)BOOL isShowLog;
@end



@implementation ZYIosRateApp

+ (ZYIosRateApp*)shareRate
{
    static ZYIosRateApp* s_share = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_share = [[ZYIosRateApp alloc] init];
    });
    return s_share;
}


- (id)init{
    self = [super init];
    if (self) {
        //时间判断
        m_timeCheck = 0;
        _isShowLog = NO;
        self.strAppID = [[ZYParamOnline shareParam] getConfigValueFromKey:@"app_id"];
        //设置回调
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(rateTimeCheck)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
    return  self;
}


- (BOOL)isCanRateApp
{
    NSString *curVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *saveVersion = [[NSUserDefaults standardUserDefaults] objectForKey:ZYRATE_APP];
    NSString* rate = [[ZYParamOnline shareParam] getParamOf:@"ZYIrate"];
    if (![curVersion isEqualToString:saveVersion] && rate.intValue == 1) {
        return YES;
    }
    if(_isShowLog)NSLog(@"评论：当前版本-%@,上次评论版本-%@,在线参数rate-%@",curVersion,saveVersion,rate);
    return NO;
}


- (void)RateWithUrlAndBlock:(rateBack)rateCall
{
    m_rateCall = rateCall;
    
    NSURL *url= [NSURL URLWithString:[self appRatePage]];
    [[UIApplication sharedApplication] openURL:url];
    
    m_timeCheck = [[NSDate date] timeIntervalSince1970];
}

- (void)RateWithTipAndBlock:(rateBack)rateCall
{
    m_rateCall = rateCall;
    NSString* hide = [[ZYParamOnline shareParam] getParamOf:@"ZYRateHide"];
    if (hide.intValue == 1) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:nil
                                                     message:NSLocalizedString(@"rate hide", nil)
                                                    delegate:self       //委托给Self，才会执行上面的调用
                                           cancelButtonTitle:nil
                                           otherButtonTitles:NSLocalizedString(@"i know", nil),
                           NSLocalizedString(@"i rate", nil),nil];
        [av show];
    }else{
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:nil
                                                     message:NSLocalizedString(@"rate tip", nil)
                                                    delegate:self       //委托给Self，才会执行上面的调用
                                           cancelButtonTitle:nil
                                           otherButtonTitles:NSLocalizedString(@"i know", nil),
                           NSLocalizedString(@"i rate", nil),nil];
        [av show];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1)
    {
        NSURL *url= [NSURL URLWithString:[self appRatePage]];
        [[UIApplication sharedApplication] openURL:url];
        
        m_timeCheck = [[NSDate date] timeIntervalSince1970];
    }
    if (buttonIndex == 0) {
        
    }
}

//进行时间检测，大于10才算评论
- (void)rateTimeCheck
{
    double dtime = [[NSDate date] timeIntervalSince1970] - m_timeCheck;
    if (dtime > 10 && m_timeCheck != 0) {
        m_timeCheck = 0;
        [self showGetStar];
    }else{
        m_timeCheck = 0;
    }
}

//给玩家评论奖励并提示玩家
- (void)showGetStar
{
    //评论成功，存值
    NSString *curVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *saveVersion = [[NSUserDefaults standardUserDefaults] objectForKey:ZYRATE_APP];
    if ([curVersion isEqualToString:saveVersion]) {
        //说明已经评论过了
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:nil
                                                     message:@"您已经领取过评论奖励了，不能再次领取奖励"
                                                    delegate:self       //委托给Self，才会执行上面的调用
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
        [av show];
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //保存评论
        [[NSUserDefaults standardUserDefaults] setObject:curVersion forKey:ZYRATE_APP];
    });
    
    NSString* hide = [[ZYParamOnline shareParam] getParamOf:@"ZYRateHide"];
    if (hide.intValue == 1) {
        return;
    }
    
    if (m_rateCall){
        m_rateCall();
    }
}


- (NSString*)appRatePage
{
    if (!self.strAppID) {
        NSLog(@"好评Error:填写appConfig.plist 属性，并引入工程");
        return @"";
    }
    if ( [[UIDevice currentDevice].systemVersion floatValue] < 7.0 ) {
        return [NSString stringWithFormat:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@",self.strAppID];
    }else{
        return [NSString stringWithFormat:@"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=%@&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8",self.strAppID];
    }
}


- (void)showLog
{
    _isShowLog = YES;
}

@end
