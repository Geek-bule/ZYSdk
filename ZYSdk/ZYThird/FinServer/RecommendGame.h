//
//  RecommendGame.h
//  SpriteSheet
//
//  Created by JustinYang on 15/8/8.
//
//

#ifndef __SpriteSheet__RecommendGame__
#define __SpriteSheet__RecommendGame__

#include <stdio.h>
#include "GeneralizeServer.h"
#include "cocos2d.h"
USING_NS_CC;


////////////////////////////////////////////////////////////////
//                      调用示例
//
//      RecommendGame *layer = RecommendGame::create();
//      addChild(layer);
//
//      如果需要不同动画效果，修改源码
//
////////////////////////////////////////////////////////////////

//获取图片的获取次数限制
#define IMAGE_GET_TIMES         100 //(次)
//图片换取的时间间隔
#define IMAGE_GET_APART         0.1  //(秒)

#define CREATE_Game(__TYPE__) \
static __TYPE__* create(Vec2 btnPos) \
{ \
__TYPE__ *pRet = new(std::nothrow) __TYPE__(); \
if (pRet && pRet->init(btnPos)) \
{ \
pRet->autorelease(); \
return pRet; \
} \
else \
{ \
delete pRet; \
pRet = NULL; \
return NULL; \
} \
}

class RecommendGame : public Layer
{
public:
    CREATE_Game(RecommendGame);
    virtual bool init(Vec2 btnPos);
    ~RecommendGame();
    
    void setIconScale(float scale);
    
    //展示可点击图片
    void showIconButton();
    void iconButtonCall(Ref* pObj);
    //判断图片是否存在
    bool isImageExsit(std::string imagePath);
    //判断并处理图片更多游戏的图片是否下载完整
    bool getMoreImageInfo();
    //更新函数
    void updateTime(float dt);
    //已下载好图片的列表id
//    std::vector<int> m_listId;
    //游戏信息列表
    tagMOREGAMEINFO* m_gameInfo;
    //
    float m_updateTime;
    int m_index;//
    int m_showIndex;//
    int m_Times;//下载图片的循环次数
    Vec2 m_btnPos;
    
    void showGame();
    
    float m_IconScale;
};


//
//// RecommendLayer 为推广按钮点击后出现的推广界面,
//// 这个只是展示调用例子，可以根据游戏来自定义展示的界面
//


class RecommendLayer : public Layer
{
public:
    CREATE_FUNC(RecommendLayer);
    virtual bool init();
    
    //调用此借口，创建推广界面信息
    void createIcon(SpriteFrame *frame,const char *url,RecommendGame *pTarget,const char *appid);
private:
    void playButtonCall(Ref *pObj);
    void closeButtonCall(Ref* pObj);
    
    std::string m_DownloadUrl;
    RecommendGame *m_Target;
    std::string m_recommendedAppid;
//    MenuItemImage *playButton;
//    MenuItemImage *closeButton;
    Node *m_pNode;
    
    bool onTouchBegan(Touch* touch, Event* event);
    void onTouchMoved(Touch* touch, Event* event);
    void onTouchEnded(Touch* touch, Event* event);
};









#endif /* defined(__SpriteSheet__RecommendGame__) */
