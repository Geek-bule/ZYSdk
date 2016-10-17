//
//  GameParam.hpp
//  CookieCrush
//
//  Created by JustinYang on 16/5/9.
//
//

#ifndef GameParam_hpp
#define GameParam_hpp

#include <stdio.h>
#include "cocos2d.h"
#include "network/HttpClient.h"
#include "cocos-ext.h"

#include "json/document.h"
#include "json/writer.h"
#include "json/stringbuffer.h"
#include <iostream>
#include <errno.h>
#include "fstream"

#define ADVIEWIDKey             "adviewidkey"

typedef std::map<std::string,std::string> paramMap;
typedef std::function<void(paramMap)> ccParamCallBack;

class GameParam
{
public:
    static GameParam &getInstance()
    {
        static GameParam instance;
        return instance;
    }
    
    void loadParamFromServer(const char *gamekey,const ccParamCallBack &call);
    std::string getParam(std::string key);
    int         getParamInt(std::string key);
    float       getParamFloat(std::string key);
private:
    //获取在线参数
    void SendGameParamRequest(const char *gamekey);
    void GetGameParamResponse(cocos2d::network::HttpClient *sender, cocos2d::network::HttpResponse *response);
    
    //参数数组
    paramMap m_gameParamMap;
    ccParamCallBack m_callBack;
};



#endif /* GameParam_hpp */
