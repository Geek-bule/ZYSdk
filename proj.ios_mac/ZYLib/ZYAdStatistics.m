//
//  ZYAdStatistics.m
//  sdkIOSDemo
//
//  Created by JustinYang on 16/9/27.
//
//

#import "ZYAdStatistics.h"
#import "AFNetworking.h"
#import "ZYParamOnline.h"
#import "ZYGameServer.h"




#define ZY_URL_STATISTICS       @"ZYGameServer/app/v1/statistics"



@interface ZYAdStatistics()
{
    sqlite3 *_db;
}

@property (nonatomic,assign) int buttonShowCount;
@property (nonatomic,assign) int buttonClickCount;
@property (nonatomic,assign) int imageShowCount;
@property (nonatomic,assign) int imageClickCount;
@property (nonatomic,retain) NSMutableDictionary *statisticsDic;
@property (nonatomic,retain) NSString *nowDate;

@end

@implementation ZYAdStatistics

+ (ZYAdStatistics*)shareStatistics
{
    static ZYAdStatistics* s_share = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_share = [[ZYAdStatistics alloc] init];
    });
    return s_share;
}


- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)setSqlite:(sqlite3*)db
{
    _db = db;
    
    NSDate *currentDate = [NSDate date];//获取当前时间，日期
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYYMMdd"];
    _nowDate = [dateFormatter stringFromDate:currentDate];
    _statisticsDic = [[NSMutableDictionary alloc] initWithDictionary:[self loadDataFromDb:_db andDate:_nowDate]];
    [self updateStatisticsDate:dateFormatter];
}

- (void)updateStatisticsDate:(NSDateFormatter*)dateFormatter
{
    //每隔七天要进行一次数据上传，上传成功之后要清空数据库
    NSString *storeDate = [[NSUserDefaults standardUserDefaults] objectForKey:ZYSTORE_DATE];
    if (!storeDate) {
        storeDate = _nowDate;
        [[NSUserDefaults standardUserDefaults] setObject:storeDate forKey:ZYSTORE_DATE];
    }
    NSDate *dateFromString = [dateFormatter dateFromString:storeDate];
    NSDate *dateToString = [dateFormatter dateFromString:_nowDate];
    int timediff = [dateToString timeIntervalSince1970]-[dateFromString timeIntervalSince1970];
    if (timediff >= 7*24*60*60) {
        NSDictionary* statisDic = [self loadDataFromDb:_db andDate:nil];
        if (statisDic && [statisDic count] != 0) {
            NSMutableArray* statisArray = [[NSMutableArray alloc] init];
            for (NSString* key in statisDic) {
                NSDictionary *dicRecord = statisDic[key];
                [statisArray addObject:dicRecord];
            }
            NSMutableDictionary* jsonDic = [[NSMutableDictionary alloc] init];
            [jsonDic setObject:statisArray forKey:@"dataList"];
            NSString* zyid = [[ZYParamOnline shareParam] getConfigValueFromKey:@"zongyi_key"];
            [jsonDic setObject:zyid forKey:@"zyno"];
            [[ZYGameServer shareServer] statisticsApp:jsonDic];
        }
    }
}


- (void)statistics:(NSString *)zyno andKey:(NSString *)recordKey
{
        NSDate *currentDate = [NSDate date];//获取当前时间，日期
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"YYYYMMdd"];
        NSString *dateString = [dateFormatter stringFromDate:currentDate];
        
        if (![_nowDate isEqualToString:dateString]) {
            _nowDate = dateString;
            [_statisticsDic removeAllObjects];
            //load data from db(似乎不用，第二天的数据不可能有，有的话只能说明玩家修改手机时间了)
        }
    
        if (_statisticsDic.count > 0) {
            //update record data
            NSMutableDictionary *record = [[NSMutableDictionary alloc] initWithDictionary:[_statisticsDic objectForKey:zyno]]; ;
            NSNumber *number = record[recordKey];
            NSNumber* addNumber = [NSNumber numberWithInt:number.intValue+1];
            [record setValue:addNumber forKey:recordKey];
            [_statisticsDic setObject:record forKey:zyno];
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:record
                                                               options:NSJSONWritingPrettyPrinted
                                                                 error:nil];
            NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            //存储
            NSString* sql = [NSString stringWithFormat:@"update statistics set record = '%@' where zyno = '%@' and date = '%@'",jsonString,zyno,_nowDate];
            [self execSql:sql andClose:YES];
        }else{
            //insert record data
            NSMutableDictionary *record = [[NSMutableDictionary alloc] init];
            [record setObject:zyno forKey:@"pushZyno"];
            [record setObject:_nowDate forKey:@"date"];
            [record setObject:[NSNumber numberWithInt:0] forKey:@"iconShow"];
            [record setObject:[NSNumber numberWithInt:0] forKey:@"iconClick"];
            [record setObject:[NSNumber numberWithInt:0] forKey:@"imgShow"];
            [record setObject:[NSNumber numberWithInt:0] forKey:@"imgClick"];
            
            [record setValue:[NSNumber numberWithInt:1] forKey:recordKey];
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:record
                                                               options:NSJSONWritingPrettyPrinted
                                                                 error:nil];
            NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            
            [_statisticsDic setObject:record forKey:zyno];
            //存储
            NSString* sql = [NSString stringWithFormat:@"INSERT INTO statistics VALUES ('%@','%@','%@')",zyno,_nowDate,jsonString];
            [self execSql:sql andClose:YES];
        }
    
}


-(void)execSql:(NSString *)sql andClose:(BOOL)close
{
    char *err;
    if (sqlite3_exec(_db, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK) {
        NSLog(@"数据统计：数据库操作数据失败!sql:%s",[sql UTF8String]);
    }
}




- (NSDictionary*)loadDataFromDb:(sqlite3*)db andDate:(NSString*)date
{
    NSString *sqlQuery;
    if (date) {
        sqlQuery = [NSString stringWithFormat:@"SELECT * FROM statistics WHERE date = '%@'",date];
    }else{
        sqlQuery = @"SELECT * FROM statistics";
    }
    sqlite3_stmt * statement;
    NSMutableDictionary* statisticsDic = [[NSMutableDictionary alloc] init];
    if (sqlite3_prepare_v2(db, [sqlQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            
            char *zyno = (char*)sqlite3_column_text(statement, 0);
            NSString*zynoLoad = [[NSString alloc]initWithUTF8String:zyno];
            
            char *date = (char*)sqlite3_column_text(statement, 1);
            NSString*dateLoad = [[NSString alloc]initWithUTF8String:date];
            
            char *record = (char*)sqlite3_column_text(statement, 2);
            NSString*recordLoad = [[NSString alloc]initWithUTF8String:record];
            NSData *resData = [[NSData alloc] initWithData:[recordLoad dataUsingEncoding:NSUTF8StringEncoding]];
            NSDictionary *dicRecord = [NSJSONSerialization JSONObjectWithData:resData options:NSJSONReadingMutableLeaves error:nil];
        
            if (date) {
                [statisticsDic setObject:dicRecord forKey:zynoLoad];
            }else{
                [statisticsDic setObject:dicRecord forKey:[NSString stringWithFormat:@"%@%@",zynoLoad,dateLoad]];
            }
            
        }
        NSLog(@"互推：本地数据库statistics读取成功");
    }
    return statisticsDic;
}





@end
