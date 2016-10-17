//
//  ZYTools.cpp
//  sdkIOSDemo
//
//  Created by JustinYang on 16/9/30.
//
//

#include "ZYTools.h"
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)



//init
void ZYTools::init()
{
    
}

void ZYTools::initAdSdk()
{
    
}

//open log
void ZYTools::showLog()
{

}

//rate game
void ZYTools::rateWithTip()
{

}
//rate game
void ZYTools::rateWithUrl()
{

}

//show ad game
void ZYTools::setAdGame(bool isShow)
{
    
}
//ad game pos
void ZYTools::setAdGame()
{

}





//==========ZYAdview sdk接入==========
#ifdef ZYTOOLS_ADVIEW
//init adConfig
void ZYTools::initConfig()
{
    
}
//init banner
void ZYTools::initBannerView()
{
    
}
//showBanner
void ZYTools::showBannerView()
{
    
}
//hideBanner
void ZYTools::hideBannerView()
{

}

//init interstitial
void ZYTools::initInterstitial()
{

}
//show interstitial
void ZYTools::showInterstitial()
{
    
}

//show splash
void ZYTools::showSplash()
{

}
#endif



//==========ZYVideo sdk接入==========
#ifdef ZYTOOLS_VIDEO
//init video
void ZYTools::initVideoSdk()
{

}
//show video
void ZYTools::showVideo()
{

}
#endif

#endif