//
//  ParamOnline.m
//  sdkIOSDemo
//
//  Created by JustinYang on 16/8/23.
//
//

#import "ZYParamOnline.h"

#import "MobClick.h"
#import "MobClickGameAnalytics.h"
#import "MobClickSocialAnalytics.h"



#define DBNAME    @"personinfo.sqlite"


#define kAppleLookupURLTemplate         @"http://itunes.apple.com/lookup?id=%@"
#define kAppleLookupURLTemplateCn       @"http://itunes.apple.com/cn/lookup?id=%@"


#define kZongYiSdkServerID              @"http://www.zongyigame.com:6601/ZYGameServer/app/v1/gameParam/%@"


#define APLog(str, ...)  if(_isShowLog)NSLog(str, ##__VA_ARGS__)


@interface ZYParamOnline()
{
    sqlite3 *db;
    int nAppId;
    paramBack _callback;
}
@property(retain,nonatomic)NSMutableDictionary *paramDict;
@property(retain,nonatomic)NSString *versionInfo;
@property(retain,nonatomic)NSString *appleID;
@property(nonatomic)BOOL isShowLog;

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


- (id)init{
    self = [super init];
    if (self) {
        
        _paramDict = [[NSMutableDictionary alloc] init];
        _isShowLog = NO;
        
    }
    return  self;
}


/**
 *设置在线参数回调
 */
- (void)initWithParamBack:(paramBack) callBack
{
    [self getParamFromServer:[NSString stringWithFormat:kZongYiSdkServerID,NSLocalizedString(@"ZYSDK_ID", nil)]];
    _callback = callBack;
}


/**
 *获取在线参数
 */

- (void)getParamFromServer:(NSString *)url
{
    //先读取本地的sql文件数据
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documents = [paths objectAtIndex:0];
    NSString *database_path = [documents stringByAppendingPathComponent:DBNAME];
    //判断有没有文件，没有就创建
    if (sqlite3_open([database_path UTF8String], &db) != SQLITE_OK) {
        APLog(@"在线参数：创建数据库文件");
    }
    NSString *sqlCreateTable = @"CREATE TABLE IF NOT EXISTS param (name TEXT, value TEXT)";
    [self execSql:sqlCreateTable and:NO];
    //读取本地的sql文件
    [self loadParamFromSqlite];
    
    //网络获取在线参数
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        if (data && [data length]>0) {
            id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            if (obj && [obj isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dict = (NSDictionary *)obj;
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
                }
            }
        }
    });
}

- (void)loadParamFromSqlite
{
    NSString *sqlQuery = @"SELECT * FROM param";
    sqlite3_stmt * statement;
    [_paramDict removeAllObjects];
    if (sqlite3_prepare_v2(db, [sqlQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            char *name = (char*)sqlite3_column_text(statement, 1);
            NSString *nsNameStr = [[NSString alloc]initWithUTF8String:name];
            
            char *value = (char*)sqlite3_column_text(statement, 2);
            NSString *nsValueStr = [[NSString alloc]initWithUTF8String:value];
            
            [_paramDict setObject:nsValueStr forKey:nsNameStr];
        }
        if (_isShowLog)NSLog(@"在线参数：本地数据库读取成功");
    }
    sqlite3_close(db);
}


- (void)storeParamSqlite
{
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
    id paramValue = [_paramDict objectForKey:key];
    if (!paramValue) {
        if (_isShowLog)NSLog(@"在线参数：数组中没有这个key：%@",key);
    }
    return paramValue;
}


/**
 *版本更新提醒
 */

- (void)checkNewVersion
{
    [self checkNewVersionFor:NSLocalizedString(@"APP_ID", nil)];
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
                    NSString *newVersion = app[@"version"];
                    _versionInfo = app[@"releaseNotes"];
                    
                    [[NSUserDefaults standardUserDefaults] setObject:newVersion
                                                              forKey:@"kAppNewVersion"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    NSString *curVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
                    [[NSBundle mainBundle] objectForInfoDictionaryKey:@"trackViewUrl"];
                    
                    if (newVersion && curVersion && newVersion.floatValue >curVersion.floatValue) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"version tip", nil)
                                                                         message:_versionInfo
                                                                        delegate:self           //委托给Self，才会执行上面的调用
                                                               cancelButtonTitle:NSLocalizedString(@"version no", nil)
                                                               otherButtonTitles:NSLocalizedString(@"version yes", nil),nil];
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


- (void)showLog
{
    _isShowLog = YES;
}



- (void)initUmeng
{
    //Umeng sdk
    [MobClick startWithAppkey:NSLocalizedString(@"UMENG_ID", nil) reportPolicy:BATCH channelId:@""];
    
    //umstrack 倒量统计
    NSString * deviceName = [[[UIDevice currentDevice] name] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString * mac = [self macString];
    NSString * idfa = [self idfaString];
    NSString * idfv = [self idfvString];
    NSString * urlString = [NSString stringWithFormat:@"http://log.umtrack.com/ping/%@/?devicename=%@&mac=%@&idfa=%@&idfv=%@", NSLocalizedString(@"UMENG_ID", nil), deviceName, mac, idfa, idfv];
    [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL: [NSURL URLWithString:urlString]] delegate:nil];
}

- (NSString * )macString{
    int mib[6];
    size_t len;
    char *buf;
    unsigned char *ptr;
    struct if_msghdr *ifm;
    struct sockaddr_dl *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1\n");
        return NULL;
    }
    
    if ((buf = (char*)malloc(len)) == NULL) {
        printf("Could not allocate memory. error!\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2");
        free(buf);
        return NULL;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    NSString *macString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                           *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    free(buf);
    
    return macString;
}

- (NSString *)idfaString {
    
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
            //for arc
            //            ASIdentifierManager *asIM = [[asIdentifierMClass alloc] init];
            
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

- (NSString *)idfvString
{
    if([[UIDevice currentDevice] respondsToSelector:@selector( identifierForVendor)]) {
        return [[UIDevice currentDevice].identifierForVendor UUIDString];
    }
    
    return @"";
}

@end
