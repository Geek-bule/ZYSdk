//
//  AdViewInterstitial.h
//  AdsMogoCocos2dxSample
//
//  Created by Chasel on 14-4-14.
//
//


#import "AdInstlManager.h"
#import "AdInstlManagerDelegate.h"
#import "AdViewConfigStore.h"


@interface InterstitialObj :NSObject<AdInstlManagerDelegate>
{
    BOOL m_ismanualrefresh;
}
@property (nonatomic, strong) AdInstlManager * interstitial;
@property (nonatomic, assign)BOOL isShowLog;

+ (InterstitialObj *)sharedInterstitialObj;
-(AdInstlManager*)createInterstitial:(NSString*)mogoid isManualRefresh:(BOOL) ismanualrefresh;
-(void)loadInterstitial;
-(void)showInterstitial;
-(void)showLog;

@end

