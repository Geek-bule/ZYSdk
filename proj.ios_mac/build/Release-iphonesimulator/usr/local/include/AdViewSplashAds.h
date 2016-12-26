//
//  AdViewSplashAds.h
//  AdsMogoCocos2dxSample
//
//  Created by Chasel on 14-4-14.
//
//


#import "AdSpreadScreenManager.h"
#import "AdSpreadScreenManagerDelegate.h"
#import "AdViewConfigStore.h"


@interface SplashAdsObj :NSObject<AdSpreadScreenManagerDelegate>
{
    
}
@property (strong, nonatomic) AdSpreadScreenManager *splashAds;
@property (nonatomic, assign)BOOL isShowLog;

+ (SplashAdsObj *)sharedSplashAdsObj;

-(void)createSplashAds:(NSString*)mogoid;

-(void)showLog;

@end