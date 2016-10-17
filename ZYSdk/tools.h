//
//  tools.h
//  SpriteSheet
//
//  Created by JustinYang on 15/8/15.
//
//

#ifndef __SpriteSheet__tools__
#define __SpriteSheet__tools__

#include <stdio.h>
#include "cocos2d.h"


#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
/**
 ios控制器，iossdk使用时打开，更改文件为.mm
 android打包时屏蔽此句并修改文件格式.mm为.cpp
 */
#define IOSAPDATE
#endif

extern std::string statusPage;

class tools
{
public:
    //是不是审核版本
    static bool s_isReviewVersion;
    static void Init();                             //在AppDelegate.cpp中进行初始化
    static void InitKtplay();
    static bool IsIPad();                           //判断是不是ipad设备
    static bool IsNotAppReview();                   //版本标识，判断是不是审核版本

    //评论游戏
    static void RateGameUrl();                      //掉用此函数直接跳转appstore商店打开游戏链接
    static void RateGameTip();                      //弹出提示用户给评论，点击确定跳转appstore

    //ios toast 提示条
    static void Toast(std::string msg);
    
    //游戏内打开链接
    static void openUrlInApp(std::string url);
    static void openUrl(std::string url);
    static void OpenMoreGameList();
    static void openDeepLink();
    //保留的bug口
    static void uMengBug();
    
    //umeng 游戏统计接口
    static void uMengPayCoin(double cash, int source, double coin);
    static void uMengPayProps(double cash, int source, std::string item, int amount, double price);
    static void uMengBuyProps(std::string item, int amount, double price);
    static void uMengUseProps(std::string item, int amount, double price);
    static void uMengStartLevel(std::string level);
    static void uMengFinishLevel(std::string level);
    static void uMengFailLevel(std::string level);
    static void uMengBonusCoin(double coin, int source);
    static void uMengBonusPorps(std::string item, int amount, double price, int source);
    static void uMengUserLevel(int level);
    static void uMengPageInfo(std::string page);
    
    //本地推送的时间获取（时间为过了多少秒之后提醒）
    static int  getNotificateSecond();
    static bool getNotificateStatus();
    static void setNotificateStatus(bool isOpen);
    
    
    //删除视频存储文件，防止视频文件越来越多
    static void cleanVideoCache();//在appDelegate.cpp的AppDelegate::applicationDidEnterBackground() 函数中调用
    static void deleteLibraryCache(std::string path);
    static void deleteDocumentCache(std::string path);
    static float getPathSize(std::string filePath);
    //查看网络状态
    static int checkReachable();
    
    //额外部分
};

#endif /* defined(__SpriteSheet__tools__) */


