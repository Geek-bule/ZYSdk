//
//  ParamOnline.m
//  sdkIOSDemo
//
//  Created by JustinYang on 16/8/23.
//
//

#import "ZYParamOnline.h"
#import "ZYGameServer.h"
#import "ZYAlertView.h"


//for idfa
#import <AdSupport/AdSupport.h>
#import <Foundation/Foundation.h>
//for mac
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>




#define DBNAME                          @"zongyi.db"


#define kAppleLookupURLTemplate         @"https://itunes.apple.com/lookup?id=%@"
#define kAppleLookupURLTemplateCn       @"https://itunes.apple.com/cn/lookup?id=%@"



#define ZY_HOST                         @"http://121.42.183.124"//@"http://192.168.1.147"//
#define ZY_PORT                         @"80"//@"8080"//
#define ZY_URL_PARAM                    @"ZYGameServer/app/v1/gameParam"


#define APLog(str, ...)  if(_isShowLog)NSLog(str, ##__VA_ARGS__)


@interface ZYParamOnline()
{
    sqlite3 *db;
    int nAppId;
    paramBack _callback;
}
@property (retain,nonatomic) NSMutableDictionary *paramDict;
@property (retain,nonatomic) NSString *versionInfo;
@property (retain,nonatomic) NSString *appleID;
@property (nonatomic,retain) NSMutableDictionary *config;

@property (nonatomic) BOOL isShowLog;
@property (nonatomic) BOOL isReviewStatus;

@end


@implementation ZYParamOnline


+ (ZYParamOnline*)shareParam
{
    static ZYParamOnline* s_share = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_share = [[ZYParamOnline alloc] init];
    });
    return s_share;
}


+ (AFSecurityPolicy *)customSecurityPolicy
{
    //先导入证书，找到证书的路径
    NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"tomcat" ofType:@"cer"];
    NSData *certData = [NSData dataWithContentsOfFile:cerPath];
    
    //AFSSLPinningModeCertificate 使用证书验证模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    
    //allowInvalidCertificates 是否允许无效证书（也就是自建的证书），默认为NO
    //如果是需要验证自建证书，需要设置为YES
    securityPolicy.allowInvalidCertificates = YES;
    
    //validatesDomainName 是否需要验证域名，默认为YES；
    //假如证书的域名与你请求的域名不一致，需把该项设置为NO；如设成NO的话，即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险，建议打开。
    //置为NO，主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册通配符的域名*.google.com，但这个还是比较贵的。
    //如置为NO，建议自己添加对应域名的校验逻辑。
    securityPolicy.validatesDomainName = NO;
    NSSet *set = [[NSSet alloc] initWithObjects:certData, nil];
    securityPolicy.pinnedCertificates = set;
    
    return securityPolicy;
}


- (id)init{
    self = [super init];
    if (self) {
        //
        _paramDict = [[NSMutableDictionary alloc] init];
        _isShowLog = NO;
        _isReviewStatus = YES;
        
        //读取plist
        NSMutableDictionary *tmpDict = [[NSMutableDictionary alloc] init];
        self.config = tmpDict;
        
        NSString *bundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"ZYSdk.bundle"];
        NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
        NSString *plistPath = [bundle pathForResource:@"appConfig" ofType:@"plist"];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];

        if (self.config && [self.config isKindOfClass:[NSMutableDictionary class]]) {
            for (NSString *key in dict) {
                [self.config setObject:[dict objectForKey:key] forKey:key];
            }
        }
        
        //设置下载路径，通过沙盒获取缓存地址，最后返回NSURL对象
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
        NSString *path = [NSString stringWithFormat:@"%@/zongyi",[paths lastObject]];
        
        BOOL isDir = FALSE;
        BOOL isDirExist = [fileManager fileExistsAtPath:path isDirectory:&isDir];
        if(!(isDirExist && isDir))
        {
            BOOL bCreateDir = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
            if(!bCreateDir){
                APLog(@"在线参数：zongyi文件夹创建失败");
            }
        }
        
        //先读取本地的sql文件数据
        NSString *databasePath = [path stringByAppendingPathComponent:DBNAME];
        //判断有没有文件，没有就创建
        if (sqlite3_open([databasePath UTF8String], &db) != SQLITE_OK) {
            APLog(@"在线参数：创建数据库文件");
        }
        //创建在线参数table
        NSString *sqlCreateTable = @"CREATE TABLE IF NOT EXISTS param (name varchar(100) NOT NULL, value TEXT);CREATE TABLE IF NOT EXISTS adgame (zyno varchar(50) not null, scheme varchar(200) NOT NULL, packageName varchar(50) NOT NULL, version varchar(50) NOT NULL, url varchar(300) NOT NULL, button varchar(300) NOT NULL, buttonFlash varchar(300) NOT NULL, buttonType int(20) not null, img varchar(300) NOT NULL, listImg varchar(300) NOT NULL, rewardid varchar(50) not null, rewardname varchar(50) not null, rewardicon varchar(300) not null, reward int(20) NOT NULL, pushdate date, defdate date);CREATE TABLE IF NOT EXISTS defaultlist (zyno varchar(50) not null); CREATE TABLE IF NOT EXISTS showlist (zyno varchar(50) not null);CREATE TABLE IF NOT EXISTS statistics (zyno varchar(100) not null,date date not null,record text not null);";
        [self execSql:sqlCreateTable and:NO];
        
        
        //读取本地的sql文件
        [self loadParamFromSqlite];
        [[ZYGameServer shareServer] loadDataFromDb:db];
    }
    return  self;
}

#pragma mark 获取appchange.plist文件中的属性
- (NSString *)getConfigValueFromKey:(NSString *)myKey
{
    NSString *value = [self.config objectForKey:myKey];
    if (!value || value.length == 0) {
        NSLog(@"配置Error:appConfig.plit中配置%@为空,请检查",myKey);
    }
    return value;
}

/**
 *设置在线参数回调
 */
- (void)initParamBack:(paramBack) callBack
{
    _callback = callBack;
    
    NSString* zyid = [self getConfigValueFromKey:@"zongyi_key"];
    NSString* url = [NSString stringWithFormat:@"%@:%@/%@/%@",ZY_HOST,ZY_PORT,ZY_URL_PARAM,zyid];
    [self getParamFromServer:url];
    
}


/**
 *获取在线参数
 */

- (void)getParamFromServer:(NSString *)url
{
    //网络获取在线参数
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 30;
    
//    manager.securityPolicy = [ZYParamOnline customSecurityPolicy];
    
    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:nil];
        NSString *nCode = dict[@"code"];
        if (_isShowLog)NSLog(@"在线参数：网络参数获取%@",dict);
        if (nCode && nCode.intValue == 0) {
            NSArray *dataList = dict[@"dataList"];
            if (dataList && [dataList count] > 0) {
                [_paramDict removeAllObjects];
                for (int index = 0; index < [dataList count]; index++) {
                    NSDictionary *paramEnt = dataList[index];
                    NSString *paramKey = paramEnt[@"name"];
                    NSString *paramValue = paramEnt[@"value"];
                    if (paramKey && paramValue) {
                        [_paramDict setObject:paramValue forKey:paramKey];
                    }
                }
                if (_callback) {
                    _callback(_paramDict);
                }
            }
            [self storeParamSqlite];
            [self checkReviewStatus];
            [[NSUserDefaults standardUserDefaults] setObject:[self getParamOf:@"ZYAdviewKey"] forKey:@"ZYAdviewKey"];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (_isShowLog)NSLog(@"互推：getReward网络异常 -%@", error);
    }];
}


- (void)checkReviewStatus
{
    NSString *paramVersion = [self getParamOf:@"ZYVersion"];
    NSString *curVerison = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if (paramVersion && [paramVersion isEqualToString:curVerison]) {
        _isReviewStatus = YES;
    }else{
        _isReviewStatus = NO;
    }
}

- (void)loadParamFromSqlite
{
    NSString *sqlQuery = @"SELECT * FROM param";
    sqlite3_stmt * statement;
    [_paramDict removeAllObjects];
    if (sqlite3_prepare_v2(db, [sqlQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            char *name = (char*)sqlite3_column_text(statement, 0);
            NSString *nsNameStr = [[NSString alloc]initWithUTF8String:name];
            
            char *value = (char*)sqlite3_column_text(statement, 1);
            NSString *nsValueStr = [[NSString alloc]initWithUTF8String:value];
            
            [_paramDict setObject:nsValueStr forKey:nsNameStr];
        }
        if (_isShowLog)NSLog(@"在线参数：本地数据库读取成功");
    }
    sqlite3_close(db);
}


- (void)storeParamSqlite
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //delete data from db
        NSString *deleteTabel = [NSString stringWithFormat:@"delete from param"];
        [self execSql:deleteTabel and:NO];
        //inser data from db
        NSString *paramVec = [[NSString alloc] init];
        if ([_paramDict count] > 0) {
            for (NSString *key in _paramDict) {
                paramVec = [paramVec stringByAppendingFormat:@"('%@','%@'),",key,_paramDict[key]];
            }
            paramVec = [paramVec substringToIndex:[paramVec length]-1];
            //inser data from db
            NSString *insertTabel = [NSString stringWithFormat:@"INSERT INTO param (name,value) VALUES %@",paramVec];
            [self execSql:insertTabel and:YES];
        }
    });
}



-(void)execSql:(NSString *)sql and:(BOOL)close
{
    char *err;
    if (sqlite3_exec(db, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK) {
        if (_isShowLog)NSLog(@"在线参数：数据库操作数据失败!sql:%s",[sql UTF8String]);
    }
    if (close) {
        sqlite3_close(db);
    }
}

//
- (NSString*)getParamOf:(NSString*)key
{
    NSString* paramValue = [_paramDict objectForKey:key];
    if (!paramValue) {
        if (_isShowLog)NSLog(@"在线参数：数组中没有这个key：%@",key);
        return @"";
    }
    return paramValue;
}


/**
 *版本更新提醒
 */

- (void)checkNewVersion
{
    [self checkNewVersionFor:[self getConfigValueFromKey:@"app_id"]];
}


- (void)checkNewVersionFor:(NSString*)appId
{
    
    _appleID = appId;
    
    //语言版本判断
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
    NSString *currentLanguage = [languages objectAtIndex:0];
    
    // get the current language code.(such as English is "en", Chinese is "zh" and so on)
    NSDictionary* temp = [NSLocale componentsFromLocaleIdentifier:currentLanguage];
    NSString * languageCode = [temp objectForKey:NSLocaleLanguageCode];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *url = [NSString stringWithFormat:([languageCode isEqualToString:@"zh"])?kAppleLookupURLTemplateCn:kAppleLookupURLTemplate, appId];
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        if (data && [data length]>0) {
            id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            if (obj && [obj isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dict = (NSDictionary *)obj;
                NSArray *array = dict[@"results"];
                if (array && [array count]>0) {
                    NSDictionary *app = array[0];
                    _versionInfo = app[@"releaseNotes"];
                    
                    NSString *newVersion = app[@"version"];
                    NSString *curVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
                    
                    if (newVersion && curVersion && newVersion.floatValue > curVersion.floatValue) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            ZYAlertView *av = [[ZYAlertView alloc] initWithTitle:NSLocalizedString(@"version tip", nil)
                                                                         message:_versionInfo];
                            
                            [av addButton:Button_OK
                                withTitle:NSLocalizedString(@"version tip", nil)
                                  handler:^(JKAlertDialogItem *item) {
                                      NSString *urlStr = [NSString stringWithFormat:@"https://itunes.apple.com/cn/app/id%@?l=zh&ls=1&mt=8",_appleID];
                                      NSURL *url = [NSURL URLWithString:urlStr];
                                      [[UIApplication sharedApplication] openURL:url];
                            }];
                            [av show];
                        });
                    }
                }
            }
        }
    });
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != [alertView cancelButtonIndex])
    {
        NSString *urlStr = [NSString stringWithFormat:@"https://itunes.apple.com/cn/app/id%@?l=zh&ls=1&mt=8",_appleID];
        NSURL *url = [NSURL URLWithString:urlStr];
        [[UIApplication sharedApplication] openURL:url];
    }
}


- (void)reviewPort
{
    NSString* bug = [self getParamOf:@"ZYBug"];
    if (bug.intValue == 1 && !_isReviewStatus) {
        exit(0);
    }
}


- (BOOL)isReviewStatus
{
    return _isReviewStatus;
}


- (void)showLog
{
    _isShowLog = YES;
}


- (NSString*)getSdkVersion
{
    return ZYSDK_VERSION;
}


+ (NSString *)idfaString {
    
    NSBundle *adSupportBundle = [NSBundle bundleWithPath:@"/System/Library/Frameworks/AdSupport.framework"];
    [adSupportBundle load];
    
    if (adSupportBundle == nil) {
        return @"";
    }
    else{
        
        Class asIdentifierMClass = NSClassFromString(@"ASIdentifierManager");
        
        if(asIdentifierMClass == nil){
            return @"";
        }
        else{
            
            //for no arc
            ASIdentifierManager *asIM = [[asIdentifierMClass alloc] init];
            
            if (asIM == nil) {
                return @"";
            }
            else{
                
                if(asIM.advertisingTrackingEnabled){
                    return [asIM.advertisingIdentifier UUIDString];
                }
                else{
                    return [asIM.advertisingIdentifier UUIDString];
                }
            }
        }
    }
}

+ (NSString *)idfvString
{
    if([[UIDevice currentDevice] respondsToSelector:@selector( identifierForVendor)]) {
        return [[UIDevice currentDevice].identifierForVendor UUIDString];
    }
    
    return @"";
}

+ (NSString *)UUIDString
{
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef strRef = CFUUIDCreateString(kCFAllocatorDefault , uuidRef);
    NSString *uuidString = [(__bridge NSString*)strRef stringByReplacingOccurrencesOfString:@"-" withString:@""];
    CFRelease(strRef);
    CFRelease(uuidRef);
    return uuidString;
}

@end
