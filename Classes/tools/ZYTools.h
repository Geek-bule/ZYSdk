//
//  ZYTools.hpp
//  sdkIOSDemo
//
//  Created by JustinYang on 16/9/30.
//
//

#ifndef ZYTools_hpp
#define ZYTools_hpp


//=================================================================
/**  
 SDK现分为3个部分
 1.ZYSDK    基础的sdk部分：功能包括（1）在线参数、（2）游戏互推、（3）更新提醒、（4）好评
 2.ADVIEW   广告sdk部分：快有聚合sdk（即adview）
 3.VIDEO    视频聚合sdk：

*/
//=================================================================

#define ZYTOOLS_ZYSDK

#define ZYTOOLS_ADVIEW

#define ZYTOOLS_VIDEO


class ZYTools
{
public:
    //init
    static void init();
    static void initAdSdk();
    
    //open log
    static void showLog();
    
    //rate game
    static void rateWithTip();
    //rate game
    static void rateWithUrl();
    //show ad game
    static void setAdGame(bool isShow);
    //ad game pos
    static void setAdGamePos();
    //game review
    static void reviewPort();
    //is ap in review
    static bool isReviewStatus();
    
    
    //==========ZYAdview sdk接入==========
#ifdef ZYTOOLS_ADVIEW
    //init adConfig
    static void initConfig();
    //init banner
    static void initBannerView();
    //showBanner
    static void showBannerView();
    //hideBanner
    static void hideBannerView();
    
    //init interstitial
    static void initInterstitial();
    //show interstitial
    static void showInterstitial();
    
    //show splash
    static void showSplash();
#endif
    
    
    //==========ZYVideo sdk接入==========
#ifdef ZYTOOLS_VIDEO
    //init video
    static void initVideoSdk();
    //show video
    static void showVideo();
#endif
};




#endif /* ZYTools_hpp */
