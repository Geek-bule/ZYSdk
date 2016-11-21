//
//  DDZServer.hpp
//  sdkIOSDemo
//
//  Created by JustinYang on 16/11/21.
//
//

#ifndef DDZServer_hpp
#define DDZServer_hpp

#include <stdio.h>
#include "cocos2d.h"
#include "CCMap.h"
USING_NS_CC;
using namespace std;


class   DDZServer
{
public:
    static DDZServer &getInstance()
    {
        static DDZServer instance;
        return instance;
    }
    
    //查询游戏记录
    void SendRecordRequest();
    
private:
    DDZServer();
    ~DDZServer();
    
    //生成随机数算法 ,随机字符串，不长于32位
    string generateTradeNO();
    
    //创建发起支付时的sign签名
    string createMD5Sign(map<string,string> signParams);
    
    //add header
    vector<string> addHeader();
    
    //system time
    string getCurrentTime();
private:
    string m_Devidfv;
    string m_Devidfa;
    string m_Devopid;
};

#endif /* DDZServer_hpp */
