//
//  GeneralizeServer.h
//  MyPopo3
//
//  Created by JustinYang on 15/8/4.
//
//

#ifndef __MyPopo3__GeneralizeServer__
#define __MyPopo3__GeneralizeServer__

#include <stdio.h>
#include "cocos2d.h"
USING_NS_CC;
#include "network/HttpClient.h"
#include "cocos-ext.h"
USING_NS_CC_EXT;
using namespace network;
#include "json/document.h"
#include "json/writer.h"
#include "json/stringbuffer.h"
#include <iostream>
#include <errno.h>
#include "fstream"


//
// 记得修改appid，还有在appdelegate 的applicationWillEnterForeground 中添加激活游戏判断
//

#define GAME_COUNT              4               //推广游戏一次发送个数
#define DAY_APART               1               //间隔多久进行一次推广游戏获取
#define REWARD_GAME             0               //每个游戏被激活之后的奖励数
#define REMOVE_APART            30              //过期图片的过期时间

typedef int  PostId;                            //post消息的id
#define post_register           1
#define post_moregame           2
#define post_newgame            3
#define post_recommend          4
#define post_activation         5


typedef int  CodeId;                            //返回码code id
#define code_normal             0
#define code_fail               1               //response failed
#define code_code               2
#define code_error              3

struct tagMOREGAMEINFO
{
    int nGameId; //
    int nGameInfoId;
    std::string strSystem;
    std::string strLanguage;
    std::string strAppId;
    std::string strPackage;
    std::string strSchemes;
    std::string strDownloadUrl;
    std::string strGameName;
    std::string strIconPath;
    std::string strIconButton;
    std::string strImagePath;
    std::string strAdImage;
    std::string strAdImageOk;
    std::string strAdImageCancel;
    bool isExsited;
};

typedef std::map<std::string,tagMOREGAMEINFO> mapGameInfo;

struct tagACTIVATEINFO
{
    int nGameId;
    std::string strUdid;
    std::string strAppid;
    std::string strRecommendedAppid;
    int64_t nCreateTime;
    int nReward;
    std::string strName;
};


typedef std::vector<std::string> vecGameAppId;

class GeneralizeServer : public Node
{
public:
    static GeneralizeServer *getInstance();
    static GeneralizeServer* create(std::string appid);
    bool init(std::string appid);
    ~GeneralizeServer();
   
    //检查游戏激活情况
    void GameActivateCheck();//在appDelegate.cpp的AppDelegate::applicationDidEnterBackground() 函数中调用
    
    //游戏激活跳转
    void GameRecommed(const char* appid,int reward);
    
    //获取更多游戏信息
    tagMOREGAMEINFO* GetMoreGameInfo();
    
    //下载图片
    void SendDownloadMessage(std::string imagePath);
    
    //获取读写路径的图片
    SpriteFrame *GetSpriteFromWriteablePath(const char* name);
    
    //将图片数据转化成图片
    SpriteFrame *GetSpriteFrameFromData(const char* name,int len);
    
    //判断图片是否下载过了
    bool isImageExsit(std::string imagePath);
    
    //找到下载好的游戏
    tagMOREGAMEINFO isExsitedAdImage();
    
private:
    
    //发送手机和游戏的注册信息
    void SendRegisterRequest(const char* udid,const char* appid);
    void GetRegisterResponse(HttpClient *sender, HttpResponse *response);
    //获取4个推广游戏的信息
    void SendGameInfoRequest(const char* udid,const char* appid);
    void GetGameInfoResponse(HttpClient *sender, HttpResponse *response);
    //推荐游戏的跳转
    void SendRecommendRequest(const char* udid,const char* appid,const char* recommendid,int reward);
    void GetRecommendResponse(HttpClient *sender, HttpResponse *response);
    //激活成功与否的判断
    void SendActiveStateRequest(const char* udid,const char* appid);
    void GetActiveStateResponse(HttpClient *sender, HttpResponse *response);
    //对激活成功的发放奖励
    void SendExchangedRewardRequest(const char*udid,const char* appid,const char*recommendedAppid);
    void GetExchangedRewardResponse(HttpClient *sender, HttpResponse *response);
    //下载图片的响应
    void SendDownloadImageRequest(std::string &imagePath);
    void GetDownloadImageResponse(HttpClient *sender, HttpResponse *response);
    //下载进程
    void BeginDowndloadImage();
    //移除图片进程
    void BeginRemoveImage();
    //写入
    bool WriteGameInfo(rapidjson::Document &Doc);
    //读取
    bool ReadGameInfo(rapidjson::Document &Doc);
    //删除之前的图片数据
    void RemoveImageDir();
    //已经安装的游戏检测
    bool SchemesCheck(const char* schemes);
    
    void pushAdImagePath();
    

    //暂不用的
    bool ReadJson(std::string jsonStr,tagMOREGAMEINFO &info);
    //查看返回码
    int  CompareCode(const char* code);
    //消息进程列表
    void SendMessage();
    //通讯失败处理
    void FailMessageDeal(PostId post,CodeId code);
    //判断是否超过7天
    bool MoreGameDayCheck();
    bool removeImageDayCheck();
    //对比信息
    bool isDifferentInfo(tagMOREGAMEINFO line,tagMOREGAMEINFO local);
    
    
    //当前状态
    std::string m_strCurrentlanguage;
    std::string m_strCurrentSystem;
    std::string m_strIosIdfa;
    //执行进程列表
    std::vector<int> m_vecTheadList;
//    //更多游戏信息
//    std::vector<tagMOREGAMEINFO> m_vecMoreGameInfoList;
    //激活游戏信息
    std::vector<tagACTIVATEINFO> m_vecActivateInfoList;
    //需要下载的图片路径列表
    std::vector<std::string> m_vecImagePathList;
    //需要删除的图片路径
    std::vector<std::string> m_remvoeImagePathVec;
    //激活奖励的游戏信息
    std::string m_strAwardAppName;
    int m_nAwardAppCoins;
    
    
    
    //本地存储的所有游戏信息
    mapGameInfo m_MoreGameInfoMap;
    //目前要推广的游戏列表
    vecGameAppId m_GameAppIdVec;
    //保存的json内容
    std::string m_StrJson;
    //推荐数组的计数
    int m_Index;
    int m_nAdIndex;
    
    //将读取的json数据转化成数组
    void getVectorDataFormJson();
    //将数据的数据保存回json
    void saveJsonDataFormVector();
    //解析服务器获取的更多游戏信息
    void resolveReciveData();
    
private:
    std::string strAppid;
    
};

#endif /* defined(__MyPopo3__GeneralizeServer__) */
