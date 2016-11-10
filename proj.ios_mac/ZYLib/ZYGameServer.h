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

- (void)loadGameServer;

- (void)loadDataFromDb:(sqlite3*)db;

- (void)jumpToDownload:(NSString*)pushZyno;

- (void)setAward:(awardBack)show andGive:(awardBack)give;

- (void)statisticsApp:(NSDictionary*)jsonData;

- (void)registerTest;

- (NSArray*)getGameZynoArray;

- (NSArray*)getDefaultArray;

- (NSDictionary*)getGameInfoDic;

/**
 *展示log
 */
- (void)showLog;

@end
