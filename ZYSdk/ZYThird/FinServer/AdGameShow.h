//
//  AdGameShow.hpp
//  sdkIOSDemo
//
//  Created by JustinYang on 16/8/19.
//
//

#ifndef AdGameShow_hpp
#define AdGameShow_hpp

#include <stdio.h>
#include "cocos2d.h"
USING_NS_CC;
#include "GeneralizeServer.h"


class ADGameShow : public Layer
{
public:
    CREATE_FUNC(ADGameShow);
    virtual bool init();
    ~ADGameShow();
    
    void ShowAdGame(tagMOREGAMEINFO &adInfo);
    
private:
    std::string m_openAppId;
    std::string m_openUrl;

    Menu *m_menu;
    
    void closeHandle(Ref *pSender);
    void openHandle(Ref *pSender);
    
    bool onTouchBegan(Touch* touch, Event* event);
    void onTouchMoved(Touch* touch, Event* event);
    void onTouchEnded(Touch* touch, Event* event);
    
};

#endif /* AdGameShow_hpp */
