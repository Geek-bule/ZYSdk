//
//  toolsKt.hpp
//  SDKDemo
//
//  Created by JustinYang on 16/4/1.
//
//

#ifndef toolsKt_hpp
#define toolsKt_hpp

#include <stdio.h>
#include "cocos2d.h"

typedef std::string ZYUserID;

struct ZYUserInfo
{
    ///KT用户唯一标识符
    ZYUserID userId;
    
    ///KT用户头像Url，如果想要获取头像缩率图请再url后面追加支持的缩率图大小。
    ///支持大小列表：_32x32,_50x50,_64x64,_80x80,_120x120,_128x128,_200x200,_256x256
    const char *headerUrl;
    
    ///KT用户昵称
    const char *nickname;
    
    ///性别  0:未知;1:男;2:女
    int gender;
};

//
//// ktplay 检测
//

class toolsKtCheck
{
public:
    static toolsKtCheck &getInstance() {
        static toolsKtCheck instance;
        return instance;
    }
    toolsKtCheck(){m_activity =false;m_availability=false;}
    
    void createHud(float dt, std::string strTimeOut);
    void disMissHud();
    
    /**KTPlay是否可用*/
    CC_SYNTHESIZE(bool, m_availability, Availability);
    /**是否有新消息*/
    CC_SYNTHESIZE(bool, m_activity, Activity);
};

//
//// 账号系统
//

class toolsKtAccount
{
public:
    static toolsKtAccount &getInstance() {
        static toolsKtAccount instance;
        return instance;
    }
    //显示登录窗口
    void showLogiView();
    //修改玩家姓名
    void setNickName(const char* strName);
    //游戏登出
    void logOutGame();
    //获取玩家目前的登录状态
    bool getLoggedInStatus();
    //获取某个玩家的信息
    void getUserProfile(ZYUserID userId);
    //获取自己游戏信息
    ZYUserInfo getSelfInfo();
public:
    //监控玩家目前状态
    void setLoginStatus();
    
private:
};

//
//// 好友系统
//

class toolsKtFriendship
{
public:
    static toolsKtFriendship &getInstance()
    {
        static toolsKtFriendship instance;
        return instance;
    }
    //显示好友列表
    void showFriendshipView();
    //获取还有列表
    void getFriendshipList();
    //添加好友
    void addFriendToList();
};

//
//// 社区功能
//

class toolsKtPlay
{
public:
    static toolsKtPlay &getInstance()
    {
        static toolsKtPlay instance;
        return instance;
    }
    //显示社区界面
    void showKtPlayView();
    //关闭社区界面
    void hideKtPlayView();
    //上传截图到社区
    void shareScreenshot();
    //上传图片到社区
    void shareImageToKT(const char *imagePath);
    //显示兑换码窗口
    void showRedemptionView();
    //上传玩家数据
    void reportScore(const char *leaderboardId,long long score);
    //获取好友排行数据
    void getFriendsLeaderboard(const char *leaderboardId,int startIndex,int count);
    
public:
    //监听ktplay是否可用
    void setKTAvailabilityStatus();
    //监视消息动态
    void setActivityStatus();
    //设置奖励
    void setDidDispatchRewards();
};

#endif /* toolsKt_hpp */
