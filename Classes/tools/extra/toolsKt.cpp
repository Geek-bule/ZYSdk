//
//  toolsKtAccount.cpp
//  SDKDemo
//
//  Created by JustinYang on 16/4/1.
//
//

#include "toolsKt.hpp"


#define ISKTPLAY          //ktplay 功能开启控制器



#ifdef ISKTPLAY
#include "KTPlayC.h"
#include "KTUserC.h"
#include "KTAccountManagerC.h"
#include "KTFriendshipC.h"
#include "KTLeaderboardC.h"

#endif


//==================================================================
//=====================toolsKtCheck ================================
//==================================================================


void toolsKtCheck::createHud(float dt, std::string strTimeOut)
{
    
}

void toolsKtCheck::disMissHud()
{
    
}



//==================================================================
//=====================toolsKtAccount===============================
//==================================================================
#ifdef ISKTPLAY
//调用KTAccountManager的showLoginView方法可以打开独立登录窗口，通过监听登录回调(成功/失败)可进行后续流程。
static void showLoginViewCallback(bool isSuccess ,KTUserC * user,KTErrorC *error)
{
    if (isSuccess) {
        //登录成功（如果之前没登录过，执行与服务器交互，然后上传游戏记录对比）
        
    } else {
        //登录失败
    }
}
#endif

void toolsKtAccount::showLogiView()
{
    #ifdef ISKTPLAY
    KTAccountManagerC::showLoginView(true, showLoginViewCallback);
#endif
}
#ifdef ISKTPLAY
//调用KTAccountManager类的setNickname方法修改昵称
static void setNickNameCallBack(bool isSuccess ,const char * nickName,KTUserC * user, KTErrorC *error)
{
    if (isSuccess) {
        //  user  是当前用户信息
    } else {
        // error 详细错误信息
    }
}
#endif
void toolsKtAccount::setNickName(const char *strName)
{
    #ifdef ISKTPLAY
    KTAccountManagerC::setNickName(strName, setNickNameCallBack);
#endif
}

void toolsKtAccount::logOutGame()
{
    #ifdef ISKTPLAY
    //调用KTAccountManager的logout方法登出账号
    KTAccountManagerC::logout();
#endif
}
#ifdef ISKTPLAY
//创建回调 KTplay账号的登录状态变更后游戏需要做相应的处理(如刷新界面)。
void loginStatusChangedCallback(bool isLoggedIn, KTUserC * user)
{
    if(isLoggedIn) {
        //登录
    } else {
        
    }
}
#endif
void toolsKtAccount::setLoginStatus()
{
    #ifdef ISKTPLAY
    KTAccountManagerC::setLoginStatusChangedCallback(loginStatusChangedCallback);
#endif
}


bool toolsKtAccount::getLoggedInStatus()
{
    #ifdef ISKTPLAY
    //游戏需要根据KTplay的登录状态设计后续流程，例如：若用户未登录弹出登录窗口，否则直接进入游戏。
    bool isLoggedIn = KTAccountManagerC::isLoggedIn();
    return isLoggedIn;
#endif
}

ZYUserInfo toolsKtAccount::getSelfInfo()
{
    #ifdef ISKTPLAY
    //调用KTAccountManager的currentAccount方法获取当前登录账号信息
    KTUserC *userC = KTAccountManagerC::currentAccount();
    ZYUserInfo info;
    info.userId = userC->userId;
    info.headerUrl = userC->headerUrl;
    info.nickname = userC->nickname;
    return info;
#endif
}
#ifdef ISKTPLAY
//调用KTAccountManager的userProfile方法可获取KTplay用户信息
static void userProfileCallback(bool isSuccess ,const char *userId ,KTUserC * user,KTErrorC *error)
{
    if (isSuccess) {
        // 操作成功 user即玩家信息
    } else {
        //操作失败
    }
}
#endif
void toolsKtAccount::getUserProfile(ZYUserID userID)
{
    #ifdef ISKTPLAY
    KTAccountManagerC::userProfile(userID.c_str() ,userProfileCallback);
#endif
}


//==================================================================
//=====================toolsKtFriendship============================
//==================================================================


void toolsKtFriendship::showFriendshipView()
{
    #ifdef ISKTPLAY
    //调用KTFriendship类的showFriendRequestsView方法打开添加好友窗口。
    KTFriendshipC::showFriendRequestsView();
#endif
}
#ifdef ISKTPLAY
//调用KTFriendship类的friendList获取好友列表数据。
static void friendListCallback(bool isSuccess,KTUserC * userArray,int userArrayCount,KTErrorC *error)
{
    if (isSuccess) {
        //操作成功 userArray  获取的好友数组
        //同步还有列表
    } else {
        //操作失败
    }
}
#endif


void toolsKtFriendship::getFriendshipList()
{
    #ifdef ISKTPLAY
    KTFriendshipC::friendList(friendListCallback);
#endif
}
#ifdef ISKTPLAY
//调用KTFriendship类的sendFriendRequests发送添加好友请求。
static void friendRequestCallback(bool isSuccess, int successCount, KTErrorC *error)
{
    if (isSuccess) {
        //操作成功  successCount，返回成功邀请的好友个数。
        
    } else {
        //操作失败
    }
}
#endif

void toolsKtFriendship::addFriendToList()
{
    #ifdef ISKTPLAY
    char *p[] = {"123", "245"};
    KTFriendshipC::sendFriendRequests(p,2,friendRequestCallback);
#endif
}


//==================================================================
//=====================toolsKtPlay==================================
//==================================================================

//调用KTPlay的show方法显示社区
void toolsKtPlay::showKtPlayView()
{
    #ifdef ISKTPLAY
    KTPlayC::show();
#endif
}

void toolsKtPlay::hideKtPlayView()
{
    #ifdef ISKTPLAY
    KTPlayC::dismiss();
    #endif
}

//KTPlay状态是否可用
void availabilityChangedCallback(bool isEnabled)
{
    toolsKtCheck::getInstance().setAvailability(isEnabled);
}

void toolsKtPlay::setKTAvailabilityStatus()
{
    #ifdef ISKTPLAY
    KTPlayC::setAvailabilityChangedCallback(availabilityChangedCallback);
    #endif
}

//监听社区状态变更接口可实现上述功能。
void activityStatusChanged(bool hasNewActivities) {
    //在这里添加玩家有新新消息时候的界面状态
    toolsKtCheck::getInstance().setActivity(hasNewActivities);
}

void toolsKtPlay::setActivityStatus()
{
    #ifdef ISKTPLAY
    KTPlayC::setActivityStatusChangedCallback(activityStatusChanged);
    #endif
}

//快速发布游戏截屏到社区
void toolsKtPlay::shareScreenshot()
{
    #ifdef ISKTPLAY
    KTPlayC::shareScreenshotToKT("大家来看看图片哈～～～");
    #endif
}

//快速发布图片到社区
void toolsKtPlay::shareImageToKT(const char *imagePath)
{
    #ifdef ISKTPLAY
    KTPlayC::shareImageToKT(imagePath , "大家来看看图片哈～～～");
    #endif
}
#ifdef ISKTPLAY
//玩家在SDK中触发领奖操作时，SDK会将奖励的数据回调给游戏，游戏根据奖励数据发放奖励给玩家。
void dispatchRewards (KTRewardItemC * item, int length){
    for ( int i = 0; i < length; i ++) {
        if (strcmp(item->typeId,"coin") == 0 ) {
            //对应ktplay后台的id给玩家发放奖励
            
        }
    }
}
#endif

void toolsKtPlay::setDidDispatchRewards()
{
    #ifdef ISKTPLAY
    KTPlayC::setDidDispatchRewardsCallback( dispatchRewards );
    #endif
}

//调用KTPlay的showRedemptionView方法显示兑换码窗口
void toolsKtPlay::showRedemptionView()
{
    #ifdef ISKTPLAY
    KTPlayC::showRedemptionView();
    #endif
}
#ifdef ISKTPLAY
//上传玩家分数需要玩家先登录到KTplay
static void reportScoreCallback(bool isSuccess,const char *leaderboardId,long long score,const char * scoreTag,KTErrorC *error)
{
    if (isSuccess) {
        //操作成功，
    } else {
        //操作失败。leaderboardId ，score 为请求信息
    }
}
#endif

void toolsKtPlay::reportScore(const char *leaderboardId, long long score)
{
    #ifdef ISKTPLAY
    //上传分数
    KTLeaderboardC::reportScore(score, leaderboardId, "scoreTag", reportScoreCallback);
    #endif
}
#ifdef ISKTPLAY
//需要玩家先登录到KTplay
static void friendLeaderboardCallback(bool isSuccess,const char *leaderboardId ,KTLeaderboardPaginatorC *leaderboard,KTErrorC *error)
{
    if (isSuccess) {
        //操作成功(需要根据leaderboardid判断)
        for (int i = 0;i<leaderboard->itemCount;i++) {
            KTUserC user = leaderboard->itemsArray[i];
        }
    } else {
        //操作失败
    }
}
#endif

void toolsKtPlay::getFriendsLeaderboard(const char *leaderboardId,int startIndex,int count)
{
    #ifdef ISKTPLAY
    //获取好友排行榜数据
    KTLeaderboardC::friendsLeaderboard(leaderboardId, startIndex, count, friendLeaderboardCallback);
#endif
}

