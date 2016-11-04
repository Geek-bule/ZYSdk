//
//  ZYAdStatistics.h
//  sdkIOSDemo
//
//  Created by JustinYang on 16/9/27.
//
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#define button_show             1
#define button_click            2
#define image_show              3
#define image_click             4


@interface ZYAdStatistics : NSObject


+ (ZYAdStatistics*)shareStatistics;

- (void)statistics:(NSString*)zyno andKey:(NSString*)recordKey;

- (NSDictionary*)loadDataFromDb:(sqlite3*)db andDate:(NSString*)date;

- (void)setSqlite:(sqlite3*)db;

@end
