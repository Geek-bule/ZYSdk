//
//  ZYAdStatistics.h
//  sdkIOSDemo
//
//  Created by JustinYang on 16/9/27.
//
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>


@interface ZYAdStatistics : NSObject


+ (ZYAdStatistics*)shareStatistics;

/**
 *  @brief  统计的数据
 *  @param  zyno    统计的zyno
 *  @param  recordKey   统计的类型
 */
- (void)statistics:(NSString*)zyno andKey:(NSString*)recordKey;

/**
 *  @brief  读取统计数据
 *  @param  db    db
 *  @param  date    日期
 */
- (NSDictionary*)loadDataFromDb:(sqlite3*)db andDate:(NSString*)date;

/**
 *  @brief  设定db
 *  @param  db    db
 */
- (void)setSqlite:(sqlite3*)db;

@end
