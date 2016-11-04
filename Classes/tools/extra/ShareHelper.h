//
//  ShareHelper.h
//  SpriteSheet
//
//  Created by JustinYang on 15/8/17.
//
//

#ifndef __SpriteSheet__ShareHelper__
#define __SpriteSheet__ShareHelper__

#import "cocos2d.h"

//分享
#define SHARE_registerApp           "4ff8051a5fc" //4ff8051a5fc
#define SHARE_WXappid               "wxa467f86b4d427b77"
#define SHARE_WXscrid               "c43ec03a72699816c79026d96d53f441"
#define SHARE_FBappid               "1574292126124080"
#define SHARE_FBscrid               "9790011b9a949c283ca85665b3e59862"


typedef std::function<void(int)> ccShareCallBack;

class ShareHelper
{
public:
    static ShareHelper *shareHelper();
    void init();
    void initFunction(const ccShareCallBack call);
    void shareWithMsg(const char* title, const char* message,int award, cocos2d::Vec2 pt);
    void shareToWechat(const char* msg,int award);
    void shareDeviceInfo();
    
    ccShareCallBack callback;
};

#endif /* defined(__SpriteSheet__ShareHelper__) */
