//
//  ZYTools.hpp
//  sdkIOSDemo
//
//  Created by JustinYang on 16/9/30.
//
//

#ifndef ZYTools_hpp
#define ZYTools_hpp

#include "cocos2d.h"

//=================================================================
/**  
 SDK现分为3个部分
 1.ZYSDK    基础的sdk部分：功能包括（1）在线参数、（2）游戏互推、（3）更新提醒、（4）好评
 2.ADVIEW   广告sdk部分：快有聚合sdk（即adview）
 3.VIDEO    视频聚合sdk：

 extra 中是老版本sdk接入过的文件，如果不需要刻意移除，不是必需的。
 在sdkLibs中有对应的ZYExtra文件中有对应的sdk，也要记得移除。
*/
//=================================================================

#define ZYTOOLS_ZYSDK

#define ZYTOOLS_ADVIEW

#define ZYTOOLS_VIDEO


typedef std::function<void()> ccVideoCallback;
typedef std::function<void(bool)> ccStatusCallback;


class ZYTools
{
public:
    //2个初始化函数
    static void init();                 //在appController中初始化
    static void initAdSdk();            //最好在游戏资源加载成功之后调用或appDelegate中调用
    
    //获取在线参数值（在线参数为启动时获取一次然后缓存在本地）
    static std::string getParamOf(std::string key);
    
    //是否显示日志，在函数自行注释或取消注释
    static void showLog();
    
    //主动弹出评论（里面有是否可以弹出评论的判断）
    static void rateWithTip();
    
    //直接跳转评论页（里面有是否可以弹出评论的判断）
    static void rateWithUrl();
    
    //游戏互推设置显示或隐藏
    static void setAdGame(bool isShow);
    
    //游戏互推图标显示的位置
    static void setAdGamePos();
    
    //游戏互推的测试函数
    static void registerTest();
    
    //游戏提交审核之前像策划询问添加在什么位置
    static void reviewPort();
    
    //判断游戏是不是在审核状态
    static bool isReviewStatus();
    
    
    //==========ZYAdview sdk接入==========
#ifdef ZYTOOLS_ADVIEW
    //init adConfig
    static void initConfig();
    //init banner
    static void initBannerView();
    //showBanner                    （横幅）
    static void showBannerView();
    //hideBanner
    static void hideBannerView();
    
    //init interstitial
    static void initInterstitial();
    //show interstitial             （插屏）
    static void showInterstitial();
    
    //show splash                   （开屏）
    static void showSplash();
#endif
    
    static void startWxPay();
    static void queryWxpay();
    
    //==========ZYVideo sdk接入==========
#ifdef ZYTOOLS_VIDEO
    static bool _isHasVideoNow;
    static ccVideoCallback _videoPlayFinish;
    static std::vector<ccStatusCallback> _videoStatusVec;
    //init video
    static void initVideoSdk();
    //register
    static void setVideoStatus(const ccStatusCallback &isHasVide);
    //show video
    static void showVideo(const ccVideoCallback &videoPlayFinish);
#endif
    
};




#endif /* ZYTools_hpp */
