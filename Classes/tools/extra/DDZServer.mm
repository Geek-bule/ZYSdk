//
//  DDZServer.cpp
//  sdkIOSDemo
//
//  Created by JustinYang on 16/11/21.
//
//

#include "DDZServer.h"
#include "MD5.h"
#include "ZYParamOnline.h"
#include "OpenUDID.h"

#include "network/HttpClient.h"
using namespace network;

#include "json/document.h"
#include "json/writer.h"
#include "json/stringbuffer.h"
#include <algorithm>
#include <string>
#include <cctype>


#define ZYID_NO                     "1c15e1e3b6bd4731a68d0d7ded717294"
#define ZYID_KEY                    "abc123"

#define ZYHTTP_HOST                 "http://www.zongyiplay.com:6601"
#define ZYHTTP_URL_RECORD           "/ZYDouDiZhu/app/v1/record"








void DDZServer::SendRecordRequest()
{
    HttpRequest* request = new HttpRequest();
    // 设置url
    string httpHost = ZYHTTP_HOST;
    httpHost+=ZYHTTP_URL_RECORD;
    // write the post data
    map<string,string> postMap;
    postMap.insert(std::pair<string,string>("nonce", generateTradeNO()));
    postMap.insert(std::pair<string,string>("created", getCurrentTime()));
    string postData = createMD5Sign(postMap);
    httpHost=httpHost+"?"+postData;
    request->setUrl(httpHost.c_str());
    //add header
    request->setHeaders(addHeader());
    request->setRequestType(HttpRequest::Type::GET);
    request->setResponseCallback([&](HttpClient *sender, HttpResponse *response){
        if (response) {
            int statusCode = (int)response->getResponseCode();
            if (response->isSucceed() && statusCode == 200){
                // dump data
                std::vector<char> *buffer = response->getResponseData();
                std::string getbuffer(buffer->begin(),buffer->end());
                std::string load_str((const char*)getbuffer.c_str(), buffer->size());
                //
                rapidjson::Document _doc;
                _doc.Parse<0>(load_str.c_str());
                log("SendRecordRequest: %s",load_str.c_str());
                if(_doc.IsObject()){
                    rapidjson::Value &codeEnt = _doc["code"];
                    int nCode = codeEnt.GetInt();
                    if (nCode == 0) {
                        if (_doc.HasMember("playCount") &&
                            _doc.HasMember("playLimitCount") &&
                            _doc.HasMember("rewardCount") &&
                            _doc.HasMember("rewardLimitCount") ) {
                            rapidjson::Value &playCountEnt = _doc["playCount"];
                            int nPlayCount = playCountEnt.GetInt();

                            rapidjson::Value &playLimitCountEnt = _doc["playLimitCount"];
                            int nPlayLimitCount = playLimitCountEnt.GetInt();

                            rapidjson::Value &rewardCountEnt = _doc["rewardCount"];
                            int nRewardCount = rewardCountEnt.GetInt();

                            rapidjson::Value &rewardLimitCountEnt = _doc["rewardLimitCount"];
                            int nRewardLimitCount = rewardLimitCountEnt.GetInt();
                        }
                    }else{
                        rapidjson::Value &messageEnt = _doc["message"];
                        const char *strMessage = messageEnt.GetString();
                        log("SendRecordRequest: %s", strMessage);
                    }
                }
            }else{
                log("SendRecordRequest:HTTP Status Code %d", statusCode);
            }
        }else{
            log("SendRecordRequest:接收返回消息失败");
        }
    });
    
    log("FriendShipServer--SendGetFriendListRequest: %s",httpHost.c_str());
    HttpClient::getInstance()->send(request);
    HttpClient::getInstance()->setTimeoutForConnect(30);
    HttpClient::getInstance()->setTimeoutForRead(30);
    request->release();
}







DDZServer::DDZServer()
{
    m_Devidfa = [[ZYParamOnline idfaString] UTF8String];
    m_Devidfv = [[ZYParamOnline idfvString] UTF8String];
    m_Devopid = [[OpenUDID value] UTF8String];
}
DDZServer::~DDZServer()
{
    
}

//生成随机数算法 ,随机字符串，不长于32位
string DDZServer::generateTradeNO()
{
    static int kNumber = 15;
    
    NSString *sourceStr = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    
    NSMutableString *resultStr = [[NSMutableString alloc] init];
    
    srand(time(0)); // 此行代码有警告:
    
    for (int i = 0; i < kNumber; i++) {
        
        unsigned index = rand() % [sourceStr length];
        
        NSString *oneStr = [sourceStr substringWithRange:NSMakeRange(index, 1)];
        
        [resultStr appendString:oneStr];
    }
    return [resultStr UTF8String];
}

//创建发起支付时的sign签名
string DDZServer::createMD5Sign(map<string,string> signParams)
{
    string sign = "";
    for (auto iter : signParams) {
        string key = iter.first;
        string value = iter.second;
        sign.append(key);
        sign.append("=");
        sign.append(value);
        sign.append("&");
    }
    
    sign = sign+"key="+ZYID_KEY;
    string signMd5 = md5(sign);
    transform(signMd5.begin(), signMd5.end(), signMd5.begin(), ::toupper);
    string result = sign +"&sign="+signMd5;
    return result;
}

//add header
vector<string> DDZServer::addHeader()
{
    std::vector<std::string> headers;
    //手机唯一标示
    __String *pIdfa = __String::createWithFormat("idfa: %s",m_Devidfa.c_str());
    headers.push_back(pIdfa->getCString());
    //手机唯一标示
    __String *pIdfv = __String::createWithFormat("idfv: %s",m_Devidfv.c_str());
    headers.push_back(pIdfv->getCString());
    //手机唯一标示
    __String *pOpenUdid = __String::createWithFormat("openudid: %s",m_Devopid.c_str());
    headers.push_back(pOpenUdid->getCString());
    //手机唯一标示
    __String *pZyno = __String::createWithFormat("zyno: %s",ZYID_NO);
    headers.push_back(pZyno->getCString());
    return headers;
}

//获取时间
string DDZServer::getCurrentTime()
{
    NSDate *currentDate = [NSDate date];//获取当前时间，日期
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd'T'HH:mm:ss'Z'"];
    NSString*time = [dateFormatter stringFromDate:currentDate];
    return [time UTF8String];
}




