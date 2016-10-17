//
//  AdGameShow.cpp
//  sdkIOSDemo
//
//  Created by JustinYang on 16/8/19.
//
//

#include "AdGameShow.h"
#include "IOSinfo.h"
#include "GameParam.hpp"

ADGameShow::~ADGameShow()
{
    
}

bool ADGameShow::init()
{
    if (!Layer::init()) {
        return false;
    }
    
    LayerColor *pLayer = LayerColor::create(Color4B(0, 0, 0, 150));
    pLayer->setPosition(0,0);
    addChild(pLayer);
    
    // Register Touch Event
    auto listener = EventListenerTouchOneByOne::create();
    listener->setSwallowTouches(true);
    
    listener->onTouchBegan = CC_CALLBACK_2(ADGameShow::onTouchBegan, this);
    listener->onTouchMoved = CC_CALLBACK_2(ADGameShow::onTouchMoved, this);
    listener->onTouchEnded = CC_CALLBACK_2(ADGameShow::onTouchEnded, this);
    
    _eventDispatcher->addEventListenerWithSceneGraphPriority(listener, this);
    
    m_menu = CCMenu::create();
    m_menu->setPosition(0,0);
    addChild(m_menu);
    
    return true;
}



void ADGameShow::ShowAdGame(tagMOREGAMEINFO &adInfo)
{
    CCSize winSize = Director::getInstance()->getWinSize();
    log("%s \n %s \n  %s",adInfo.strAdImage.c_str(),adInfo.strAdImageOk.c_str(),adInfo.strAdImageCancel.c_str());
    //随机展示一个游戏的信息
    SpriteFrame *pButtonFrame1 = GeneralizeServer::getInstance()->GetSpriteFromWriteablePath(adInfo.strAdImage.c_str());
    CCSprite *iconButton1 = CCSprite::createWithSpriteFrame(pButtonFrame1);
    CCSprite *iconButton2 = CCSprite::createWithSpriteFrame(pButtonFrame1);
    auto pImageBg = CCMenuItemSprite::create(iconButton1, iconButton2, this, menu_selector(ADGameShow::openHandle));
    pImageBg->setPosition(winSize/2);
    m_menu->addChild(pImageBg,1);
    
    
    SpriteFrame *pButtonFrame2 = GeneralizeServer::getInstance()->GetSpriteFromWriteablePath(adInfo.strAdImageOk.c_str());
    CCSprite *iconButton3 = CCSprite::createWithSpriteFrame(pButtonFrame2);
    CCSprite *iconButton4 = CCSprite::createWithSpriteFrame(pButtonFrame2);
    iconButton4->setScale(0.95);
    auto pImageOk = CCMenuItemSprite::create(iconButton3, iconButton4, this, menu_selector(ADGameShow::openHandle));
    pImageOk->setPosition(Vec2(winSize.width*0.5-100,winSize.height*0.5-100));
    m_menu->addChild(pImageOk,2);

    
    SpriteFrame *pButtonFrame3 = GeneralizeServer::getInstance()->GetSpriteFromWriteablePath(adInfo.strAdImageCancel.c_str());
    CCSprite *iconButton5 = CCSprite::createWithSpriteFrame(pButtonFrame3);
    CCSprite *iconButton6 = CCSprite::createWithSpriteFrame(pButtonFrame3);
    iconButton6->setScale(0.95);
    auto pImageCancel = CCMenuItemSprite::create(iconButton5, iconButton6, this, menu_selector(ADGameShow::closeHandle));
    pImageCancel->setPosition(Vec2(winSize.width*0.5+100,winSize.height*0.5-100));
    m_menu->addChild(pImageCancel,3);

    
    m_openAppId = adInfo.strAppId;
    m_openUrl = adInfo.strDownloadUrl;
}


void ADGameShow::closeHandle(Ref *pSender)
{
    removeFromParentAndCleanup(true);
}


void ADGameShow::openHandle(Ref *pSender)
{
    //跳转推荐
    GeneralizeServer::getInstance()->GameRecommed(m_openAppId.c_str(), REWARD_GAME);
    //打开下载链接
    IOSInfo::openUrl(m_openUrl);
    
    removeFromParentAndCleanup(true);
}


bool ADGameShow::onTouchBegan(Touch *pTouch, Event *pEvent)
{
    return true;
}

void ADGameShow::onTouchMoved(Touch *pTouch, Event *pEvent)
{
    
}

void ADGameShow::onTouchEnded(Touch *pTouch, Event *pEvent)
{
    
}

