#ifndef __HELLOWORLD_SCENE_H__
#define __HELLOWORLD_SCENE_H__

#include "cocos2d.h"

class HelloWorld : public cocos2d::Layer
{
public:
    // there's no 'id' in cpp, so we recommend returning the class instance pointer
    static cocos2d::Scene* createScene();
    static HelloWorld *getInstance();
    // Here's a difference. Method 'init' in cocos2d-x returns bool, instead of returning 'id' in cocos2d-iphone
    virtual bool init();
    
    void ktLoginCallback(Ref* pSender);
    
    void ktLogoutCallback(Ref* pSender);
    
    void ktplayCallback(Ref* pSender);
    
    void friendsCallback(Ref* pSender);
    
    void rateGameCallback(Ref* pSender);
    
    void shareSdkCallback(Ref* pSender);
    
    void mogoBannerCallback(Ref* pSender);
    
    void mogoInterstitialCallback(Ref* pSender);
    
    void videoCallback(Ref* pSender);
    
    void iapCallback(Ref* pSender);
    
    void gameCenterCallback(Ref* pSender);
    
    void notificateCallback(Ref* pSender);
    
    void MoreGameCallback(Ref* pSender);
    
    void submitStorageCallback(Ref* pSender);
    
    void updateStorageCallback(Ref* pSender);
    
    void consumeHeartCallback(Ref* pSender);
    
    void addHeartCallback(Ref* pSender);
    
    void addHeartMaxCallback(Ref* pSender);
    
    void videoBtnVisible(bool isVisible);
    
    void iapLoadSuccess();
    
    void videoPlayFinish();

    // implement the "static create()" method manually
    CREATE_FUNC(HelloWorld);
    
    
    bool m_isShowBanner;
    bool m_switchBanner;
    bool m_isLoadIntertitial;
    bool m_isLoadIap;
    bool m_isAdCircle;
    bool m_isAdTriangle;
    cocos2d::Size winSize;
    
    enum{
        enBtnInApp=1,
        enBtnShare,
        enBtnKTplay,
        enBtnMoreGame,
        enBtnMoreGame2,
        enBtnWatch,
        enBtnWxPay,
        enBtnDevice,
        enBtnVideo,
        enBtnMenu,
        enBtnInter,
        enBtn,
    };
};



#endif // __HELLOWORLD_SCENE_H__
