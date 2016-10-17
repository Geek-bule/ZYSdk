//
//  IOSInfo.hpp
//  sdkIOSDemo
//
//  Created by JustinYang on 16/7/8.
//
//

#ifndef IOSInfo_hpp
#define IOSInfo_hpp

#include <stdio.h>
#include "cocos2d.h"

class IOSInfo
{
public:
    //获取本机信息
    static std::string getLanguage();
    static std::string getIdFa();
    static std::string getIdFv();
    static std::string getVersion();
    static std::string getBuild();
    static std::string getUnicode(const char* strChinese);
    static bool canOpenUlr(std::string url);
    static void openUrl(std::string url);
};

#endif /* IOSInfo_hpp */
