//
//  GeneralizeServer.cpp
//  MyPopo3
//
//  Created by JustinYang on 15/8/4.
//
//

#include "GeneralizeServer.h"
#include "IOSInfo.h"

#define LIMIT_TIME              "recommend-limittime1"
#define REMOVE_TIME             "recommend-removetime"


#define HTTP_MOREGAME           "http://www.zongyigame.com:8801/zhongyi/gameInfoIF/getRanGameInfos/v2"
#define HTTP_NEWGAME            "http://www.zongyigame.com:8801/zhongyi/gameInfoIF/getNewGameInfo"
#define HTTP_REGISTER           "http://www.zongyigame.com:8801/zhongyi/gameInfoIF/saveMobileGame"
#define HTTP_RECOMMEND          "http://www.zongyigame.com:8801/zhongyi/gameInfoIF/saveMobileJumpGame"
#define HTTP_ACTIVATION         "http://www.zongyigame.com:8801/zhongyi/gameInfoIF/getUnexchangedRewardList"
#define HTTP_EXCHANGE           "http://www.zongyigame.com:8801/zhongyi/gameInfoIF/changeStatusExchangedReward"





static GeneralizeServer *instance = nullptr;

GeneralizeServer *GeneralizeServer::getInstance()
{
    if (instance == nullptr) {
        MessageBox("互推功能没初始化", "错误");
    }
    return instance;
}


GeneralizeServer* GeneralizeServer::create(std::string appid)
{
    instance = new(std::nothrow) GeneralizeServer();
    if (instance && instance->init(appid))
    {
        instance->retain();
        return instance;
    }
    else
    {
        delete instance;
        instance = NULL;
        return NULL;
    }
}


GeneralizeServer::~GeneralizeServer()
{
    instance = nullptr;
}

bool GeneralizeServer::init(std::string appid)
{
    if (!Node::init()) {
        return false;
    }
    
    m_strAwardAppName= "";
    m_nAwardAppCoins =0 ;
    strAppid = appid;
    
    //语言版本判断
    m_strCurrentlanguage = IOSInfo::getLanguage();
    m_strCurrentSystem = "ios";
    m_strIosIdfa = IOSInfo::getIdFa();
    
    
    //注册成功之后不再进行注册
    m_vecTheadList.push_back(post_register);
    if (MoreGameDayCheck()) {
        m_vecTheadList.push_back(post_moregame);
    }
    m_vecTheadList.push_back(post_activation);
    
    //从本读读取数据
    getVectorDataFormJson();
    
    SendMessage();

    return true;
}

void GeneralizeServer::GameActivateCheck()
{
    SendActiveStateRequest(m_strIosIdfa.c_str(), strAppid.c_str());
}

void GeneralizeServer::GameRecommed(const char *reappid,int reward)
{
    SendRecommendRequest(m_strIosIdfa.c_str(), strAppid.c_str(), reappid,reward);
}

void GeneralizeServer::SendDownloadMessage(std::string imagePath)
{
    std::string strUrl = imagePath;
    SendDownloadImageRequest(strUrl);
}

//从读写路径中读取图片数据
SpriteFrame* GeneralizeServer::GetSpriteFromWriteablePath(const char* name)
{
    std::string imagePath = name;
    std::string path = FileUtils::getInstance()->getWritablePath();
    int posi = imagePath.find_first_of('/');
    std::string imagePathPart(imagePath.substr(posi+1,imagePath.size()));
    path += imagePathPart;
    FILE* fp = fopen(path.c_str(), "rb");
    if (!fp)
    {
        return NULL;
    }
    fseek(fp, 0, SEEK_END);
    int len = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    char* buf = (char*)malloc(len);
    fread(buf, len, 1, fp);
    fclose(fp);
    
    SpriteFrame* callBackFrame = GetSpriteFrameFromData(buf, len);
    free(buf);
    return callBackFrame;
}

//根据字符转换成图片数据
SpriteFrame *GeneralizeServer::GetSpriteFrameFromData(const char *buf,int len)
{
    Image* img = new Image;
    img->initWithImageData((const unsigned char*)buf, len);
    if (img->getData() == NULL || img->getDataLen() <= 0){
        img->release();
        return NULL;
    }
    cocos2d::Texture2D* texture = new cocos2d::Texture2D();
    bool isImg = texture->initWithImage(img);
    img->release();
    if (!isImg)
    {
        delete texture;
        return NULL;
        //return CCSprite::create("default.png");//加载资源并非图片时返回的默认图
    }
    
    Sprite* sprite = Sprite::createWithTexture(texture);
    float sWidth = sprite->getContentSize().width;
    float sHeight = sprite->getContentSize().height;
    SpriteFrame* callBackFrame = SpriteFrame::createWithTexture(texture, CCRect(0,0,sWidth,sHeight));
    texture->release();
    return callBackFrame;
}


//判断图片是否已经下载过了
bool GeneralizeServer::isImageExsit(std::string imagePathAll)
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


bool GeneralizeServer::MoreGameDayCheck()
{
    struct timeval now;
    gettimeofday(&now, NULL);
    long long timeNow = now.tv_sec;
    
    std::string timeData = UserDefault::getInstance()->getStringForKey(LIMIT_TIME,"0");
    long long timeLast = atoll(timeData.c_str());
    
    long long timeDistance = timeNow-timeLast;
    long long sevenDay = DAY_APART*24*60*60;
    if (timeDistance > sevenDay) {
        return true;
    }
    return false;
}

bool GeneralizeServer::removeImageDayCheck()
{
    struct timeval now;
    gettimeofday(&now, NULL);
    long long timeNow = now.tv_sec;
    
    std::string timeData = UserDefault::getInstance()->getStringForKey(REMOVE_TIME,"0");
    long long timeLast = atoll(timeData.c_str());
    
    long long timeDistance = timeNow-timeLast;
    long long sevenDay = REMOVE_APART*24*60*60;
    if (timeDistance > sevenDay) {
        return true;
    }
    return false;
}

void GeneralizeServer::SendMessage()
{
    if (m_vecTheadList.size() > 0){
        switch (*m_vecTheadList.begin()) {
            case post_register:
                SendRegisterRequest(m_strIosIdfa.c_str(), strAppid.c_str());
                break;
            case post_moregame:
                SendGameInfoRequest(m_strIosIdfa.c_str(), strAppid.c_str());
                break;
            case post_newgame:
                break;
            case post_recommend://测试用
                SendRecommendRequest(m_strIosIdfa.c_str(), strAppid.c_str(), "982089666",REWARD_GAME);
                break;
            case 111://测试用
                SendRegisterRequest(m_strIosIdfa.c_str(), "982089666");
                break;
            case 222://测试用
                SendRecommendRequest(m_strIosIdfa.c_str(), strAppid.c_str(), "698597073",REWARD_GAME);
                break;
            case 333://测试用
                SendRegisterRequest(m_strIosIdfa.c_str(), "698597073");
                break;
            case post_activation:
                SendActiveStateRequest(m_strIosIdfa.c_str(), strAppid.c_str());
                break;
            default:
                break;
        }
        
        m_vecTheadList.erase(m_vecTheadList.begin());
    }
}

void GeneralizeServer::FailMessageDeal(PostId post, CodeId code)
{
    SendMessage();
}

//
////发送注册本机的消息
//

void GeneralizeServer::SendRegisterRequest(const char* udid,const char* appid)
{
    HttpRequest* request = new HttpRequest();
    request->setUrl(HTTP_REGISTER);
    request->setRequestType(HttpRequest::Type::POST);
    request->setResponseCallback(CC_CALLBACK_2(GeneralizeServer::GetRegisterResponse, this));
    
    // write the post data
    __String *pData = __String::createWithFormat("udid=%s&appid=%s&language=%s&operatingSystem=%s",udid,appid,m_strCurrentlanguage.c_str(),m_strCurrentSystem.c_str());
    const char* postData = pData->getCString();
    request->setRequestData(postData, strlen(postData));
    log("互推机制:GeneralizeServer-- %s%s",HTTP_REGISTER,pData->getCString());
    HttpClient::getInstance()->send(request);
    request->release();
}

void GeneralizeServer::GetRegisterResponse(HttpClient *sender, HttpResponse *response)
{
    if (!response)
    {
        log("互推机制:接收返回消息失败");
        return;
    }
    
    int statusCode = response->getResponseCode();
    char statusString[64] = {};
    sprintf(statusString, "HTTP Status Code: %d", statusCode);
    log("互推机制:%s", statusString);
    
    if (!response->isSucceed())
    {
        log("互推机制:response failed");
        log("互推机制:error buffer: %s", response->getErrorBuffer());
        return;
    }
    
    // dump data
    std::vector<char> *buffer = response->getResponseData();
    std::string getbuffer(buffer->begin(),buffer->end());
    
    rapidjson::Document _doc;
    std::string load_str((const char*)getbuffer.c_str(), buffer->size());
    log("互推机制:GeneralizeServer-- %s%s",HTTP_REGISTER,load_str.c_str());
    _doc.Parse<0>(load_str.c_str());
    if(!_doc.IsObject()){
        return;
    }
    
    if(!_doc.HasMember("code")){
        return;
    }
    // 通过[]取成员值,再根据需要转为array,int,double,string
    const rapidjson::Value &pCode = _doc["code"];
    const char* codeStr = pCode.GetString();
    //根据code码判断失败原因
    if (!GeneralizeServer::CompareCode(codeStr)) {
        return;
    }
    //执行下一接口
    SendMessage();
    
}

//
////发送获取更多游戏消息
//

void GeneralizeServer::SendGameInfoRequest(const char* udid,const char* appid)
{
    HttpRequest* request = new HttpRequest();
    request->setUrl(HTTP_MOREGAME);
    request->setRequestType(HttpRequest::Type::POST);
    request->setResponseCallback(CC_CALLBACK_2(GeneralizeServer::GetGameInfoResponse, this));
    
    // write the post data
    __String *pData = __String::createWithFormat("language=%s&operatingSystem=%s&count=%d&udid=%s&appid=%s",m_strCurrentlanguage.c_str(),m_strCurrentSystem.c_str(),GAME_COUNT,udid,appid);
    const char* postData = pData->getCString();
    request->setRequestData(postData, strlen(postData));
    log("互推机制:GeneralizeServer-- %s%s",HTTP_MOREGAME,pData->getCString());
    HttpClient::getInstance()->send(request);
    request->release();
}

void GeneralizeServer::GetGameInfoResponse(HttpClient *sender, HttpResponse *response)
{
    if (!response)
    {
        log("互推机制:接收返回消息失败");
        FailMessageDeal(post_moregame, code_fail);
        return;
    }
    
    int statusCode = response->getResponseCode();
    char statusString[64] = {};
    sprintf(statusString, "HTTP Status Code: %d", statusCode);
    log("互推机制:%s", statusString);
    
    if (!response->isSucceed())
    {
        log("互推机制:response failed");
        log("互推机制:error buffer: %s", response->getErrorBuffer());
        FailMessageDeal(post_moregame, code_fail);
        return;
    }
    
    // dump data
    std::vector<char> *buffer = response->getResponseData();
    std::string getbuffer(buffer->begin(),buffer->end());
    
    rapidjson::Document _doc;
    std::string load_str((const char*)getbuffer.c_str(), buffer->size());
    log("互推机制:GeneralizeServer-- %s%s",HTTP_MOREGAME,load_str.c_str());
    _doc.Parse<0>(load_str.c_str());
    //解读json数据
    if (!ReadGameInfo(_doc)) {
        FailMessageDeal(post_moregame, code_code);
        return;
    }else{
        //存储解读的json数据
        saveJsonDataFormVector();
        log("互推机制:更多游戏json写入成功");
    }
    
    //成功之后进行下一个接口
    SendMessage();
    //保存一个时间，超过7天换一次更多游戏内容
    struct timeval now;
    gettimeofday(&now, NULL);
    long long timell = now.tv_sec;
    __String *pTimeLimit = __String::createWithFormat("%lld",timell);
    UserDefault::getInstance()->setStringForKey(LIMIT_TIME, pTimeLimit->getCString());
    
    //下载新的图片
    pushAdImagePath();
}

//
////发送推荐游戏的消息
//

void GeneralizeServer::SendRecommendRequest(const char* udid,const char* appid,const char* recommendid,int reward)
{
    HttpRequest* request = new HttpRequest();
    request->setUrl(HTTP_RECOMMEND);
    request->setRequestType(HttpRequest::Type::POST);
    request->setResponseCallback(CC_CALLBACK_2(GeneralizeServer::GetRecommendResponse, this));
    
    // write the post data
    __String *pData = __String::createWithFormat("udid=%s&appid=%s&recommendedAppid=%s&reward=%d",udid,appid,recommendid,reward);
    const char* postData = pData->getCString();
    request->setRequestData(postData, strlen(postData));
    log("互推机制:GeneralizeServer-- %s%s",HTTP_RECOMMEND,pData->getCString());
    HttpClient::getInstance()->send(request);
    request->release();
}

void GeneralizeServer::GetRecommendResponse(HttpClient *sender, HttpResponse *response)
{
    if (!response)
    {
        log("互推机制:接收返回消息失败");
        return;
    }
    
    int statusCode = response->getResponseCode();
    char statusString[64] = {};
    sprintf(statusString, "HTTP Status Code: %d", statusCode);
    log("互推机制:%s", statusString);
    
    if (!response->isSucceed())
    {
        log("互推机制:response failed");
        log("互推机制:error buffer: %s", response->getErrorBuffer());
        return;
    }
    
    // dump data
    std::vector<char> *buffer = response->getResponseData();
    std::string getbuffer(buffer->begin(),buffer->end());
    
    rapidjson::Document _doc;
    std::string load_str((const char*)getbuffer.c_str(), buffer->size());
    log("互推机制:GeneralizeServer-- %s%s",HTTP_RECOMMEND,load_str.c_str());
    _doc.Parse<0>(load_str.c_str());
    if(!_doc.IsObject()){
        return;
    }
    if(!_doc.HasMember("code")){
        return;
    }
    // 通过[]取成员值,再根据需要转为array,int,double,string
    const rapidjson::Value &pCode = _doc["code"];
    const char* codeStr = pCode.GetString();
    //根据code码判断失败原因
    if (!GeneralizeServer::CompareCode(codeStr)) {
        return;
    }
    
    //发送推荐游戏成功
    log("互推机制:发送推荐游戏成功");
    SendMessage();
}

//
////发送获取激活游戏列表的消息
//

void GeneralizeServer::SendActiveStateRequest(const char* udid,const char* appid)
{
    HttpRequest* request = new HttpRequest();
    request->setUrl(HTTP_ACTIVATION);
    request->setRequestType(HttpRequest::Type::POST);
    request->setResponseCallback(CC_CALLBACK_2(GeneralizeServer::GetActiveStateResponse, this));
    
    // write the post data
    __String *pData = __String::createWithFormat("udid=%s&appid=%s&language=%s&operatingSystem=%s",udid,appid,m_strCurrentlanguage.c_str(),m_strCurrentSystem.c_str());
    const char* postData = pData->getCString();
    request->setRequestData(postData, strlen(postData));
    HttpClient::getInstance()->send(request);
    request->release();
}

void GeneralizeServer::GetActiveStateResponse(HttpClient *sender, HttpResponse *response)
{
    if (!response)
    {
        log("互推机制:接收返回消息失败");
        return;
    }
    
    int statusCode = response->getResponseCode();
    char statusString[64] = {};
    sprintf(statusString, "HTTP Status Code: %d", statusCode);
    log("互推机制:%s", statusString);
    
    if (!response->isSucceed())
    {
        log("互推机制:response failed");
        log("互推机制:error buffer: %s", response->getErrorBuffer());
        return;
    }
    
    // dump data
    std::vector<char> *buffer = response->getResponseData();
    std::string getbuffer(buffer->begin(),buffer->end());
    
    rapidjson::Document _doc;
    std::string load_str((const char*)getbuffer.c_str(), buffer->size());
    _doc.Parse<0>(load_str.c_str());
    if(!_doc.IsObject()){
        return;
    }
    if(!_doc.HasMember("code")){
        return;
    }
    // 通过[]取成员值,再根据需要转为array,int,double,string
    const rapidjson::Value &pCode = _doc["code"];
    const char* codeStr = pCode.GetString();
    //根据code码判断失败原因
    if (!GeneralizeServer::CompareCode(codeStr)) {
        return;
    }
    
    //推荐游戏激活成功，发给用户奖励并提示
    //是否有此成员
    if(!_doc.HasMember("activatedList")){
        return;
    }
    // 通过[]取成员值,再根据需要转为array,int,double,string
    const rapidjson::Value &pArray = _doc["activatedList"];
    
    //是否是数组
    if(!pArray.IsArray()){
        return;
    }
    for (rapidjson::SizeType i = 0; i < pArray.Size(); i++)
    {
        const rapidjson::Value &valueEnt = pArray[i];
        if(valueEnt.HasMember("id") && valueEnt.HasMember("udid") &&
           valueEnt.HasMember("appid") && valueEnt.HasMember("recommendedAppid") &&
           valueEnt.HasMember("createTime") && valueEnt.HasMember("reward") &&
           valueEnt.HasMember("isActivated"))
        {
            tagACTIVATEINFO game1;
            game1.nGameId = i;
            
            const rapidjson::Value &gameUdid = valueEnt["udid"];
            const char* sGameUdid = gameUdid.GetString();      //得到int值
            game1.strUdid = sGameUdid;
            
            const rapidjson::Value &gameAppid = valueEnt["appid"];
            const char* sGameAppid = gameAppid.GetString();
            game1.strAppid = sGameAppid;
            
            const rapidjson::Value &recommendedAppid = valueEnt["recommendedAppid"];
            const char* sRecommendedAppid = recommendedAppid.GetString();
            game1.strRecommendedAppid = sRecommendedAppid;
            
            const rapidjson::Value &createTime = valueEnt["createTime"];
            int64_t nCreateTime = createTime.GetInt64();
            game1.nCreateTime = nCreateTime;
            
            const rapidjson::Value &reward = valueEnt["reward"];
            int nReward = reward.GetInt();
            game1.nReward = nReward;
            
            const rapidjson::Value & appName = valueEnt["name"];
            const char* sAppName = appName.GetString();
            game1.strName = sAppName;
            
            m_vecActivateInfoList.push_back(game1);
        }else{
            log("互推机制:获取推荐游戏信息不全？");
        }
    }
    //获取成功后就尝试发放奖励
    if (m_vecActivateInfoList.size() > 0) {
        tagACTIVATEINFO info = m_vecActivateInfoList[0];
        SendExchangedRewardRequest(info.strUdid.c_str(), info.strAppid.c_str(), info.strRecommendedAppid.c_str());
    }
}

//
////发送领取奖励的消息
//

void GeneralizeServer::SendExchangedRewardRequest(const char *udid, const char *appid, const char *recommendedAppid)
{
    HttpRequest* request = new HttpRequest();
    request->setUrl(HTTP_EXCHANGE);
    request->setRequestType(HttpRequest::Type::POST);
    request->setResponseCallback(CC_CALLBACK_2(GeneralizeServer::GetExchangedRewardResponse, this));
    
    // write the post data
    __String *pData = __String::createWithFormat("udid=%s&appid=%s&recommendedAppid=%s",udid,appid,recommendedAppid);
    const char* postData = pData->getCString();
    request->setRequestData(postData, strlen(postData));
    
    HttpClient::getInstance()->send(request);
    request->release();
}

void GeneralizeServer::GetExchangedRewardResponse(HttpClient *sender, HttpResponse *response)
{
    if (!response)
    {
        log("互推机制:接收返回消息失败");
        return;
    }
    
    int statusCode = response->getResponseCode();
    char statusString[64] = {};
    sprintf(statusString, "HTTP Status Code: %d", statusCode);
    log("互推机制:%s", statusString);
    
    if (!response->isSucceed())
    {
        log("互推机制:response failed");
        log("互推机制:error buffer: %s", response->getErrorBuffer());
        return;
    }
    
    // dump data
    std::vector<char> *buffer = response->getResponseData();
    std::string getbuffer(buffer->begin(),buffer->end());
    
    rapidjson::Document _doc;
    std::string load_str((const char*)getbuffer.c_str(), buffer->size());
    _doc.Parse<0>(load_str.c_str());
    if(!_doc.IsObject()){
        return;
    }
    if(!_doc.HasMember("code")){
        return;
    }
    // 通过[]取成员值,再根据需要转为array,int,double,string
    const rapidjson::Value &pCode = _doc["code"];
    const char* codeStr = pCode.GetString();
    //根据code码判断失败原因
    if (!GeneralizeServer::CompareCode(codeStr)) {
        return;
    }
    //服务器允许发放奖励
    if (m_vecActivateInfoList.size() > 0) {
        tagACTIVATEINFO info = m_vecActivateInfoList[0];
        //添加到发放奖励的列表
        m_nAwardAppCoins += info.nReward;
        m_strAwardAppName.append(info.strName.c_str());
        m_strAwardAppName.append("\n");
        if (m_vecActivateInfoList.size()==1 && m_nAwardAppCoins > 0) {
            // 弹出任务奖励
            m_strAwardAppName= "";
            m_nAwardAppCoins =0 ;
        }
        
        //领过奖励的移除
        m_vecActivateInfoList.erase(m_vecActivateInfoList.begin());
        
        if (m_vecActivateInfoList.size() > 0) {
            tagACTIVATEINFO nextInfo = m_vecActivateInfoList[0];
            SendExchangedRewardRequest(nextInfo.strUdid.c_str(), nextInfo.strAppid.c_str(), nextInfo.strRecommendedAppid.c_str());
        }
    }
}

//
////发送下载图片资源的消息
//

void GeneralizeServer::SendDownloadImageRequest(std::string &imagePath)
{
    HttpRequest* request = new HttpRequest();
    request->setUrl(imagePath.c_str());
    request->setRequestType(HttpRequest::Type::GET);
    request->setResponseCallback(CC_CALLBACK_2(GeneralizeServer::GetDownloadImageResponse, this));
    log("互推机制:GeneralizeServer--download %s",imagePath.c_str());
    HttpClient::getInstance()->send(request);
    request->setTag(imagePath.c_str());
    request->release();
}

void GeneralizeServer::GetDownloadImageResponse(HttpClient *sender, HttpResponse *response)
{
    if (!response)
    {
        log("互推机制:接收返回消息失败");
        return;
    }
    int statusCode = response->getResponseCode();
    char statusString[64] = {};
    sprintf(statusString, "HTTP Status Code: %d", statusCode);
    log("互推机制:%s", statusString);
    
    if (!response->isSucceed())
    {
        log("互推机制:response failed");
        log("互推机制:error buffer: %s", response->getErrorBuffer());
        return;
    }
    
    if (statusCode != 200) {
        return;
    }
    
    // 图片信息
    std::vector<char> *buffer = response->getResponseData();
    std::string getbuffer(buffer->begin(),buffer->end());
    //检验字符串是否为图片数据
    if (strcmp(getbuffer.c_str(), "") == 0){
        log("互推机制:get buffer data failed");
        return;
    }
    log("互推机制:%s",getbuffer.c_str());
    Sprite *icon = Sprite::createWithSpriteFrame(GetSpriteFrameFromData(getbuffer.c_str(), buffer->size()));
    if (icon == NULL) {
        log("互推机制:不是图片的数据");
        return;
    }
    // 图片路径
    std::string imagePath = response->getHttpRequest()->getTag();
    int posi = imagePath.find_first_of('/');
    std::string imagePathPart(imagePath.substr(posi+1,imagePath.size()));
    int pos = imagePathPart.find_last_of('/');
    std::string dict(imagePathPart.substr(0, pos));
    std::string writePath = FileUtils::getInstance()->getWritablePath();
    std::string dictPath = writePath+dict;
    
    //先判断文件夹，没有先创建文件夹
    if (!FileUtils::getInstance()->isDirectoryExist(dictPath)) {
        FileUtils::getInstance()->createDirectory(dictPath);
    }
    //然后存储图片
    std::string path = writePath + imagePathPart;
    std::ofstream outfile;
    outfile.open(path.c_str());
    if (outfile.fail())
    {
        return;
    }
    outfile << getbuffer;
    outfile.close();
    
    //图片下载成功之后进入下一次的下载
    BeginDowndloadImage();
}

void GeneralizeServer::BeginDowndloadImage()
{
    if (m_vecImagePathList.size()>0) {
        log("互推机制:进入图片下载 ...");
        if (!isImageExsit(*m_vecImagePathList.begin())) {
            SendDownloadImageRequest(*m_vecImagePathList.begin());
            log("互推机制:GeneralizeServer--图片下载: %s",m_vecImagePathList.begin()->c_str());
        }
        m_vecImagePathList.erase(m_vecImagePathList.begin());
    }
}

void GeneralizeServer::BeginRemoveImage()
{
    if (m_remvoeImagePathVec.size()>0) {
        log("互推机制:进入图片移除 ...");
        if (!isImageExsit(*m_remvoeImagePathVec.begin())) {
            std::string imagePathAll = *m_remvoeImagePathVec.begin();
            int pos = imagePathAll.find_first_of('/');
            std::string imagePath(imagePathAll.substr(pos+1,imagePathAll.size()));
            std::string iconimage =  FileUtils::getInstance()->getWritablePath()+imagePath;
            FileUtils::getInstance()->removeFile(iconimage);
            log("互推机制:GeneralizeServer--图片移除: %s",iconimage.c_str());
        }
        m_remvoeImagePathVec.erase(m_remvoeImagePathVec.begin());
        BeginRemoveImage();
    }
}

bool GeneralizeServer::ReadGameInfo(rapidjson::Document &_doc)
{
    if(!_doc.IsObject()){
        return false;
    }
    if(!_doc.HasMember("code")){
        return false;
    }
    // 通过[]取成员值,再根据需要转为array,int,double,string
    const rapidjson::Value &pCode = _doc["code"];
    const char* codeStr = pCode.GetString();
    //根据code码判断失败原因
    if (!GeneralizeServer::CompareCode(codeStr)) {
        return false;
    }
    
    //是否有此成员
    if(!_doc.HasMember("gameInfoList")){
        return false;
    }
    // 通过[]取成员值,再根据需要转为array,int,double,string
    const rapidjson::Value &pArray = _doc["gameInfoList"];
    
    //是否是数组
    if(!pArray.IsArray()){
        return false;
    }
    
    //如果过了一个月，就删除掉之前的图片
//    mapGameInfo _DeleteGameInfoMap;
    m_GameAppIdVec.clear();
    if (removeImageDayCheck()) {
        RemoveImageDir();
//        _DeleteGameInfoMap.swap(m_MoreGameInfoMap);
//        struct timeval now;
//        gettimeofday(&now, NULL);
//        long long timell = now.tv_sec;
//        __String *pTimeLimit = __String::createWithFormat("%lld",timell);
//        UserDefault::getInstance()->setStringForKey(REMOVE_TIME, pTimeLimit->getCString());
    }
    for (rapidjson::SizeType i = 0; i < pArray.Size(); i++)
    {
        const rapidjson::Value &valueEnt = pArray[i];
        if(valueEnt.HasMember("gameInfoId") &&
           valueEnt.HasMember("operatingSystem") && valueEnt.HasMember("language") &&
           valueEnt.HasMember("appId") && valueEnt.HasMember("packageName") &&
           valueEnt.HasMember("schemes") && valueEnt.HasMember("downloadUrl") &&
           valueEnt.HasMember("name") && valueEnt.HasMember("fullIcon") &&
           valueEnt.HasMember("fullImagePath") && valueEnt.HasMember("fullIconButton"))
        {
            tagMOREGAMEINFO game1;
            game1.nGameId = i;
            
            if (valueEnt.HasMember("gameInfoId")) {
                const rapidjson::Value &gameInfoId = valueEnt["gameInfoId"];
                const char* sGameInfoId = gameInfoId.GetString();      //得到int值
                int nGameInfoId = atoi(sGameInfoId);
                game1.nGameInfoId = nGameInfoId;
            }
            
            if (valueEnt.HasMember("operatingSystem")) {
                const rapidjson::Value &operatingSystem = valueEnt["operatingSystem"];
                const char* sOperatingSystem = operatingSystem.GetString();
                game1.strSystem = sOperatingSystem;
            }
            
            if (valueEnt.HasMember("language")) {
                const rapidjson::Value &language = valueEnt["language"];
                const char* sLanguage = language.GetString();
                game1.strLanguage = sLanguage;
            }
            
            if (valueEnt.HasMember("appId")) {
                const rapidjson::Value &appid = valueEnt["appId"];
                const char* sAppid = appid.GetString();
                game1.strAppId = sAppid;
            }
            
            if (valueEnt.HasMember("packageName")) {
                const rapidjson::Value &packageName = valueEnt["packageName"];
                const char* sPackageName = packageName.GetString();
                game1.strPackage = sPackageName;
            }
            
            if (valueEnt.HasMember("schemes")) {
                const rapidjson::Value &schemes = valueEnt["schemes"];
                const char* sSchemes = schemes.GetString();
                game1.strSchemes = sSchemes;
            }
            
            if (valueEnt.HasMember("downloadUrl")) {
                const rapidjson::Value &downloadUrl = valueEnt["downloadUrl"];
                const char* sDownloadUrl = downloadUrl.GetString();
                game1.strDownloadUrl = sDownloadUrl;
            }
            
            if (valueEnt.HasMember("name")) {
                const rapidjson::Value &name = valueEnt["name"];
                const char* sName = name.GetString();
                game1.strGameName = sName;
            }
            
            if (valueEnt.HasMember("fullIcon")) {
                const rapidjson::Value &icon = valueEnt["fullIcon"];
                const char* sIcon = icon.GetString();
                game1.strIconPath = sIcon;
            }
            
            if (valueEnt.HasMember("fullIconButton")) {
                const rapidjson::Value &iconButton = valueEnt["fullIconButton"];
                const char* sIconButton = iconButton.GetString();
                game1.strIconButton = sIconButton;
            }
            
            if (valueEnt.HasMember("fullImagePath")) {
                const rapidjson::Value &image = valueEnt["fullImagePath"];
                const char* sImagePath = image.GetString();
                game1.strImagePath = sImagePath;
            }
            
            if (valueEnt.HasMember("adImage")) {
                const rapidjson::Value &adImageEnt = valueEnt["adImage"];
                const char* sAdImage = adImageEnt.GetString();
                game1.strAdImage = sAdImage;
            }
            
            if (valueEnt.HasMember("adImageOK")) {
                const rapidjson::Value &adImageOkEnt = valueEnt["adImageOK"];
                const char* sAdImageOk = adImageOkEnt.GetString();
                game1.strAdImageOk = sAdImageOk;
            }
            
            if (valueEnt.HasMember("adImageCancel")) {
                const rapidjson::Value &adImageCancelEnt = valueEnt["adImageCancel"];
                const char* sAdImageCancel = adImageCancelEnt.GetString();
                game1.strAdImageCancel = sAdImageCancel;
            }
            
            //进行一次判断，已经安装的游戏就不添加到展示列表
            if (!SchemesCheck(game1.strSchemes.c_str())) {
                //看看之前是不是有过这个游戏的信息
                auto iter = m_MoreGameInfoMap.find(game1.strAppId);
                if (iter == m_MoreGameInfoMap.end()) {
                    m_MoreGameInfoMap.insert(std::make_pair(game1.strAppId, game1));
                }else{
                    //对比信息看看是不是有更新
                    tagMOREGAMEINFO info = iter->second;
                    if (isDifferentInfo(game1, info)) {
                        //更新游戏信息
                        iter->second = game1;
                    }
                }
                //添加展示游戏列表
                m_GameAppIdVec.push_back(game1.strAppId);
//                //从要删除列表之中删除掉要展示的游戏
//                auto iter2 = _DeleteGameInfoMap.find(game1.strAppId);
//                if (iter2 != _DeleteGameInfoMap.end()) {
//                    _DeleteGameInfoMap.erase(iter2);
//                }
            }
        }else{
            log("互推机制:获取推荐游戏信息不全？");
        }
    }
//    //将过期的图片删除掉
//    for (auto iterDelete : _DeleteGameInfoMap) {
//        tagMOREGAMEINFO info = iterDelete.second;
//        m_remvoeImagePathVec.push_back(info.strIconPath);
//        m_remvoeImagePathVec.push_back(info.strIconButton);
//        m_remvoeImagePathVec.push_back(info.strImagePath);
//    }
//    //执行删除函数
//    BeginRemoveImage();
    return true;
}

bool GeneralizeServer::WriteGameInfo(rapidjson::Document &Doc)
{
    rapidjson::StringBuffer buffer;
    rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
    Doc.Accept(writer);
    std::string strJson(buffer.GetString(), buffer.GetSize());
    log("互推机制:BioEvolve::CElemDataMgr:%s", strJson.c_str());
    std::string filepath = (FileUtils::getInstance()->getWritablePath() + "gameinfov2.json");
    std::ofstream outfile;
    outfile.open(filepath.c_str());
    if (outfile.fail()) 
    { 
        return false;
    } 
    outfile << strJson;
    outfile.close();
    return true;
}

void GeneralizeServer::RemoveImageDir()
{
    std::string dirPath = FileUtils::getInstance()->getWritablePath()+"images";
    FileUtils::getInstance()->removeDirectory(dirPath);
}

bool GeneralizeServer::SchemesCheck(const char* schemes)
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    return false;
#elif (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
    return IOSInfo::canOpenUlr(schemes);
#endif
}

void GeneralizeServer::pushAdImagePath()
{
    for (auto iter : m_MoreGameInfoMap) {
        tagMOREGAMEINFO* game1 = &(iter.second);
        
        if (strcmp(game1->strAdImage.c_str(),"") != 0
            &&
            strcmp(game1->strAdImageOk.c_str(),"") != 0
            &&
            strcmp(game1->strAdImageCancel.c_str(),"") != 0) {
            
            m_vecImagePathList.push_back(game1->strAdImage);
            m_vecImagePathList.push_back(game1->strAdImageOk);
            m_vecImagePathList.push_back(game1->strAdImageCancel);
        }
    }
    
    if (m_vecImagePathList.size() > 0) {
        BeginDowndloadImage();
    }
}

tagMOREGAMEINFO GeneralizeServer::isExsitedAdImage()
{
    
    if (m_GameAppIdVec.size() > 0) {
        m_nAdIndex = 0;
        while (m_nAdIndex < m_GameAppIdVec.size()){
            auto iterImage = m_MoreGameInfoMap.find(m_GameAppIdVec[m_nAdIndex]);
            if (isImageExsit(iterImage->second.strAdImage)
                &&
                isImageExsit(iterImage->second.strAdImageOk)
                &&
                isImageExsit(iterImage->second.strAdImageCancel)
                ) {
                return iterImage->second;
            }else{
                if (strcmp(iterImage->second.strAdImage.c_str(),"") != 0
                    &&
                    strcmp(iterImage->second.strAdImageOk.c_str(),"") != 0
                    &&
                    strcmp(iterImage->second.strAdImageCancel.c_str(),"") != 0) {
                    
                    m_vecImagePathList.push_back(iterImage->second.strAdImage);
                    m_vecImagePathList.push_back(iterImage->second.strAdImageOk);
                    m_vecImagePathList.push_back(iterImage->second.strAdImageCancel);
                }
                if (m_vecImagePathList.size() > 0) {
                    BeginDowndloadImage();
                }
            }
            m_nAdIndex++;
        }
    }
    tagMOREGAMEINFO adInfo;
    adInfo.nGameId = -99;
    return adInfo;
}

tagMOREGAMEINFO* GeneralizeServer::GetMoreGameInfo()
{
    if (m_GameAppIdVec.size() > 0) {
        if (m_Index >= m_GameAppIdVec.size()) {
            m_Index = 0;
        }
        auto iter = m_MoreGameInfoMap.find(m_GameAppIdVec[m_Index]);
        m_Index++;
        if (iter != m_MoreGameInfoMap.end()) {
            tagMOREGAMEINFO* game1 = &(iter->second);
            if (strcmp(game1->strIconButton.c_str(),"") != 0
                &&
                strcmp(game1->strImagePath.c_str(),"") != 0) {
                
                m_vecImagePathList.push_back(game1->strIconButton);
                m_vecImagePathList.push_back(game1->strImagePath);
            }
            
            BeginDowndloadImage();
            return game1;
        }
        
    }
    
    //对游戏信息分别判断选择展示哪个游戏
    return nullptr;
}

bool GeneralizeServer::ReadJson(std::string jsonStr, tagMOREGAMEINFO &info)
{
    return true;
}

bool GeneralizeServer::isDifferentInfo(tagMOREGAMEINFO line, tagMOREGAMEINFO local)
{
    if (strcmp(line.strPackage.c_str(), local.strPackage.c_str()) != 0) {
        return true;
    }
    if (strcmp(line.strSchemes.c_str(), local.strSchemes.c_str()) != 0) {
        return true;
    }
    if (strcmp(line.strDownloadUrl.c_str(), local.strDownloadUrl.c_str()) != 0) {
        return true;
    }
    if (strcmp(line.strGameName.c_str(), local.strGameName.c_str()) != 0) {
        return true;
    }
    if (strcmp(line.strIconPath.c_str(), local.strIconPath.c_str()) != 0) {
        //删除之前的图片，下载新的图片
        m_vecImagePathList.push_back(line.strIconPath);
        m_remvoeImagePathVec.push_back(local.strIconPath);
        return true;
    }
    if (strcmp(line.strIconButton.c_str(), local.strIconButton.c_str()) != 0) {
        //删除之前的图片，下载新的图片
        m_vecImagePathList.push_back(line.strIconButton);
        m_remvoeImagePathVec.push_back(local.strIconButton);
        return true;
    }
    if (strcmp(line.strImagePath.c_str(), local.strImagePath.c_str()) != 0) {
        //删除之前的图片，下载新的图片
        m_vecImagePathList.push_back(line.strImagePath);
        m_remvoeImagePathVec.push_back(local.strImagePath);
        return true;
    }
    
    if (strcmp(line.strAdImage.c_str(), local.strAdImage.c_str()) != 0) {
        //删除之前的图片，下载新的图片
        m_vecImagePathList.push_back(line.strAdImage);
        m_remvoeImagePathVec.push_back(local.strAdImage);
        return true;
    }
    if (strcmp(line.strAdImageOk.c_str(), local.strAdImageOk.c_str()) != 0) {
        //删除之前的图片，下载新的图片
        m_vecImagePathList.push_back(line.strAdImageOk);
        m_remvoeImagePathVec.push_back(local.strAdImageOk);
        return true;
    }
    if (strcmp(line.strAdImageCancel.c_str(), local.strAdImageCancel.c_str()) != 0) {
        //删除之前的图片，下载新的图片
        m_vecImagePathList.push_back(line.strAdImageCancel);
        m_remvoeImagePathVec.push_back(local.strAdImageCancel);
        return true;
    }
    
    BeginRemoveImage();
    return false;
}


int GeneralizeServer::CompareCode(const char *code)
{
    if (strcmp(code, "000000") == 0) {
        return 1;
    }else if (strcmp(code, "ME0001") == 0) {
        log("互推机制:Waring:缺少appid");
        return 0;
    }else if (strcmp(code, "ME0002") == 0) {
        log("互推机制:Waring:缺少language");
        return 0;
    }else if (strcmp(code, "ME0003") == 0) {
        log("互推机制:Waring:缺少udid");
        return 0;
    }else if (strcmp(code, "ME0004") == 0) {
        log("互推机制:Waring:缺少recommendedAppid");
        return 0;
    }else if (strcmp(code, "ME0005") == 0) {
        log("互推机制:Waring:缺少operatingSystem");
        return 0;
    }else if (strcmp(code, "ME0006") == 0) {
        log("互推机制:Waring:缺少奖励值参数");
        return 0;
    }else if (strcmp(code, "EE0001") == 0) {
        log("互推机制:Waring:解析错误");
        return 0;
    }else if (strcmp(code, "EE0002") == 0) {
        log("互推机制:Waring:appid 未知");
        return 0;
    }else if (strcmp(code, "EE0003") == 0) {
        log("互推机制:Waring:recommendappid 未知");
        return 0;
    }else if (strcmp(code, "RE0001") == 0) {
        log("互推机制:Waring:查询没有结果");
        return 0;
    }else if (strcmp(code, "RE0002") == 0) {
        log("互推机制:Waring:新游戏已安装");
        return 0;
    }else if (strcmp(code, "RE0003") == 0) {
        log("互推机制:Waring:游戏未激活");
        return 0;
    }else if (strcmp(code, "OL0001") == 0) {
        log("互推机制:Waring:appid 过长");
        return 0;
    }else if (strcmp(code, "OL0002") == 0) {
        log("互推机制:Waring:language 过长");
        return 0;
    }else if (strcmp(code, "OL0003") == 0) {
        log("互推机制:Waring:udid 过长");
        return 0;
    }else if (strcmp(code, "OL0004") == 0) {
        log("互推机制:Waring:recommendappid 过长");
        return 0;
    }else if (strcmp(code, "OL0005") == 0) {
        log("互推机制:Waring:operatingSystem 过长");
        return 0;
    }else if (strcmp(code, "E99999") == 0) {
        log("互推机制:Error:系统错误");
        return 0;
    }else{
        log("互推机制:没有对应的code");
        return 0;
    }
    return 0;
}



void GeneralizeServer::getVectorDataFormJson()
{
    std::string filepath = (FileUtils::getInstance()->getWritablePath() + "gameinfov2.json");
    Data filedata = FileUtils::getInstance()->getDataFromFile(filepath);
    //json文件如果没有数据，就不处理
    if (filedata.getBytes() != NULL) {
        std::string _StrJson((const char*)filedata.getBytes(), filedata.getSize());
        rapidjson::Document _doc;
        _doc.Parse<0>(_StrJson.c_str());
        if(!_doc.IsObject()){
            return;
        }
        if(!_doc.HasMember("recommendIdList")){
            return;
        }
        // 通过[]取成员值,再根据需要转为array,int,double,string
        const rapidjson::Value &pIdList = _doc["recommendIdList"];
        //是否是数组
        if(!pIdList.IsArray()){
            return;
        }
        for (rapidjson::SizeType i = 0; i < pIdList.Size(); i++)
        {
            const rapidjson::Value &valueEnt = pIdList[i];
            const char* strAppID = valueEnt.GetString();
            //添加展示游戏列表
            m_GameAppIdVec.push_back(strAppID);
        }
        
        //是否有此成员
        if(!_doc.HasMember("gameInfoList")){
            return;
        }
        // 通过[]取成员值,再根据需要转为array,int,double,string
        const rapidjson::Value &pArray = _doc["gameInfoList"];
        //是否是数组
        if(!pArray.IsArray()){
            return;
        }
        for (rapidjson::SizeType i = 0; i < pArray.Size(); i++)
        {
            const rapidjson::Value &valueEnt = pArray[i];
            if(valueEnt.HasMember("gameInfoId") &&
               valueEnt.HasMember("operatingSystem") && valueEnt.HasMember("language") &&
               valueEnt.HasMember("appId") && valueEnt.HasMember("packageName") &&
               valueEnt.HasMember("schemes") && valueEnt.HasMember("downloadUrl") &&
               valueEnt.HasMember("name") && valueEnt.HasMember("fullIcon") &&
               valueEnt.HasMember("fullImagePath") && valueEnt.HasMember("fullIconButton"))
            {
                tagMOREGAMEINFO game1;
                game1.nGameId = i;
                
                const rapidjson::Value &gameInfoId = valueEnt["gameInfoId"];
                int nGameInfoId = gameInfoId.GetInt();//得到int值
                game1.nGameInfoId = nGameInfoId;
                
                const rapidjson::Value &operatingSystem = valueEnt["operatingSystem"];
                const char* sOperatingSystem = operatingSystem.GetString();
                game1.strSystem = sOperatingSystem;
                
                const rapidjson::Value &language = valueEnt["language"];
                const char* sLanguage = language.GetString();
                game1.strLanguage = sLanguage;
                
                const rapidjson::Value &appid = valueEnt["appId"];
                const char* sAppid = appid.GetString();
                game1.strAppId = sAppid;
                
                const rapidjson::Value &packageName = valueEnt["packageName"];
                const char* sPackageName = packageName.GetString();
                game1.strPackage = sPackageName;
                
                const rapidjson::Value &schemes = valueEnt["schemes"];
                const char* sSchemes = schemes.GetString();
                game1.strSchemes = sSchemes;
                
                const rapidjson::Value &downloadUrl = valueEnt["downloadUrl"];
                const char* sDownloadUrl = downloadUrl.GetString();
                game1.strDownloadUrl = sDownloadUrl;
                
                const rapidjson::Value &name = valueEnt["name"];
                const char* sName = name.GetString();
                game1.strGameName = sName;
                
                const rapidjson::Value &icon = valueEnt["fullIcon"];
                const char* sIcon = icon.GetString();
                game1.strIconPath = sIcon;
                
                const rapidjson::Value &iconButton = valueEnt["fullIconButton"];
                const char* sIconButton = iconButton.GetString();
                game1.strIconButton = sIconButton;
                
                const rapidjson::Value &image = valueEnt["fullImagePath"];
                const char* sImagePath = image.GetString();
                game1.strImagePath = sImagePath;
                
                const rapidjson::Value &checkExsited = valueEnt["isExsited"];
                bool isExsited = checkExsited.GetBool();
                game1.isExsited = isExsited;
                
                if (valueEnt.HasMember("adImage")) {
                    const rapidjson::Value &adImageEnt = valueEnt["adImage"];
                    const char* sAdImage = adImageEnt.GetString();
                    game1.strAdImage = sAdImage;
                }
                
                if (valueEnt.HasMember("adImageOK")) {
                    const rapidjson::Value &adImageOKEnt = valueEnt["adImageOK"];
                    const char* sAdImageOK = adImageOKEnt.GetString();
                    game1.strAdImageOk = sAdImageOK;
                }
                
                if (valueEnt.HasMember("adImageCancel")) {
                    const rapidjson::Value &adImageCancelEnt = valueEnt["adImageCancel"];
                    const char* sAdImageCancel = adImageCancelEnt.GetString();
                    game1.strAdImageCancel = sAdImageCancel;
                }
                
                //看看之前是不是有过这个游戏的信息
                auto iter = m_MoreGameInfoMap.find(game1.strAppId);
                if (iter == m_MoreGameInfoMap.end()) {
                    m_MoreGameInfoMap.insert(std::make_pair(game1.strAppId, game1));
                }
            }else{
                log("互推机制:获取推荐游戏信息不全？");
            }
        }
    }
}

void GeneralizeServer::saveJsonDataFormVector()
{
    rapidjson::Document _doc;
    _doc.SetObject();
    rapidjson::Document::AllocatorType& allocator = _doc.GetAllocator();
    //展示的游戏id列表
    rapidjson::Value recommendIDList(rapidjson::kArrayType);
    for (int index =0; index < m_GameAppIdVec.size(); index++) {
        std::string strAppId = m_GameAppIdVec.at(index);
        rapidjson::Value gameAppID(rapidjson::kStringType);
        gameAppID.SetString(strAppId.c_str(),strAppId.size(),allocator);
        recommendIDList.PushBack(gameAppID, allocator);
    }
    _doc.AddMember("recommendIdList", recommendIDList, allocator);
    
    //已知的推荐游戏信息
    rapidjson::Value moreGameInfoList(rapidjson::kArrayType);
    for (auto &iter : m_MoreGameInfoMap) {
        tagMOREGAMEINFO info = iter.second;
        rapidjson::Value valueEnt(rapidjson::kObjectType);

        valueEnt.AddMember("gameInfoId", info.nGameInfoId, allocator);
        rapidjson::Value gameAppID(rapidjson::kStringType);
        gameAppID.SetString(info.strAppId.c_str(),info.strAppId.size(),allocator);
        valueEnt.AddMember("appId", gameAppID, allocator);
        rapidjson::Value curSystem(rapidjson::kStringType);
        curSystem.SetString(info.strSystem.c_str(),info.strSystem.size(),allocator);
        valueEnt.AddMember("operatingSystem", curSystem, allocator);
        rapidjson::Value curLanguage(rapidjson::kStringType);
        curLanguage.SetString(info.strLanguage.c_str(),info.strLanguage.size(),allocator);
        valueEnt.AddMember("language", curLanguage, allocator);
        rapidjson::Value curPackage(rapidjson::kStringType);
        curPackage.SetString(info.strPackage.c_str(),info.strPackage.size(),allocator);
        valueEnt.AddMember("packageName", curPackage, allocator);
        rapidjson::Value curSchemes(rapidjson::kStringType);
        curSchemes.SetString(info.strSchemes.c_str(),info.strSchemes.size(),allocator);
        valueEnt.AddMember("schemes", curSchemes, allocator);
        rapidjson::Value curDownLoadUlr(rapidjson::kStringType);
        curDownLoadUlr.SetString(info.strDownloadUrl.c_str(),info.strDownloadUrl.size(),allocator);
        valueEnt.AddMember("downloadUrl", curDownLoadUlr, allocator);
        rapidjson::Value curGameName(rapidjson::kStringType);
        curGameName.SetString(info.strGameName.c_str(),info.strGameName.size(),allocator);
        valueEnt.AddMember("name", curGameName, allocator);
        rapidjson::Value curIconPath(rapidjson::kStringType);
        curIconPath.SetString(info.strIconPath.c_str(),info.strIconPath.size(),allocator);
        valueEnt.AddMember("fullIcon", curIconPath, allocator);
        rapidjson::Value curIconButton(rapidjson::kStringType);
        curIconButton.SetString(info.strIconButton.c_str(),info.strIconButton.size(),allocator);
        valueEnt.AddMember("fullIconButton", curIconButton, allocator);
        rapidjson::Value curImagePath(rapidjson::kStringType);
        curImagePath.SetString(info.strImagePath.c_str(),info.strImagePath.size(),allocator);
        valueEnt.AddMember("fullImagePath", curImagePath, allocator);
        rapidjson::Value adImageEnt(rapidjson::kStringType);
        adImageEnt.SetString(info.strAdImage.c_str(),info.strAdImage.size(),allocator);
        valueEnt.AddMember("adImage", adImageEnt, allocator);
        rapidjson::Value adImageOkEnt(rapidjson::kStringType);
        adImageOkEnt.SetString(info.strAdImageOk.c_str(),info.strAdImageOk.size(),allocator);
        valueEnt.AddMember("adImageOK", adImageOkEnt, allocator);
        rapidjson::Value adImageCancelEnt(rapidjson::kStringType);
        adImageCancelEnt.SetString(info.strAdImageCancel.c_str(),info.strAdImageCancel.size(),allocator);
        valueEnt.AddMember("adImageCancel", adImageCancelEnt, allocator);
        valueEnt.AddMember("isExsited", info.isExsited, allocator);
        
        moreGameInfoList.PushBack(valueEnt, allocator);
    }
    _doc.AddMember("gameInfoList", moreGameInfoList, allocator);
    
    WriteGameInfo(_doc);
}




