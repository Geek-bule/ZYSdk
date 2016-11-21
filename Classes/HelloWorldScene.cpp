#include "HelloWorldScene.h"
#include "cocostudio/CocoStudio.h"
#include "ui/CocosGUI.h"
#include "ZYTools.h"
//extra
#include "IAPHelper.h"
#include "ShareHelper.h"
#include "toolsKt.hpp"
#include "appleWatch.h"
#include "DDZServer.h"
USING_NS_CC;





using namespace cocostudio::timeline;

Scene* HelloWorld::createScene()
{
    // 'scene' is an autorelease object
    auto scene = Scene::create();
    
    // 'layer' is an autorelease object
    auto layer = HelloWorld::create();

    // add layer as a child to scene
    scene->addChild(layer);

    // return the scene
    return scene;
}

static HelloWorld *instance = nullptr;

HelloWorld *HelloWorld::getInstance()
{
    return instance;
}

// on "init" you need to initialize your instance
bool HelloWorld::init()
{
    //////////////////////////////
    // 1. super init first
    if ( !Layer::init() )
    {
        return false;
    }
    instance = this;
    
    LayerColor *pLayer=  LayerColor::create(Color4B(100,100,100,255));
    addChild(pLayer);
    //广告，分享，内购，gamecenter 初始化
    //一般在游戏加载资源之后进行sdk 的初始化，只要初始化一次
    ZYTools::initAdSdk();
    
    
    m_isShowBanner = false;
    m_isLoadIntertitial = false;
    m_isLoadIap = false;
    m_switchBanner = false;
    m_isAdCircle = false;
    m_isAdTriangle = false;
    
    //屏幕尺寸
    winSize = Director::getInstance()->getWinSize();
    
    // create menu, it's an autorelease object
    auto menu = Menu::create();
    menu->setPosition(Vec2::ZERO);
    this->addChild(menu, 1, enBtnMenu);
    
    /*不能展示的功能说明
     *1.
     *2.
     *3.
     *4.
     *5.
    */
    
    //rate
    auto pRateTip = MenuItemFont::create("Rate (游戏评论)", CC_CALLBACK_1(HelloWorld::rateGameCallback, this));
    pRateTip->setPosition(Vec2(winSize.width*0.5, winSize.height*0.9));
    menu->addChild(pRateTip);
    
    //UdidLogin
    auto pMoreGame = MenuItemFont::create("显示互推圆形按钮", CC_CALLBACK_1(HelloWorld::MoreGameCallback, this));
    pMoreGame->setPosition(Vec2(winSize.width*0.5, winSize.height*0.85));
    menu->addChild(pMoreGame,1,enBtnMoreGame);
    
    //moregame
    auto pMoreGame2 = MenuItemFont::create("显示互推三角按钮", CC_CALLBACK_1(HelloWorld::consumeHeartCallback, this));
    pMoreGame2->setPosition(Vec2(winSize.width*0.5, winSize.height*0.8));
    menu->addChild(pMoreGame2,1,enBtnMoreGame2);
    
    //SubmitStorage
    auto pSubmitStorage = MenuItemFont::create("显示互推大图", CC_CALLBACK_1(HelloWorld::submitStorageCallback, this));
    pSubmitStorage->setPosition(Vec2(winSize.width*0.5, winSize.height*0.75));
    menu->addChild(pSubmitStorage);
    
    auto pHideStorage = MenuItemFont::create("*测试*", CC_CALLBACK_1(HelloWorld::updateStorageCallback, this));
    pHideStorage->setPosition(Vec2(winSize.width*0.82, winSize.height*0.75));
    menu->addChild(pHideStorage);
    
    //Mogo Banner
    auto pMogoBanner = MenuItemFont::create("Banner（广告条）", CC_CALLBACK_1(HelloWorld::mogoBannerCallback, this));
    pMogoBanner->setPosition(Vec2(winSize.width*0.5, winSize.height*0.7));
    menu->addChild(pMogoBanner);
    
    //Mogo Interstitial
    auto pMogoInterstitial = MenuItemFont::create("Interstitial（显示插屏）", CC_CALLBACK_1(HelloWorld::mogoInterstitialCallback, this));
    pMogoInterstitial->setPosition(Vec2(winSize.width*0.5, winSize.height*0.65));
    menu->addChild(pMogoInterstitial,1,enBtnInter);
    
    //Video
    auto pVideo = MenuItemFont::create("Video Show（视频）（隐藏按钮）", CC_CALLBACK_1(HelloWorld::videoCallback, this));
    pVideo->setPosition(Vec2(winSize.width*0.5, winSize.height*0.6));
    menu->addChild(pVideo,1,enBtnVideo);
    pVideo->setEnabled(false);
    
    //视频加载成功的回调
    ZYTools::setVideoStatus(CC_CALLBACK_1(HelloWorld::videoBtnVisible, this));
    

    
    // ktplay firend list
    auto pFirendList = MenuItemFont::create("Extra 初始化", CC_CALLBACK_1(HelloWorld::friendsCallback, this));
    pFirendList->setPosition(Vec2(winSize.width*0.5, winSize.height*0.55));
    menu->addChild(pFirendList);
    
    //In App Purchase
    auto pIAP = MenuItemFont::create("In App Purchase（内购加载）", CC_CALLBACK_1(HelloWorld::iapCallback, this));
    pIAP->setPosition(Vec2(winSize.width*0.5, winSize.height*0.5));
    menu->addChild(pIAP,1,enBtnInApp);
    pIAP->setEnabled(false);
    
    //share sdk
    auto pShareTip = MenuItemFont::create("Share Sdk（分享）", CC_CALLBACK_1(HelloWorld::shareSdkCallback, this));
    pShareTip->setPosition(Vec2(winSize.width*0.5, winSize.height*0.45));
    menu->addChild(pShareTip,1,enBtnShare);
    pShareTip->setEnabled(false);
    
    // ktplay
    auto pVersionTip = MenuItemFont::create("KTPlay(游戏社区)", CC_CALLBACK_1(HelloWorld::ktplayCallback, this));
    pVersionTip->setPosition(Vec2(winSize.width*0.5, winSize.height*0.4));
    menu->addChild(pVersionTip,1,enBtnKTplay);
    pVersionTip->setEnabled(false);
    

    //apple watch
    auto pNotificate = MenuItemFont::create("watch（手表功能）", CC_CALLBACK_1(HelloWorld::notificateCallback, this));
    pNotificate->setPosition(Vec2(winSize.width*0.5, winSize.height*0.35));
    menu->addChild(pNotificate,1,enBtnWatch);
    pNotificate->setEnabled(false);
    
    
    // ktplaylogin
    auto pKTPlayLogin = MenuItemFont::create("支付订单(微信)", CC_CALLBACK_1(HelloWorld::ktLoginCallback, this));
    pKTPlayLogin->setPosition(Vec2(winSize.width*0.5, winSize.height*0.3));
    menu->addChild(pKTPlayLogin,1,enBtnWxPay);
    pKTPlayLogin->setEnabled(false);
    
//    // ktplaylogout
//    auto pKTPlayLogOut = MenuItemFont::create("查询订单(微信)", CC_CALLBACK_1(HelloWorld::ktLogoutCallback, this));
//    pKTPlayLogOut->setPosition(Vec2(winSize.width*0.5, winSize.height*0.25));
//    menu->addChild(pKTPlayLogOut);
    
    //GameCenter
    auto pGameCenter = MenuItemFont::create("设备记录清理", CC_CALLBACK_1(HelloWorld::gameCenterCallback, this));
    pGameCenter->setPosition(Vec2(winSize.width*0.5, winSize.height*0.25));
    menu->addChild(pGameCenter,1,enBtnDevice);
    pGameCenter->setEnabled(false);
    
    //SubmitStorage
//    auto pUpdateStorage = MenuItemFont::create("showAdGame（展示游戏广告）", CC_CALLBACK_1(HelloWorld::updateStorageCallback, this));
//    pUpdateStorage->setPosition(Vec2(winSize.width*0.5, winSize.height*0.25));
//    menu->addChild(pUpdateStorage);

    //UpdateHeart
//    auto pConsumeHeart = MenuItemFont::create("DeepLink(深度连接)", CC_CALLBACK_1(HelloWorld::consumeHeartCallback, this));
//    pConsumeHeart->setPosition(Vec2(winSize.width*0.5, winSize.height*0.2));
//    menu->addChild(pConsumeHeart);
//
//    //UpdateHeart
//    auto pAddHeart = MenuItemFont::create("AddHeart", CC_CALLBACK_1(HelloWorld::addHeartCallback, this));
//    pAddHeart->setPosition(Vec2(winSize.width*0.5, winSize.height*0.15));
//    menu->addChild(pAddHeart);
//    
//    //UpdateHeart
//    auto pAddHeartMax = MenuItemFont::create("AddHeartMax", CC_CALLBACK_1(HelloWorld::addHeartMaxCallback, this));
//    pAddHeartMax->setPosition(Vec2(winSize.width*0.5, winSize.height*0.1));
//    menu->addChild(pAddHeartMax);

    //推送自己的游戏
//    RecommendGame *layer = RecommendGame::create(winSize/5);
//    addChild(layer,111);
//    //设置大小
//    layer->setIconScale(0.54);
    
    
    std::string path = UserDefault::getInstance()->getXMLFilePath();
    log("xmlfilepath is %s",path.c_str());
    


    return true;
}

void HelloWorld::ktLoginCallback(cocos2d::Ref *pSender)
{
    ZYTools::startWxPay();
}

void HelloWorld::ktLogoutCallback(cocos2d::Ref *pSender)
{
    ZYTools::queryWxpay();
}

void HelloWorld::ktplayCallback(cocos2d::Ref *pSender)
{
    toolsKtPlay::getInstance().showKtPlayView();
}

void shareSdkCallBack(int award)
{
    //分享成功后的回调
    cocos2d::MessageBox("在这个函数里面给玩家购买商品！！（如果不需要可以屏蔽）", "支付成功回调");
}

void OrderSuccess(std::string identifier)
{
    //支付 identifier 成功回调
    cocos2d::MessageBox("在这个函数里面给玩家购买商品！！（如果不需要可以屏蔽）", "支付成功回调");
}

void RestoreSuccess(std::string identifier)
{
    //restore identifier 成功回调
    cocos2d::MessageBox("在这个函数里面给玩家恢复内购！！（如果不需要可以屏蔽）", "恢复内购成功回调");
}

void LoadSuccess(std::vector<tagIAPINFO> identifier)
{
    HelloWorld::getInstance()->iapLoadSuccess();
}

void HelloWorld::friendsCallback(cocos2d::Ref *pSender)
{
    auto pItem = (MenuItemFont*)pSender;
    pItem->setEnabled(false);
    
    //share sdk 初始化
    ShareHelper::shareHelper()->init();
    ShareHelper::shareHelper()->initFunction(shareSdkCallBack);
    auto pItemIAP = (MenuItemFont*)getChildByTag(enBtnMenu)->getChildByTag(enBtnInApp);
    pItemIAP->setEnabled(true);
    auto pItemDevice = (MenuItemFont*)getChildByTag(enBtnMenu)->getChildByTag(enBtnDevice);
    pItemDevice->setEnabled(true);
    
    //IAP 初始化
    InIAPHelper::shareIAP()->initIAPId();
    InIAPHelper::shareIAP()->setOrderSuccess(OrderSuccess);
    InIAPHelper::shareIAP()->setRestoreSuccess(RestoreSuccess);
    InIAPHelper::shareIAP()->setLoadSuccess(LoadSuccess);
    auto pItemShare = (MenuItemFont*)getChildByTag(enBtnMenu)->getChildByTag(enBtnShare);
    pItemShare->setEnabled(true);

    //ktplay 初始化
    toolsKtAccount::getInstance().setLoginStatus();
    toolsKtPlay::getInstance().setDidDispatchRewards();
    toolsKtPlay::getInstance().setActivityStatus();
    toolsKtPlay::getInstance().setKTAvailabilityStatus();
    auto pItemKT = (MenuItemFont*)getChildByTag(enBtnMenu)->getChildByTag(enBtnKTplay);
    pItemKT->setEnabled(true);
    
    //appleWatch 初始化
    appleWatchCpp::init();
    auto pItemWatch = (MenuItemFont*)getChildByTag(enBtnMenu)->getChildByTag(enBtnWatch);
    pItemWatch->setEnabled(true);
    
    //微信支付
    auto pItemWxPay = (MenuItemFont*)getChildByTag(enBtnMenu)->getChildByTag(enBtnWxPay);
    pItemWxPay->setEnabled(true);
    
    
    
}

void HelloWorld::rateGameCallback(cocos2d::Ref *pSender)
{
    ZYTools::rateWithTip();
}

void HelloWorld::shareSdkCallback(cocos2d::Ref *pSender)
{
    ShareHelper::shareHelper()->shareWithMsg("", "", 0, Vec2(0, 0));
}

void HelloWorld::mogoBannerCallback(cocos2d::Ref *pSender)
{
#ifdef ZYTOOLS_ADVIEW
    if (m_isShowBanner) {
        //显示banner
        ZYTools::showBannerView();
    }else{
        //隐藏banner
        ZYTools::hideBannerView();
    }
    m_isShowBanner = !m_isShowBanner;
#endif
}

void HelloWorld::mogoInterstitialCallback(cocos2d::Ref *pSender)
{
#ifdef ZYTOOLS_ADVIEW
    ZYTools::showInterstitial();
#endif
}

void HelloWorld::videoCallback(cocos2d::Ref *pSender)
{
#ifdef ZYTOOLS_VIDEO
    ZYTools::showVideo(CC_CALLBACK_0(HelloWorld::videoPlayFinish, this));
#endif
}

void HelloWorld::videoPlayFinish()
{
    MessageBox("视频播放成功", "");
}

void HelloWorld::gameCenterCallback(cocos2d::Ref *pSender)
{
    ShareHelper::shareHelper()->shareDeviceInfo();
}

void HelloWorld::iapCallback(cocos2d::Ref *pSender)
{
    if (!m_isLoadIap) {
        //先加载要进行内购的id
        std::vector<std::string> productids;
        productids.push_back(IAP_GOLD1);
        productids.push_back(IAP_GOLD2);
        InIAPHelper::shareIAP()->loadIAPProducts(productids,true);
    }else{
        //加载成功内购id后，根据id来进行购买
        InIAPHelper::shareIAP()->orderIdentifier(IAP_GOLD1);
    }
}

void HelloWorld::notificateCallback(cocos2d::Ref *pSender)
{
    appleWatchCpp::startWatch();
    //在手表段查看数据变化
    MessageBox("在手表段查看数据变化", "");
}

void HelloWorld::MoreGameCallback(cocos2d::Ref *pSender)
{
    auto pItem = (MenuItemFont*) getChildByTag(enBtnMenu)->getChildByTag(enBtnMoreGame);
    m_isAdCircle = !m_isAdCircle;
    if (m_isAdCircle) {
        pItem->setString("隐藏互推圆形按钮");
    }else{
        pItem->setString("显示互推圆形按钮");
    }
    ZYTools::setAdCircle(m_isAdCircle, Vec2(0.2, 0.8), 1.0);
}

void HelloWorld::consumeHeartCallback(cocos2d::Ref *pSender)
{
    auto pItem = (MenuItemFont*) getChildByTag(enBtnMenu)->getChildByTag(enBtnMoreGame2);
    m_isAdTriangle = !m_isAdTriangle;
    if (m_isAdTriangle) {
        pItem->setString("隐藏互推三角按钮");
    }else{
        pItem->setString("显示互推三角按钮");
    }
    ZYTools::setAdTriangle(m_isAdTriangle, 1.0);
}

void HelloWorld::submitStorageCallback(cocos2d::Ref *pSender)
{
    ZYTools::showBigPic();
}

void HelloWorld::updateStorageCallback(cocos2d::Ref *pSender)
{
    ZYTools::registerTest();
}

void HelloWorld::addHeartCallback(cocos2d::Ref *pSender)
{
    
}

void HelloWorld::addHeartMaxCallback(cocos2d::Ref *pSender)
{
//    NSString *testString = @"http://www.zongyiplay.com/zywallpapper/images/category/c6b934d195964e94b7bf15c84c0e5922.jpg";
//    
//    NSString* testKey = @"key1233215678987";
//    NSLog(@"testString:%@",testString);
//    
//    NSData* testData = [testString dataUsingEncoding:NSUTF8StringEncoding];
//    NSLog(@"testData:%@",testData);
//    
//    NSData* data = [CATSecurity aes256EncryptWithData:testData key:testKey];
//    NSLog(@"aes256EncryptWithData:key:%@",data);
//    //将加密好的data base64编码后传给java
//    NSString* base64EncodedString = [CATSecurity base64EncodedStringWithData:data];
//    NSLog(@"base64EncodedStringWithData:%@",base64EncodedString);
//    
//    data = [CATSecurity aes256DecryptWithData:data key:testKey];
//    NSLog(@"aes256DecryptWithData:key:%@",data);
//    
//    data = [CATSecurity aes256EncryptWithString:testString key:testKey];
//    NSLog(@"aes256EncryptWithString:key:%@",data);
//    //将加密好的data base64编码后传给java
//    
//    base64EncodedString = [CATSecurity base64EncodedStringWithData:data];
//    NSLog(@"base64EncodedStringWithData:%@",base64EncodedString);
//    
//    //服务器端传过来加密字符串 base64EncodedString
//    base64EncodedString = @"f6yeU+cqNQjuDJvUwPy05C9cssvDvRzUWUxQwaKB+HamkzA7jeMmWfBBKDtxKg2yup5kHwf3wT+UkW7va6s1iw7KwaloeHEkCBVFXn13kh53EKzkihSUlwu4W0OPVvOL";
//    //解密
//    NSData* decryptData = [CATSecurity dataWithBase64EncodedString:base64EncodedString];
//    
//    NSString* str = [CATSecurity aes256DecryptStringWithData:decryptData key:testKey];
//    NSLog(@"解密出来的字符串:%@",str);
}


void HelloWorld::videoBtnVisible(bool isVisible)
{
    auto pItem = (MenuItemFont*) getChildByTag(enBtnMenu)->getChildByTag(enBtnVideo);
    if (isVisible) {
        pItem->setString("Video Show（视频）(显示按钮)");
    }else{
        pItem->setString("Video Show（视频）（隐藏按钮）");
    }
    
    pItem->setEnabled(isVisible);
}

void HelloWorld::iapLoadSuccess()
{
    auto pItem = (MenuItemFont*)getChildByTag(enBtnMenu)->getChildByTag(enBtnInApp);
    pItem->setString("In App Purchase（内购使用）");
    m_isLoadIap = true;
}

