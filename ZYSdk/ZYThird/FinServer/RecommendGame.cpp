//
//  RecommendGame.cpp
//  SpriteSheet
//
//  Created by JustinYang on 15/8/8.
//
//

#include "RecommendGame.h"
#include "GameParam.hpp"
#include "IOSinfo.h"
USING_NS_CC;


#define UM_RECOMMEND                "recommend"

RecommendGame::~RecommendGame()
{
    
}

bool RecommendGame::init(Vec2 btnPos)
{
    if (!Layer::create()) {
        return false;
    }
    //当有数据时才进行展示
    m_index = 0;
    m_Times = 0;
    m_updateTime=0;
    m_showIndex=0;
    m_IconScale=1.0;
    
    //获取信息
    showGame();
        
    m_btnPos = btnPos;
    
    return true;
}

void RecommendGame::setIconScale(float scale)
{
    m_IconScale = scale;
}

void RecommendGame::showGame()
{
    m_gameInfo = GeneralizeServer::getInstance()->GetMoreGameInfo();
    schedule(schedule_selector(RecommendGame::updateTime), IMAGE_GET_APART);
    m_Times = 0;
}

//通过一段时间的循环判断，是否下载成功游戏的图片
void RecommendGame::updateTime(float dt)
{
    getMoreImageInfo();
    m_Times ++;
    //超过时间之后就不获取了
    if (m_Times == IMAGE_GET_TIMES) {
        m_Times = 0;
        unschedule(schedule_selector(RecommendGame::updateTime));
        showGame();
    }
}
//获取存储到本地的游戏信息，如果图片下载成功了就调用 showIconButton() 函数就进行展示
bool RecommendGame::getMoreImageInfo()
{
    if (m_gameInfo != nullptr) {
        //对vector中没有记录的，判断图片是否存在
        if (isImageExsit(m_gameInfo->strImagePath)) {
            if (isImageExsit(m_gameInfo->strIconButton)) {
                SpriteFrame *pButtonFrame = GeneralizeServer::getInstance()->GetSpriteFromWriteablePath(m_gameInfo->strIconButton.c_str());
                SpriteFrameCache::getInstance()->addSpriteFrame(pButtonFrame, m_gameInfo->strIconButton.c_str());
                showIconButton();
                unschedule(schedule_selector(RecommendGame::updateTime));
            }
        }
    }else{
        m_gameInfo = GeneralizeServer::getInstance()->GetMoreGameInfo();
    }
    return false;
}

//下载图片成功之后，进行游戏推荐展示
void RecommendGame::showIconButton()
{
    removeChildByTag(75);
    
    //做一个后台开关，防止出问题时不能关闭功能
    if (GameParam::getInstance().getParamInt(UM_RECOMMEND) == 1){
        
        //随机展示一个游戏的信息
        auto iconButton = ui::Button::create("", "","",ui::Button::TextureResType::PLIST);
        iconButton->loadTextureNormal(m_gameInfo->strIconButton,ui::Button::TextureResType::PLIST);
        iconButton->loadTexturePressed(m_gameInfo->strIconButton,ui::Button::TextureResType::PLIST);
        iconButton->setPosition(m_btnPos);
        iconButton->addClickEventListener(CC_CALLBACK_1(RecommendGame::iconButtonCall, this));
        this->addChild(iconButton,1,75);
        iconButton->setScale(m_IconScale);
        
        
        //按钮效果
        ActionInterval *pScale1 = ScaleTo::create(1.5, m_IconScale+0.1);
        ActionInterval *pScale2 = ScaleTo::create(1, m_IconScale);
        
        auto seq = Sequence::create(pScale1, pScale2,NULL);
        
        auto Action = RepeatForever::create(seq);
        
        iconButton->runAction(Action);
    }

}

//展示按钮点击回调
void RecommendGame::iconButtonCall(Ref *pObj)
{
    //pObj go out and remove
    ui::Button *iconButton = (ui::Button*)pObj;
    iconButton->removeFromParentAndCleanup(true);
    
    //layer go in
    RecommendLayer *player = RecommendLayer::create();
    SpriteFrame *frame = GeneralizeServer::getInstance()->GetSpriteFromWriteablePath(m_gameInfo->strImagePath.c_str());
    player->createIcon(frame, m_gameInfo->strDownloadUrl.c_str(),this,m_gameInfo->strAppId.c_str());
    player->setPosition(0,0);
    addChild(player,5);
    
    
}

//判断游戏图片是否存在本地
bool RecommendGame::isImageExsit(std::string imagePathAll)
{
    int pos = imagePathAll.find_first_of('/');
    std::string imagePath(imagePathAll.substr(pos+1,imagePathAll.size()));
    std::string iconimage =  FileUtils::getInstance()->getWritablePath()+imagePath;
    bool fileIsExist = FileUtils::getInstance()->isFileExist(FileUtils::getInstance()->fullPathForFilename(iconimage.c_str()));
    if (fileIsExist) {
        SpriteFrame *pImageFrame = GeneralizeServer::getInstance()->GetSpriteFromWriteablePath(imagePathAll.c_str());
        Sprite* iconPng = Sprite::createWithSpriteFrame(pImageFrame);
        if (iconPng) {
            return true;
        }
    }
    return false;
}

/*****************
 RecommendLayer
 *****************/

//
//// RecommendLayer 为推广按钮点击后出现的推广界面,
//// 这个只是展示调用例子，可以根据游戏来自定义展示的界面
//

bool RecommendLayer::init()
{
    if (!CCLayer::create()) {
        return false;
    }
    
    LayerColor *pLayer = LayerColor::create(Color4B(0, 0, 0, 150));
    pLayer->setPosition(0,0);
    addChild(pLayer);
    
    Size winSize = Director::getInstance()->getWinSize();
    
    //创建一个Node
    m_pNode = Node::create();
    m_pNode->setPosition(Point(0,winSize.height));
    addChild(m_pNode,1,1);
    
    
    // Register Touch Event
    auto listener = EventListenerTouchOneByOne::create();
    listener->setSwallowTouches(true);
    
    listener->onTouchBegan = CC_CALLBACK_2(RecommendLayer::onTouchBegan, this);
    listener->onTouchMoved = CC_CALLBACK_2(RecommendLayer::onTouchMoved, this);
    listener->onTouchEnded = CC_CALLBACK_2(RecommendLayer::onTouchEnded, this);
    
    _eventDispatcher->addEventListenerWithSceneGraphPriority(listener, this);
    
    
    //动画
    auto pMove = MoveTo::create(0.3,Point(0,0));
    auto pAct = EaseBackOut::create(pMove);
    auto action = Sequence::create(pAct, NULL);
    m_pNode->runAction(action);
    
    return true;
}


void RecommendLayer::createIcon(SpriteFrame *frame, const char *url,RecommendGame *pTarget,const char* appid)
{
    m_DownloadUrl = url;
    m_Target = pTarget;
    m_recommendedAppid = appid;
    Sprite *pIcon = Sprite::createWithSpriteFrame(frame);
    Size winSize = Director::getInstance()->getWinSize();
    pIcon->setPosition(winSize.width/2,winSize.height/2);
    m_pNode->addChild(pIcon,1,1);
    
}


void RecommendLayer::playButtonCall(Ref *pObj)
{
    //跳转推荐
    GeneralizeServer::getInstance()->GameRecommed(m_recommendedAppid.c_str(), REWARD_GAME);
    //打开下载链接
    IOSInfo::openUrl(m_DownloadUrl);
    //close layer
    closeButtonCall(NULL);
}


void RecommendLayer::closeButtonCall(Ref *pObj)
{
    //做动作然后remove
    m_Target->showGame();
    removeFromParentAndCleanup(true);
}

bool RecommendLayer::onTouchBegan(Touch *pTouch, Event *pEvent)
{
    log("StartLayer touch layer ");
    Vec2 touchPoint = CCDirector::getInstance()->convertToGL(pTouch->getLocationInView());
    Rect rRect = m_pNode->getChildByTag(1)->getBoundingBox();
    if (rRect.containsPoint(touchPoint)) {
        playButtonCall(nullptr);
    }else{
        auto action1 = DelayTime::create(0.1);
        auto action2 = CallFuncN::create(CC_CALLBACK_1(RecommendLayer::closeButtonCall, this));
        auto action3 = Sequence::create(action1,action2, NULL);
        this->runAction(action3);
    }
    
    return true;
}

void RecommendLayer::onTouchMoved(Touch *pTouch, Event *pEvent)
{
    
}

void RecommendLayer::onTouchEnded(Touch *pTouch, Event *pEvent)
{
}









