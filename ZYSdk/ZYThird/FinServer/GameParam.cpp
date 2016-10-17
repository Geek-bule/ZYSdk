//
//  GameParam.cpp
//  CookieCrush
//
//  Created by JustinYang on 16/5/9.
//
//

#include "GameParam.hpp"

USING_NS_CC;
USING_NS_CC_EXT;
using namespace network;


#define HTTP_GAMEPARAM          "http://114.215.118.143:6601/ZYGameServer/app/v1/gameParam/"






void GameParam::loadParamFromServer(const char *gamekey, const ccParamCallBack &call)
{
    if (strcmp(gamekey,"") == 0) {
        MessageBox("在线参数gamekey不能为空", "Error");
        return ;
    }
    m_callBack = call;
    SendGameParamRequest(gamekey);
}


std::string GameParam::getParam(std::string key)
{
    auto iter = m_gameParamMap.find(key);
    if (iter != m_gameParamMap.end()) {
        return iter->second;
    }
    return "";
}

int  GameParam::getParamInt(std::string key)
{
    std::string strParam = "";
    auto iter = m_gameParamMap.find(key);
    if (iter != m_gameParamMap.end()) {
        strParam = iter->second;
    }
    int nParam = atoi(strParam.c_str());
    return nParam;
}


float  GameParam::getParamFloat(std::string key)
{
    std::string strParam = "";
    auto iter = m_gameParamMap.find(key);
    if (iter != m_gameParamMap.end()) {
        strParam = iter->second;
    }
    float nParam = atof(strParam.c_str());
    return nParam;
}



//获取在线参数
void GameParam::SendGameParamRequest(const char *gamekey)
{
    HttpRequest* request = new HttpRequest();
    request->setUrl(__String::createWithFormat("%s%s",HTTP_GAMEPARAM,gamekey)->getCString());
    request->setRequestType(HttpRequest::Type::GET);
    request->setResponseCallback(CC_CALLBACK_2(GameParam::GetGameParamResponse, this));
    
    log("LogicServer--SendGameParam: %s",HTTP_GAMEPARAM);
    HttpClient::getInstance()->send(request);
    HttpClient::getInstance()->setTimeoutForConnect(5);
    HttpClient::getInstance()->setTimeoutForRead(5);
    request->release();
}

void GameParam::GetGameParamResponse(HttpClient *sender, HttpResponse *response)
{
    if (!response)
    {
        log("在线参数::接收返回消息失败");
        return;
    }
    
    int statusCode = response->getResponseCode();
    char statusString[64] = {};
    sprintf(statusString, "HTTP Status Code: %d", statusCode);
    log("在线参数::%s", statusString);
    if (!response->isSucceed())
    {
        log("在线参数::response failed");
        log("在线参数::error buffer: %s", response->getErrorBuffer());
        return;
    }
    
    // dump data
    std::vector<char> *buffer = response->getResponseData();
    std::string getbuffer(buffer->begin(),buffer->end());
    std::string load_str((const char*)getbuffer.c_str(), buffer->size());
    log("在线参数:: %s",load_str.c_str());
    
    //参数处理
    rapidjson::Document _doc;
    _doc.Parse<0>(load_str.c_str());
    if(!_doc.IsObject()){
        return;
    }
    rapidjson::Value &codeEnt = _doc["code"];
    if (codeEnt.IsInt()) {
        int nCode = codeEnt.GetInt();
        if (nCode == 0) {
            rapidjson::Value &paramListEnt = _doc["dataList"];
            if (paramListEnt.IsArray()) {
                for (int nIndex = 0; nIndex < paramListEnt.Size(); nIndex++) {
                    rapidjson::Value &paramEnt = paramListEnt[nIndex];
                    rapidjson::Value &nameEnt = paramEnt["name"];
                    rapidjson::Value &valueEnt = paramEnt["value"];
                    if (nameEnt.IsString() && valueEnt.IsString()) {
                        std::string strName = nameEnt.GetString();
                        std::string strValue = valueEnt.GetString();
                        m_gameParamMap.insert(std::make_pair(strName, strValue));
                    }
                }
                if (m_callBack) {
                    m_callBack(m_gameParamMap);
                    UserDefault::getInstance()->setStringForKey(ADVIEWIDKey, getParam(ADVIEWIDKey));
                }
            }
        }
    }
}




