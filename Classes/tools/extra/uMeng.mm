//
//  uMeng.cpp
//  sdkIOSDemo
//
//  Created by JustinYang on 16/10/15.
//
//

#import "uMeng.h"
#import "ZYParamOnline.h"
#import "MobClick.h"
#import "MobClickGameAnalytics.h"
#import "MobClickSocialAnalytics.h"

void uMeng::initUmeng()
{
    //Umeng sdk
    NSString *umengKey = [[ZYParamOnline shareParam] getConfigValueFromKey:@"umeng_key"];
    NSString *umengChannel = [[ZYParamOnline shareParam] getConfigValueFromKey:@"umeng_channel"];
    [MobClick startWithAppkey:umengKey reportPolicy:BATCH channelId:umengChannel];
}

void uMeng::uMengPayCoin(double cash, int source, double coin)
{

    [MobClickGameAnalytics pay:cash source:source coin:coin];

}

void uMeng::uMengPayProps(double cash, int source, std::string item, int amount, double price)
{

    NSString *_item = [NSString stringWithUTF8String:item.c_str()];
    [MobClickGameAnalytics pay:cash source:source item:_item amount:amount price:price];

}

void uMeng::uMengBuyProps(std::string item, int amount, double price)
{

    NSString *_item = [NSString stringWithUTF8String:item.c_str()];
    [MobClickGameAnalytics buy:_item amount:amount price:price];

}

void uMeng::uMengUseProps(std::string item, int amount, double price)
{

    NSString *_item = [NSString stringWithUTF8String:item.c_str()];
    [MobClickGameAnalytics use:_item amount:amount price:price];

}

void uMeng::uMengStartLevel(std::string level)
{

    NSString *_level = [NSString stringWithUTF8String:level.c_str()];
    [MobClickGameAnalytics startLevel:_level];

}

void uMeng::uMengFinishLevel(std::string level)
{

    NSString *_level = [NSString stringWithUTF8String:level.c_str()];
    [MobClickGameAnalytics finishLevel:_level];

}

void uMeng::uMengFailLevel(std::string level)
{

    NSString *_level = [NSString stringWithUTF8String:level.c_str()];
    [MobClickGameAnalytics failLevel:_level];

}

void uMeng::uMengBonusCoin(double coin, int source)
{

    [MobClickGameAnalytics bonus:coin source:source];

}

void uMeng::uMengBonusPorps(std::string item, int amount, double price, int source)
{

    NSString *_item = [NSString stringWithUTF8String:item.c_str()];
    [MobClickGameAnalytics bonus:_item amount:amount price:price source:source];

}

void uMeng::uMengUserLevel(int level)
{

    [MobClickGameAnalytics setUserLevelId:level];

}

void uMeng::uMengPageInfo(std::string page)
{

    NSString *strLable = [NSString stringWithUTF8String:page.c_str()];
    [MobClick event:@"page" label:strLable];

}


