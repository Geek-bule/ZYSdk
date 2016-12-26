//
//  GameServer.h
//  sdkIOSDemo
//
//  Created by JustinYang on 16/8/24.
//
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#define ZYSTORE_DATE            @"zongyistatistics"

typedef void (^tokenBack)(NSString* token);
typedef void (^awardBack)(NSArray* awardDic);


@interface ZYGameServer : NSObject



+ (ZYGameServer*)shareServer;

/**
 *  @brief  获取服务器互推配置
 */
- (void)loadGameServer;

/**
 *  @brief  读取本地互推数据
 *  @param  db        sqlite的db
 */
- (void)loadDataFromDb:(sqlite3*)db;

/**
 *  @brief  跳转下载链接
 *  @param  pushZyno        被推送的zyno
 */
- (void)jumpToDownload:(NSString*)pushZyno;

/**
 *  @brief  设置奖励的回调
 *  @param  show        设定玩家将要获得的奖励列表的回调，只是展示不给奖励
 *  @param  give        设定玩家获得的奖励列表的回调，展示并给奖励
 */
- (void)setAward:(awardBack)show andGive:(awardBack)give;

/**
 *  @brief  发送统计数据
 *  @param  jsonData        统计数据的json 结构
 */
- (void)statisticsApp:(NSDictionary*)jsonData;

/**
 *  @brief  测试在线注册
 */
- (void)registerTest;

/**
 *  @brief
 *  @return  返回所有互推列表zyno
 */
- (NSArray*)getGameZynoArray;


/**
 *  @brief
 *  @return  返回所有默认列表zyno
 */
- (NSArray*)getDefaultArray;

/**
 *  @brief
 *  @param  返回所有互推游戏的信息
 */
- (NSDictionary*)getGameInfoDic;

/**
 *  @brief  展示log
 */
- (void)showLog;

@end
