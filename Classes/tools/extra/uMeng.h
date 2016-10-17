//
//  uMeng.hpp
//  sdkIOSDemo
//
//  Created by JustinYang on 16/10/15.
//
//

#ifndef uMeng_hpp
#define uMeng_hpp

#include <stdio.h>


class uMeng
{
public:
    static void initUmeng();
    //玩家支付货币兑换虚拟币,用于统计游戏的收入情况
    static void uMengPayCoin(double cash, int source, double coin);
    //玩家用虚拟币兑换一定数量、价值的道具
    static void uMengPayProps(double cash, int source, std::string item, int amount, double price);
    static void uMengBuyProps(std::string item, int amount, double price);
    //玩家使用道具的情况
    static void uMengUseProps(std::string item, int amount, double price);
    //记录玩家在游戏中的进度
    static void uMengStartLevel(std::string level);
    static void uMengFinishLevel(std::string level);
    static void uMengFailLevel(std::string level);
    //针对游戏中额外获得的虚拟币进行统计，比如系统赠送，节日奖励，打怪掉落。
    static void uMengBonusCoin(double coin, int source);
    static void uMengBonusPorps(std::string item, int amount, double price, int source);
    //当玩家建立角色或者升级时，需调用此接口
    static void uMengUserLevel(int level);
    static void uMengPageInfo(std::string page);
};

#endif /* uMeng_hpp */
