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

@property (nonatomic, retain) NSMutableDictionary* adGameInfoDic;   //推荐的更多游戏
@property (nonatomic, retain) NSMutableDictionary* rewardInfoDic;   //奖励的列表
@property (nonatomic, retain) NSMutableArray* adGameZynoArray;      //推荐的zyno列表
@property (nonatomic, retain) NSMutableArray* adDisableImg;         //删除的图片列表
@property (nonatomic, retain) NSMutableArray* adDefaultArray;       //默认列表的zyno
@property (nonatomic, retain) NSMutableArray* adLoadImgArray;       //图片下载列表
@property (nonatomic, retain) NSString* adGameRic;                  //领取奖励的ric拼接字符串


+ (ZYGameServer*)shareServer;

- (void)loadGameServer;

- (void)loadDataFromDb:(sqlite3*)db;

- (void)jumpToDownload:(NSString*)pushZyno;

- (void)setAward:(awardBack)show andGive:(awardBack)give;

- (void)statisticsApp:(NSDictionary*)jsonData;

- (void)registerTest;

/**
 *展示log
 */
- (void)showLog;

@end
