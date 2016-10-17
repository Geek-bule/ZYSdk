//
//  toolsAN.h
//  OLStarYouth
//
//  Created by justin yang on 3/24/14.
//
//

#ifndef __OLStarYouth__toolsAN__
#define __OLStarYouth__toolsAN__

#include <iostream>
#include "cocos2d.h"


#define MOGOBANNER
#define MOGOINTERSTITIAL
#define MOGOSPLASH
#define SHARESDK
#define VIDEOSDK
#define GAMECENTER                //GameCenter开关
#define SHOPPING                  //内购开关





class toolsAN
{
public:
    static void toolsInit();
    
#ifdef GAMECENTER
    static void initGC();                                           //初始化gamecenter
    static void showGameCenter();
    static void updateScore(std::string identifier,int score);      //上传分数到排行榜
    static void getRank(std::string identifier);                    //获取排行榜上名次
    static void updateCallBack(int rank, float percent);            //获取排行榜上名次之后回调排名
#endif
#ifdef SHOPPING
    static void initIAP();                              //付费初始化部分
    static void loadIAPProducts(std::vector<std::string> productids,bool isLoad = true);
    static void orderWithId(int productid);    //通过id调用付费部分
    static void orderWithIdentifer(std::string identifier);    //通过id调用付费部分
    static void restoreProducts();      //恢复购买
    static void OrderSuccess(std::string identifier);   //付费成功回调
    static void RestoreSuccess(std::string identifier); //restore成功回调
#endif
    // HUD 和 Toast 的使用查看 ios/IosHelper 下的文件源码
    static void _createHUD(std::string msg, float delay,std::string outMsg);                            //loading 动画
    static void _dismissHUD();                           //结束 loading
#ifdef MOGOBANNER
    //admogo 广告
    static void initBanner();   //初始banner
    static void initBanner(const char* appId,cocos2d::Vec2 pos);
    static void ShowBannerView(const char* appId);                   //展示banner
    static void HideBannerView(const char* appId);                   //隐藏banner
    static void ReleaseBanner(const char* appId);   //释放banner
    static void setBannerView(const char* appId);
#endif
#ifdef MOGOINTERSTITIAL
    //admogo 插屏
    static int s_interstitalTimes;                  //
    static void ShowInterstitialWithTimes(bool isRate=true,int time =2);        //隔几次之后展示插屏
    static void initInterstitial();                 //初始interstitial
    static void loadInterstitial();                 //加载interstitial
    static void showInterstitial();                 //展示interstitial
#endif
#ifdef MOGOSPLASH
    //admogo 开屏
    static void showSplashads();
#endif
#ifdef SHARESDK
    //share sdk
    static void initShareSdk();                 //初始sharesdk
    static void shareWithMesg(std::string title,std::string msg, int award,cocos2d::Vec2 pt);//分享内容
    static void shareToWechat(std::string msg, int award);//只分享到朋友圈
#endif
#ifdef VIDEOSDK
    //video sdk
    static void initVideoSdk();             //初始化视频平台
    static void showVideo();                //轮着播放视屏平台
#endif
    static bool checkNewVersion();
    //判断路径下的文件是否存在（读写路径）
    static bool isFileExist(const char* pFileName, const char* strPath);
    static unsigned char* getFileData(const std::string& filename, const char* mode, ssize_t *size);
    //复制文件到读写路径下
    static void copyData(const char* pFileName, const char* pFilePath, const char* strPath);
};



#endif /* defined(__OLStarYouth__toolsAN__) */
