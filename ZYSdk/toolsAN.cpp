//
//  toolsAN.cpp
//  OLStarYouth
//
//  Created by justin yang on 3/24/14.
//
//

#include "toolsAN.h"
#include "sdkConfig.h"
#include "tools.h"
#include "GameParam.hpp"
#include "GCHelper.h"
#include "IAPHelper.h"
#include "HelloWorldScene.h"
USING_NS_CC;

#include "ShareHelper.h"
#include "AdViewBanner.h"
#include "AdViewInterstitial.h"
#include "AdViewSplashAds.h"
#include "videoManager.h"
#include "AdViewToolX.h"
#include "IOSInfo.h"
#ifdef IOSAPDATE_UN
#include "AdsVideoInmob.h"

#endif

#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
#include <jni.h>
#include "platform/android/jni/JniHelper.h"
#include <android/log.h>

extern "C"

{
    void Java_com_zongyi_identifier_javaName_sam(JNIEnv*  env, jobject thiz)
    
    {
        CCLog("order sam start");
        toolsAN::sam();
        CCLog("order sam end");
    }
    void Java_com_zongyi_identifier_javaName_sample(JNIEnv*  env, jobject thiz, jstring text)
    
    {
        CCLog("order sample start");
        const char* pszText = env->GetStringUTFChars(text, NULL);
        toolsAN::sample(pszText);
        CCLog("order sample end");
        
        /* 安卓部分代码例子
         public static native void sample(String text);
         */
    }
}
#endif



void toolsAN::toolsInit()
{
#ifdef GAMECENTER
    toolsAN::initGC();
#endif
#ifdef SHOPPING
    toolsAN::initIAP();
#endif
    toolsAN::initShareSdk();
    toolsAN::initVideoSdk();
    toolsAN::initBanner();
//    toolsAN::HideBannerView();                          //隐藏banner条，如果不需要开始就隐藏记得讲它屏蔽
    toolsAN::initInterstitial();
}

#ifdef GAMECENTER

void toolsAN::initGC()
{
#ifdef IOSAPDATE
    InGCHelper::shareIAP()->initGC();
    InGCHelper::shareIAP()->setGCcallBack(updateCallBack);
#endif
}

void toolsAN::showGameCenter()
{
#ifdef IOSAPDATE
    InGCHelper::shareIAP()->showGameCenter();
#endif
}

void toolsAN::updateScore(std::string identifier, int score)
{
#ifdef IOSAPDATE
    InGCHelper::shareIAP()->updateGC(identifier, score);
#endif
}

void toolsAN::getRank(std::string identifier)
{
#ifdef IOSAPDATE
    InGCHelper::shareIAP()->getRank(identifier);
#endif
}

void toolsAN::updateCallBack(int rank, float percent)
{
    /**
     * @param rank :玩家当前的排名
     * @param percent :玩家排名百分比
     */
    
}

#endif
#ifdef SHOPPING

void LoadSuccess(std::vector<tagIAPINFO> identifier)
{
    cocos2d::MessageBox("在这个函数里面给玩家展示商品！！（如果不需要可以屏蔽）", "内购商品加载回调");
}

void toolsAN::initIAP()
{
#ifdef IOSAPDATE
    /**
     * 警告 一定要初始化所有计费id，
     */
    InIAPHelper::shareIAP()->initIAPId();
    InIAPHelper::shareIAP()->setOrderSuccess(OrderSuccess);
    InIAPHelper::shareIAP()->setRestoreSuccess(RestoreSuccess);
    InIAPHelper::shareIAP()->setLoadSuccess(LoadSuccess);
#endif
}
void toolsAN::loadIAPProducts(std::vector<std::string> productids,bool isLoad)
{
#ifdef IOSAPDATE
    InIAPHelper::shareIAP()->loadIAPProducts(productids,isLoad);
#endif
}

void toolsAN::orderWithId(int productid)
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    JniMethodInfo minfo;//定义Jni函数信息结构体
    bool isHave;
    isHave = JniHelper::getStaticMethodInfo(minfo,"com/zongyi/identifier/javaName","payCode", "(Ljava/lang/String;)V");
    
    jstring stringArg = t.env->NewStringUTF(identifier);
    if (!isHave) {
        CCLog("jni:payCode此函数不存在");
    }else{
        CCLog("jni:payCode此函数存在");
        //调用此函数
        minfo.env->CallStaticVoidMethod(minfo.classID, minfo.methodID, stringArg);
    }
    CCLog("jni-java函数执行完毕");
#endif
#ifdef IOSAPDATE
    InIAPHelper::shareIAP()->orderProduct(productid);
#endif
}

void toolsAN::orderWithIdentifer(std::string identifier)
{
#ifdef IOSAPDATE
    InIAPHelper::shareIAP()->orderIdentifier(identifier);
#endif
}

void toolsAN::restoreProducts()
{
#ifdef IOSAPDATE
    InIAPHelper::shareIAP()->restoreProducts();
#endif
}

void toolsAN::OrderSuccess(std::string identifier)
{
    //支付 identifier 成功回调
    cocos2d::MessageBox("在这个函数里面给玩家购买商品！！（如果不需要可以屏蔽）", "支付成功回调");
}

void toolsAN::RestoreSuccess(std::string identifier)
{
    //restore identifier 成功回调
    cocos2d::MessageBox("在这个函数里面给玩家恢复内购！！（如果不需要可以屏蔽）", "恢复内购成功回调");
}

#endif

void toolsAN::_createHUD(std::string msg, float delay, std::string outMsg)
{
#ifdef IOSAPDATE
    InIAPHelper::shareIAP()->createHUD(msg,delay,outMsg);
#endif
}

void toolsAN::_dismissHUD()
{
#ifdef IOSAPDATE
    InIAPHelper::shareIAP()->dismissHUD();
#endif
}

#ifdef MOGOBANNER


void toolsAN::initBanner(const char *appId, cocos2d::Vec2 pos)
{
    AdViewBanner::sharedBanner()->createBanner(appId, pos);
}

void toolsAN::initBanner()
{
    Vec2 pos = Vec2(AdViewToolX::AD_POS_CENTER, AdViewToolX::AD_POS_TOP);
    AdViewBanner::sharedBanner()->createBanner(ADVIEW_KEY, pos);
}

void toolsAN::ShowBannerView(const char* appId)
{
#ifdef IOSAPDATE
    AdViewBanner::sharedBanner()->showBanner(appId);
#endif
}

void toolsAN::HideBannerView(const char* appId)
{
#ifdef IOSAPDATE
    AdViewBanner::sharedBanner()->hidenBanner(appId);
#endif
}

void toolsAN::ReleaseBanner(const char* appId)
{
#ifdef IOSAPDATE
    AdViewBanner::sharedBanner()->releaseBanner(appId);
#endif
}

void toolsAN::setBannerView(const char *appId)
{
    AdViewBanner::sharedBanner()->setAdView(appId, AdViewToolX::AD_POS_TOP);
}


#endif
#ifdef MOGOINTERSTITIAL

int toolsAN::s_interstitalTimes = 0;

void toolsAN::initInterstitial()
{
#ifdef IOSAPDATE
    //如果游戏想自动刷新广告，请将第二个参数修改成false
    //第二个参数：是否手动刷新（注意：adview 广告有20分钟有效期）
    AdViewInterstitial::sharedInterstitial()->initInterstitial(ADVIEW_KEY,false);
#endif
}

void toolsAN::loadInterstitial()
{
#ifdef IOSAPDATE
    AdViewInterstitial::sharedInterstitial()->loadInterstitial();
#endif
}

void toolsAN::showInterstitial()
{
#ifdef IOSAPDATE
    AdViewInterstitial::sharedInterstitial()->showInterstitial();
#endif
}


void toolsAN::ShowInterstitialWithTimes(bool isRate,int time)
{
#ifdef IOSAPDATE
    s_interstitalTimes++;
    if (s_interstitalTimes == time) {
        s_interstitalTimes = 0;
        int rateCheck = GameParam::getInstance().getParamInt(UM_IRATE);
        if (!cocos2d::UserDefault::getInstance()->getBoolForKey(IRate_Store) && isRate && rateCheck) {
            tools::RateGameTip();
        }else{
            toolsAN::showInterstitial();
        }
    }
#endif
}

#endif
#ifdef MOGOSPLASH

void toolsAN::showSplashads()
{
#ifdef IOSAPDATE
    AdViewSplashAds::sharedInterstitial()->loadSplashAds(ADVIEW_KEY);
#endif
}
#endif
#ifdef SHARESDK

void shareSuccessReward(int award)
{
#ifdef IOSAPDATE
    cocos2d::MessageBox("在这个函数里面给玩家发放分享奖励！！（如果不需要可以屏蔽）", "分享成功回调");
#endif
}

void toolsAN::initShareSdk()
{
#ifdef IOSAPDATE
    ShareHelper::shareHelper()->init();
    ShareHelper::shareHelper()->initFunction(shareSuccessReward);
#endif
}

void toolsAN::shareWithMesg(std::string title, std::string msg, int award,cocos2d::Vec2 pt)
{
#ifdef IOSAPDATE
    //分享内容
    ShareHelper::shareHelper()->shareWithMsg(title.c_str(), msg.c_str(), award,pt);
#endif
}

void toolsAN::shareToWechat(std::string msg, int award)
{
#ifdef IOSAPDATE
    ShareHelper::shareHelper()->shareToWechat(msg.c_str(), award);
#endif
}


#endif

#ifdef VIDEOSDK

//控制按钮显示或隐藏
void videoBtnStatus(bool isVisible,int videoId)
{
#ifdef IOSAPDATE
    if (isVisible) {
        //控制所有视频按钮隐藏
        log("ToolAN视频ID:%d",videoId);
    }else{
        //控制所有视频按钮显示
        log("ToolAN视频ID:%d",videoId);
    }
    if (HelloWorld::getInstance()) {
        HelloWorld::getInstance()->videoBtnVisible(isVisible);
    }
#endif
}

void toolsAN::initVideoSdk()
{
#ifdef IOSAPDATE
    //视频初始化
    videoManager::getInstance().insertVideoID(KEY_JOYING_ID, Joying_ID);
    videoManager::getInstance().insertVideoID(KEY_JOYING_KEY, Joying_Key);
    videoManager::getInstance().insertVideoID(KEY_VUNGLE_ID, Vungle_ID);
    videoManager::getInstance().initVideoSdk(videoBtnStatus);
#endif
}

//视频播放完成回调
void videoPlayStatusSuccess(int videoId)
{
#ifdef IOSAPDATE
    MessageBox("在这个函数里面给玩家发放视频奖励！！（如果不需要可以屏蔽）", "视频播放成功回调");
#endif
}

void toolsAN::showVideo()
{
#ifdef IOSAPDATE
    //视频播放
    videoManager::getInstance().playVideo(videoPlayStatusSuccess);
#endif
}

#endif


//检验版本
bool toolsAN::checkNewVersion()
{
    std::string strFileName = "version";
    std::string strPath = "cookie/";
    std::string strVersion = IOSInfo::getBuild();
    if (isFileExist(strFileName.c_str(), strPath.c_str())) {
        std::string filePath = FileUtils::getInstance()->getWritablePath();
        filePath+=strPath;
        filePath+=strFileName;
        Data filedata = FileUtils::getInstance()->getDataFromFile(filePath);
        //json文件如果没有数据，就不处理
        if (filedata.getBytes() != NULL) {
            const char* lastVer = (const char*)filedata.getBytes();
            if (strcmp(lastVer, strVersion.c_str()) != 0) {
                std::ofstream outfile;
                outfile.open(filePath.c_str());
                if (outfile.fail())
                {
                    return false;
                }
                outfile << strVersion.c_str();
                outfile.close();
                return true;
            }
        }
    }else{
        std::string filePath = FileUtils::getInstance()->getWritablePath();
        filePath+=strPath;
        FileUtils::getInstance()->createDirectory(filePath);
        filePath+=strFileName;
        std::ofstream outfile;
        outfile.open(filePath.c_str());
        if (outfile.fail())
        {
            return false;
        }
        outfile << strVersion.c_str();
        outfile.close();
        return true;
    }
    return false;
}


//判断存在
bool toolsAN::isFileExist(const char* pFileName, const char* strPath)
{
    if(!pFileName)return false;
    std::string filePath = FileUtils::getInstance()->getWritablePath();
    filePath+=strPath;
    filePath+=pFileName;
    FILE *pFp = fopen(filePath.c_str(),"r");
    CCLOG("%s",filePath.c_str());
    if(pFp)
    {
        fclose(pFp);
        return true;
    }
    return false;
}

//测试
unsigned char* toolsAN::getFileData(const std::string& filename, const char* mode, ssize_t *size)
{
    unsigned char * buffer = nullptr;
    CCASSERT(!filename.empty() && size != nullptr && mode != nullptr, "Invalid parameters.");
    *size = 0;
    do
    {
        // read the file from hardware
        FILE *fp = fopen(filename.c_str(), mode);
        CC_BREAK_IF(!fp);
        
        fseek(fp,0,SEEK_END);
        *size = ftell(fp);
        fseek(fp,0,SEEK_SET);
        buffer = (unsigned char*)malloc(*size);
        *size = fread(buffer,sizeof(unsigned char), *size,fp);
        fclose(fp);
    } while (0);
    
    if (!buffer)
    {
        std::string msg = "Get data from file(";
        msg.append(filename).append(") failed!");
        
        CCLOG("%s", msg.c_str());
    }
    return buffer;
}

void toolsAN::copyData(const char *pFileName, const char *pFilePath, const char *pPath)
{
    
    CCLOG("DataBaseDebug: Copy %s to WriteablePath",pFileName);
    std::string strDataPath = pFilePath;
    std::string strPath = FileUtils::getInstance()->fullPathForFilename(strDataPath+pFileName);
    long len=0;
    unsigned char* data = NULL;
    data = getFileData(strPath.c_str(),"r",&len);
    
    std::string destPath = FileUtils::getInstance()->getWritablePath();
    destPath+= pPath;
    FileUtils::getInstance()->createDirectory(destPath);
    destPath+= pFileName;
    
    FILE *pFp=fopen(destPath.c_str(),"w+b");
    fwrite(data,sizeof(char),len,pFp);
    fclose(pFp);
    delete []data;
    data=NULL;
}






