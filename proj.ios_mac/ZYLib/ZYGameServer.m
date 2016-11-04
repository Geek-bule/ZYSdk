//
//  GameServer.m
//  sdkIOSDemo
//
//  Created by JustinYang on 16/8/24.
//
//

#import "ZYGameServer.h"
#import "ZYParamOnline.h"
#import "OpenUDID.h"
#import "ZYGameInfo.h"
#import "ZYAwardInfo.h"
#import "ZYAlertView.h"
#import "ZYAdStatistics.h"


#define ZY_URL_REGISTER         @"ZYGameServer/app/v1/login"
#define ZY_URL_MOREGAME         @"ZYGameServer/app/v1/gameInfo"
#define ZY_URL_JUMPDOWN         @"ZYGameServer/app/v1/gamePush/jump"
#define ZY_URL_AWARDLIST        @"ZYGameServer/app/v1/gamePush/reward"
#define ZY_URL_GETAWARD         @"ZYGameServer/app/v1/gamePush/reward"
#define ZY_URL_STATISTICS       @"ZYGameServer/app/v1/gamePush/statistics"


#define cellHeight              40


@interface ZYGameServer()<UIAlertViewDelegate>
{
    sqlite3 *_db;
//    UITableView *_table;
}

@property(nonatomic)BOOL isShowLog;

@property (nonatomic, retain) NSString* ZYTransId;      //随机数
@property (nonatomic, retain) NSString* ZYToken;        //token
@property (nonatomic, retain) NSString* ZYAppId;        //appId
@property (nonatomic, retain) NSString* ZYChannelId;        //appId

@property (nonatomic, assign) BOOL  isRegistering;      //注册接口已经运行
@property (nonatomic, retain) NSMutableDictionary* blockArray;  //回调数组

@property (nonatomic, retain) NSString* ZYTestZyno;        //appId

@property (nonatomic) awardBack awardShowBack;
@property (nonatomic) awardBack awardGiveBack;

@end

@implementation ZYGameServer

+ (ZYGameServer*)shareServer
{
    static ZYGameServer* s_share = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_share = [[ZYGameServer alloc] init];
    });
    return s_share;
}


- (id)init
{
    self = [super init];
    if (self) {
        
        _blockArray = [[NSMutableDictionary alloc] init];
        _adGameInfoDic = [[NSMutableDictionary alloc] init];
        _rewardInfoDic = [[NSMutableDictionary alloc] init];
        _adGameZynoArray = [[NSMutableArray alloc] init];
        _adDefaultArray = [[NSMutableArray alloc] init];
        _adDisableImg = [[NSMutableArray alloc] init];
        _adLoadImgArray = [[NSMutableArray alloc] init];
        _isShowLog = NO;
        
        //设置回调
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(getRewardList)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        
    }
    return self;
}


- (void)loadGameServer
{
    //appid 传入
    _ZYAppId = [[ZYParamOnline shareParam] getConfigValueFromKey:@"zongyi_key"];
    _ZYChannelId = [[ZYParamOnline shareParam] getConfigValueFromKey:@"zongyi_channel"];
    
    //注册
    [self registerMobile:@"loadMoreGameInfo" back:^(NSString *token) {
        [self loadMoreGameInfo];
        //统计
        [[ZYAdStatistics shareStatistics] setSqlite:_db];
    }];
    
    
}


- (NSString*)getLanguage
{
    //语言版本判断
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
    NSString *currentLanguage = [languages objectAtIndex:0];
    
    // get the current language code.(such as English is "en", Chinese is "zh" and so on)
    NSDictionary* temp = [NSLocale componentsFromLocaleIdentifier:currentLanguage];
    NSString * languageCode = [temp objectForKey:NSLocaleLanguageCode];
    
    return languageCode;
}


- (NSString*)getVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}


- (NSString*)getFilePath:(NSString*)url
{
    NSArray* searchArray = [url componentsSeparatedByString:@"/"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *path = [NSString stringWithFormat:@"%@/zongyi/images",[paths lastObject]];
    NSString *imagePath = [path stringByAppendingPathComponent:searchArray.lastObject];
    return imagePath;
}


- (void)addHeader:(AFHTTPSessionManager *)manager
{
    [manager.requestSerializer setValue:_ZYTransId forHTTPHeaderField:@"transId"];
    [manager.requestSerializer setValue:[ZYParamOnline idfaString] forHTTPHeaderField:@"idfa"];
    [manager.requestSerializer setValue:[ZYParamOnline idfvString] forHTTPHeaderField:@"idfv"];
    [manager.requestSerializer setValue:[OpenUDID value] forHTTPHeaderField:@"openudid"];
    [manager.requestSerializer setValue:@"ios" forHTTPHeaderField:@"zyos"];
    [manager.requestSerializer setValue:[self getLanguage] forHTTPHeaderField:@"language"];
    [manager.requestSerializer setValue:_ZYToken forHTTPHeaderField:@"token"];
    if (_isShowLog)NSLog(@"互推：header:%@",manager.requestSerializer.HTTPRequestHeaders);
    
}

- (void)createHeader:(AFHTTPSessionManager *)manager
{
    srandom(time(0));
    int nTransId = random() % 1000000+100000;
    _ZYTransId = [NSString stringWithFormat:@"%d",nTransId];
    [manager.requestSerializer setValue:_ZYTransId forHTTPHeaderField:@"transId"];
    [manager.requestSerializer setValue:[ZYParamOnline idfaString] forHTTPHeaderField:@"idfa"];
    [manager.requestSerializer setValue:[ZYParamOnline idfvString] forHTTPHeaderField:@"idfv"];
    [manager.requestSerializer setValue:[OpenUDID value] forHTTPHeaderField:@"openudid"];
    [manager.requestSerializer setValue:@"ios" forHTTPHeaderField:@"os"];
    [manager.requestSerializer setValue:[self getLanguage] forHTTPHeaderField:@"language"];
    if (_isShowLog)NSLog(@"互推：header:%@",manager.requestSerializer.HTTPRequestHeaders);
}



- (void)loadDataFromDb:(sqlite3*)db
{
    _db = db;
    NSString *sqlQuery = @"SELECT * FROM adgame";
    sqlite3_stmt * statement;
    [_adGameInfoDic removeAllObjects];
    if (sqlite3_prepare_v2(db, [sqlQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            ZYGameInfo *info = [[ZYGameInfo alloc] init];
            char *zyno = (char*)sqlite3_column_text(statement, 0);
            info.zyno = [[NSString alloc]initWithUTF8String:zyno];
            
            char *scheme = (char*)sqlite3_column_text(statement, 1);
            info.scheme = [[NSString alloc]initWithUTF8String:scheme];
            
            char *packageName = (char*)sqlite3_column_text(statement, 2);
            info.packageName = [[NSString alloc]initWithUTF8String:packageName];
            
            char *url = (char*)sqlite3_column_text(statement, 3);
            info.url = [[NSString alloc]initWithUTF8String:url];
            
            char *version = (char*)sqlite3_column_text(statement, 4);
            info.version = [[NSString alloc]initWithUTF8String:version];
            
            char *button = (char*)sqlite3_column_text(statement, 5);
            info.button = [[NSString alloc]initWithUTF8String:button];
            
            char *buttonFlash = (char*)sqlite3_column_text(statement, 6);
            info.buttonFlash = [[NSString alloc]initWithUTF8String:buttonFlash];
            
            char *img = (char*)sqlite3_column_text(statement, 7);
            info.img = [[NSString alloc]initWithUTF8String:img];
            
            char *listImg = (char*)sqlite3_column_text(statement, 8);
            info.listImg = [[NSString alloc]initWithUTF8String:listImg];
            
            [_adGameInfoDic setObject:info forKey:info.zyno];
        }
        if (_isShowLog)NSLog(@"互推：本地数据库adgame读取成功");
    }
    
    sqlQuery = @"SELECT * FROM showlist";
    [_adGameZynoArray removeAllObjects];
    if (sqlite3_prepare_v2(db, [sqlQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            char *zyno = (char*)sqlite3_column_text(statement, 0);
            NSString *nsNameStr = [[NSString alloc]initWithUTF8String:zyno];
            
            [_adGameZynoArray addObject:nsNameStr];
        }
        if (_isShowLog)NSLog(@"互推：本地数据库showlist读取成功");
    }
    
    sqlQuery = @"SELECT * FROM defaultlist";
    [_adDefaultArray removeAllObjects];
    if (sqlite3_prepare_v2(db, [sqlQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            char *zyno = (char*)sqlite3_column_text(statement, 0);
            NSString *nsNameStr = [[NSString alloc]initWithUTF8String:zyno];
            
            [_adDefaultArray addObject:nsNameStr];
        }
        if (_isShowLog)NSLog(@"互推：本地数据库defaultlist读取成功");
    }
    sqlite3_close(db);
}


- (void)storeAdGameInfo
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *deleteTabel = [NSString stringWithFormat:@"delete from adgame"];
        [self execSql:deleteTabel and:NO];
        //inser data from db
        NSString *paramVec = [[NSString alloc] init];
        if ([_adGameInfoDic count] > 0) {
            for (NSString *key in _adGameInfoDic) {
                ZYGameInfo *info = _adGameInfoDic[key];
                paramVec = [paramVec stringByAppendingFormat:@"('%@','%@','%@','%@','%@','%@','%@','%@','%@','%@','%@','%@','%@'),",info.zyno,info.scheme,info.packageName,info.version,info.url,info.button,info.buttonFlash,info.img,info.listImg,info.rewardId,info.rewardName,info.rewardIcon,info.reward];
            }
            paramVec = [paramVec substringToIndex:[paramVec length]-1];
            //inser data from db
            NSString *insertTabel = [NSString stringWithFormat:@"INSERT INTO adgame (zyno, scheme, packageName, version, url, button, buttonFlash, img, lisImg, rewardid, rewardname, rewardicon, reward) VALUES %@",paramVec];
            [self execSql:insertTabel and:NO];
        }
        
        deleteTabel = [NSString stringWithFormat:@"delete from showlist"];
        [self execSql:deleteTabel and:NO];
        //inser data from db
        paramVec = @"";
        if ([_adGameZynoArray count] > 0) {
            for (id value in _adGameZynoArray) {
                paramVec = [paramVec stringByAppendingFormat:@"('%@'),",value];
            }
            paramVec = [paramVec substringToIndex:[paramVec length]-1];
            //inser data from db
            NSString *insertTabel = [NSString stringWithFormat:@"INSERT INTO showlist (zyno) VALUES %@",paramVec];
            [self execSql:insertTabel and:NO];
        }
        
        deleteTabel = [NSString stringWithFormat:@"delete from defaultlist"];
        [self execSql:deleteTabel and:NO];
        //inser data from db
        paramVec = @"";
        if ([_adDefaultArray count] > 0) {
            for (id value in _adDefaultArray) {
                paramVec = [paramVec stringByAppendingFormat:@"('%@'),",value];
            }
            paramVec = [paramVec substringToIndex:[paramVec length]-1];
            //inser data from db
            NSString *insertTabel = [NSString stringWithFormat:@"INSERT INTO defaultlist (zyno) VALUES %@",paramVec];
            [self execSql:insertTabel and:YES];
        }
    });
}


-(void)execSql:(NSString *)sql and:(BOOL)close
{
    char *err;
    if (sqlite3_exec(_db, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK) {
        if (_isShowLog)NSLog(@"互推：数据库操作数据失败!sql:%s",[sql UTF8String]);
    }
    if (close) {
        sqlite3_close(_db);
    }
}


- (BOOL)isTokenActive
{
    if (!self.ZYToken || self.ZYToken.length == 0) {
        return NO;
    }
    return YES;
}


- (void)registerMobile:(NSString*)name back:(tokenBack)_callBack
{
    if (name && _callBack) {
        [_blockArray setObject:_callBack forKey:name];
    }
    if (_isRegistering) {
        return;
    }
    _isRegistering = YES;
    //登陆链接
    NSString*url = [NSString stringWithFormat:@"%@:%@/%@",ZY_HOST,ZY_PORT,ZY_URL_REGISTER];
    NSDictionary * parameter = @{@"zyno":_ZYAppId, @"version":[self getVersion]};
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 30;
    [self createHeader:manager];
    if (_isShowLog)NSLog(@"互推：register=>%@?%@",url,parameter);

    [manager POST:url parameters:parameter progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:nil];
        if (_isShowLog)NSLog(@"互推：register<=%@",dic);
        _isRegistering = NO;
        NSString *code = dic[@"code"];
        if (code && code.intValue == 0) {
            _ZYToken = dic[@"token"];
            for (NSString* key in _blockArray) {
                tokenBack back = _blockArray[key];
                if (back) {
                    back(_ZYToken);
                }
            }
            [_blockArray removeAllObjects];
        }else{
            NSString *message = dic[@"message"];
            if (_isShowLog)NSLog(@"互推：register－%@",message);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (_isShowLog)NSLog(@"互推：register网络异常 - %@", error);
    }];
}



- (void)loadMoreGameInfo
{
    if (![self isTokenActive]) {
        return;
    }
    CGRect winSize = [[UIScreen mainScreen] bounds];
    NSString *url = [NSString stringWithFormat:@"%@:%@/%@",ZY_HOST,ZY_PORT,ZY_URL_MOREGAME];
    NSDictionary * parameter = @{@"zyno":_ZYAppId, @"channel":_ZYChannelId, @"screen":(winSize.size.width>winSize.size.height)?@"landscape":@"portrait"};
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 30;
    [self addHeader:manager];
    if (_isShowLog)NSLog(@"互推：loadgame=>%@?%@",url,parameter);
    
    manager.securityPolicy = [ZYParamOnline customSecurityPolicy];
    
    [manager GET:url parameters:parameter progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:nil];
        if (_isShowLog)NSLog(@"互推：loadgame<=%@",dic);
        NSString *code = dic[@"code"];
        if (code && code.intValue == 0) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSDictionary* defaultList = dic[@"defaultList"];
            NSArray* dataList = defaultList[@"dataList"];
            [_adDefaultArray removeAllObjects];
            if (dataList.count > 0) {
                NSMutableArray *zynoArray = [[NSMutableArray alloc] init];
                for (id value in dataList) {
                    ZYGameInfo *info = [[ZYGameInfo alloc] initWithDictionary:value];
                    //对比2个版本
                    [self compareWith:info];
                    //存储默认的zyno
                    [zynoArray addObject:info.zyno];
                    //判断是不是
                    if (![fileManager fileExistsAtPath:[self getFilePath:info.button]]) {
                        [_adLoadImgArray addObject:info.button];
                    }
                    if (![fileManager fileExistsAtPath:[self getFilePath:info.buttonFlash]]) {
                        [_adLoadImgArray addObject:info.buttonFlash];
                    }
                    if (![fileManager fileExistsAtPath:[self getFilePath:info.listImg]]) {
                        [_adLoadImgArray addObject:info.listImg];
                    }
                }
                _adDefaultArray = [[NSMutableArray alloc] initWithArray:zynoArray];
            }
            NSDictionary *pushList = dic[@"pushList"];
            dataList = pushList[@"dataList"];
            [_adGameZynoArray removeAllObjects];
            if (dataList.count > 0) {
                NSMutableArray *zynoArray = [[NSMutableArray alloc] init];
                for (id value in dataList) {
                    ZYGameInfo *info = [[ZYGameInfo alloc] initWithDictionary:value];
                    //对比2个版本
                    [self compareWith:info];
                    //存储推荐的zyno
                    [zynoArray addObject:info.zyno];
                    //判断文件是不是存在
                    if (![fileManager fileExistsAtPath:[self getFilePath:info.button]]) {
                        [_adLoadImgArray addObject:info.button];
                    }
                    if (![fileManager fileExistsAtPath:[self getFilePath:info.buttonFlash]]) {
                        [_adLoadImgArray addObject:info.buttonFlash];
                    }
                    if (![fileManager fileExistsAtPath:[self getFilePath:info.img]]) {
                        [_adLoadImgArray addObject:info.img];
                    }
                    if (info.rewardIcon && ![info.rewardIcon isEqualToString:@""]) {
                        if (![fileManager fileExistsAtPath:[self getFilePath:info.rewardIcon]]) {
                            [_adLoadImgArray addObject:info.rewardIcon];
                        }
                    }
                }
                _adGameZynoArray = [[NSMutableArray alloc] initWithArray:zynoArray];
                
            }
            
            //存储到本地
            [self storeAdGameInfo];
            //下载图片
            [self beginToDownload];
        }else{
            if (code && code.intValue == 2) {
                [self registerMobile:@"loadMoreGameInfo" back:^(NSString *token) {
                    [self loadMoreGameInfo];
                }];
            }
            NSString *message = dic[@"message"];
            if (_isShowLog)NSLog(@"互推：loadgame－%@",message);
        }
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (_isShowLog)NSLog(@"互推：loadgame网络异常 -%@", error);
    }];
}

- (void)compareWith:(ZYGameInfo*)info
{
    ZYGameInfo*oldInfo = [_adGameInfoDic objectForKey:info.zyno];
    if (!oldInfo) {
        [_adGameInfoDic setObject:info forKey:info.zyno];
    }else{
        if (![oldInfo.button isEqualToString:info.button]) {
            [_adDisableImg addObject:oldInfo.button];
        }
        if (![oldInfo.buttonFlash isEqualToString:info.buttonFlash]) {
            [_adDisableImg addObject:oldInfo.buttonFlash];
        }
        if (![oldInfo.img isEqualToString:info.img]) {
            [_adDisableImg addObject:oldInfo.img];
        }
        if (![oldInfo.listImg isEqualToString:info.listImg]) {
            [_adDisableImg addObject:oldInfo.listImg];
        }
        if (oldInfo.rewardIcon && info.rewardIcon && ![oldInfo.rewardIcon isEqualToString:@""] && ![info.rewardIcon isEqualToString:@""] ) {
            if (![oldInfo.rewardIcon isEqualToString:info.rewardIcon]) {
                [_adDisableImg addObject:oldInfo.rewardIcon];
            }
        }
        [_adGameInfoDic setObject:info forKey:info.zyno];
    }
}


- (void)removeDownloadImg
{
    if ([_adDisableImg count] >0) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        for (id value in _adDisableImg) {
            NSString* filePath = [self getFilePath:value];
            [fileManager removeItemAtPath:filePath error:nil];
        }
        [_adDisableImg removeAllObjects];
    }
}


- (void)beginToDownload
{
    [self removeDownloadImg];
    if (_adLoadImgArray.count > 0) {
        //begin download
        NSString *downloadUrl = [_adLoadImgArray objectAtIndex:0];
        if (_isShowLog)NSLog(@"互推：开始下载%@",downloadUrl);
        [self downloadImage:downloadUrl];
        [_adLoadImgArray removeObject:downloadUrl];
    }
}


- (void)downloadImage:(NSString*)urlString
{
    //1.创建管理者对象
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    //2.确定请求的URL地址
    NSURL *URL = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    //3.创建请求对象
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        //下载地址
        if (_isShowLog)NSLog(@"互推：默认下载地址:%@",targetPath);
        //设置下载路径，通过沙盒获取缓存地址，最后返回NSURL对象
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
        NSString *path = [NSString stringWithFormat:@"%@/zongyi/images",[paths lastObject]];
        
        BOOL isDir = FALSE;
        BOOL isDirExist = [fileManager fileExistsAtPath:path isDirectory:&isDir];
        if(!(isDirExist && isDir))
        {
            BOOL bCreateDir = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
            if(!bCreateDir){
                if (_isShowLog)NSLog(@"互推：images文件夹创建失败");
            }
        }
        
        NSURL *documentsDirectoryURL = [fileManager URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        
        return [documentsDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"zongyi/images/%@",[response suggestedFilename]]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (_isShowLog)NSLog(@"互推：File downloaded to: %@ \n _%@_", filePath,error);
        [self beginToDownload];
    }];
    [downloadTask resume];
}


- (void)jumpToDownload:(NSString*)pushZyno
{
    if (![self isTokenActive]) {
        return;
    }
    ZYGameInfo *info = _adGameInfoDic[pushZyno];
    _ZYTestZyno = pushZyno;//测试使用
    NSString *url = [NSString stringWithFormat:@"%@:%@/%@",ZY_HOST,ZY_PORT,ZY_URL_JUMPDOWN];
    NSDictionary *parameter = @{@"zyno":_ZYAppId, @"pushZyno":pushZyno, @"pushVersion":info.version};
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 30;
    [self addHeader:manager];
    if (_isShowLog)NSLog(@"互推：jumpDownload=>%@?%@",url,parameter);
    
    [manager POST:url parameters:parameter progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:nil];
        if (_isShowLog)NSLog(@"互推：jumpDownload<=%@",dic);
        NSString *code = dic[@"code"];
        if (code && code.intValue == 0) {
            if (_isShowLog)NSLog(@"跳转调用");
        }else{
            if (code && code.intValue == 2) {
                [self registerMobile:@"jumpToDownload" back:^(NSString *token) {
                    [self jumpToDownload:pushZyno];
                }];
            }
            NSString *message = dic[@"message"];
            if (_isShowLog)NSLog(@"互推：jumpToDownload－%@",message);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (_isShowLog)NSLog(@"互推：jumpToDownload网络异常 -%@", error);
    }];
    
    //jump url
    NSURL *downUrl= [NSURL URLWithString:info.url];
    [[UIApplication sharedApplication] openURL:downUrl];
}


- (void)setAward:(awardBack)show andGive:(awardBack)give
{
    _awardShowBack = show;
    _awardGiveBack = give;
}

- (void)getRewardList
{
    if (![self isTokenActive]) {
        return;
    }
    
    NSString *url = [NSString stringWithFormat:@"%@:%@/%@",ZY_HOST,ZY_PORT,ZY_URL_AWARDLIST];
    NSDictionary *parameter = @{@"zyno":_ZYAppId, @"channel":_ZYChannelId};
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 30;
    [self addHeader:manager];
    if (_isShowLog)NSLog(@"互推：getReward=>%@?%@",url,parameter);
    
    [manager GET:url parameters:parameter progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:nil];
        if (_isShowLog)NSLog(@"互推：getReward<=%@",dic);
        NSString *code = dic[@"code"];
        if (code && code.intValue == 0) {
            NSArray *dataList = dic[@"dataList"];
            if (_awardShowBack) {
                _awardShowBack(dataList);
            }else {
                if (dataList.count > 0) {
                    _adGameRic = @"";
                    int nCount = 1;
                    for (id value in dataList) {
                        ZYAwardInfo *info = [[ZYAwardInfo alloc] initWithDictionary:value];
                        [_rewardInfoDic setObject:info forKey:info.rid];
                        _adGameRic = [_adGameRic stringByAppendingString:[NSString stringWithFormat:@"%d",info.rid.intValue]];
                        _adGameRic = [_adGameRic stringByAppendingString:@","];
                        nCount++;
                    }
                    _adGameRic = [_adGameRic substringToIndex:[_adGameRic length]-1];
                    
                    //如何防止重复切入切除出现多个alert
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"下载奖励礼包"
                                                                           message:nil
                                                                          delegate:self
                                                                 cancelButtonTitle:nil
                                                                 otherButtonTitles:@"领取", nil];
                        UIView *view = [[UIView alloc]initWithFrame:CGRectMake(180, 5, 250, _rewardInfoDic.count*cellHeight)];
                        int count= 0;
                        for (NSString *key in _rewardInfoDic) {
                            ZYAwardInfo *info = [_rewardInfoDic objectForKey:key];
                            
                            NSString* imgPath = [self getFilePath:info.rewardIcon];
                            NSFileManager* fileManager = [NSFileManager defaultManager];
                            if ([fileManager fileExistsAtPath:imgPath]) {
                                UIImage *rewardIcon = [UIImage imageWithContentsOfFile:imgPath];
                                UIImageView* rewardIconView = [[UIImageView alloc] initWithImage:rewardIcon];
                                rewardIconView.frame = CGRectMake(40, count*45, cellHeight, cellHeight);
                                [view addSubview:rewardIconView];
                            }
                            
                            UILabel *pLabel = [[UILabel alloc] init];
                            pLabel.frame = CGRectMake(90, count*45, 250-95, cellHeight);
                            [view addSubview:pLabel];
                            [pLabel setText:[NSString stringWithFormat:@"%@:%d",info.rewardName,info.reward.intValue]];
                            
                            count++;
                        }
                        
                        //check if os version is 7 or above
                        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
                            [alertView setValue:view forKey:@"accessoryView"];
                        }else{
                            [alertView addSubview:view];
                        }
                        
                        [alertView show];
                    });
                }
            }
        }else{
            if (code && code.intValue == 2) {
                [self registerMobile:@"getRewardList" back:^(NSString *token) {
                    [self getRewardList];
                }];
            }
            NSString *message = dic[@"message"];
            if (_isShowLog)NSLog(@"互推：getReward－%@",message);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (_isShowLog)NSLog(@"互推：getReward网络异常 -%@", error);
    }];
}


- (void)reviceReward:(NSString*)rid
{
    if (![self isTokenActive]) {
        return;
    }
    NSString *url = [NSString stringWithFormat:@"%@:%@/%@",ZY_HOST,ZY_PORT,ZY_URL_GETAWARD];
    NSDictionary *parameter = @{@"zyno":_ZYAppId, @"rid":rid, @"channel":_ZYChannelId};
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 30;
    [self addHeader:manager];
    if (_isShowLog)NSLog(@"互推：reviceReward=>%@?%@",url,parameter);
    
    [manager POST:url parameters:parameter progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:nil];
        if (_isShowLog)NSLog(@"互推：reviceReward<=%@",dic);
        NSString *code = dic[@"code"];
        if (code && code.intValue == 0) {
            if (_isShowLog)NSLog(@"领奖成功");
            NSArray *dataList = dic[@"dataList"];
            if (_awardGiveBack) {
                _awardGiveBack(dataList);
            }else {
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"错误！！！"
                                                             message:@"没有设置领取奖励成功的回调"
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
                [av show];
            }
        }else{
            if (code && code.intValue == 2) {
                [self registerMobile:@"reviceReward" back:^(NSString *token) {
                    [self reviceReward:rid];
                }];
            }
            NSString *message = dic[@"message"];
            if (_isShowLog)NSLog(@"互推：reviceReward－%@",message);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (_isShowLog)NSLog(@"互推：reviceReward网络异常 -%@", error);
    }];
}


#pragma --mark Alert
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0)
    {
        if (_adGameRic != nil && _adGameRic.length != 0) {
            [self reviceReward:_adGameRic];
        }
    }
}


- (void)statisticsApp:(NSDictionary*)parameter
{
    NSString *url = [NSString stringWithFormat:@"%@:%@/%@",ZY_HOST,ZY_PORT,ZY_URL_STATISTICS];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.requestSerializer.timeoutInterval = 30;
    [self addHeader:manager];
    
    if (_isShowLog)NSLog(@"互推：statisticsApp=>%@?%@",url,parameter);
    
    [manager POST:url parameters:parameter progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:nil];
        if (_isShowLog)NSLog(@"互推：statisticsApp<=%@",dic);
        NSString *code = dic[@"code"];
        if (code && code.intValue == 0) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if (_isShowLog)NSLog(@"互推：statisticsApp上传成功");
                //清空statistics数据库
                NSString *deleteTabel = @"delete from statistics";
                [self execSql:deleteTabel and:YES];
                NSDate *currentDate = [NSDate date];//获取当前时间，日期
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"YYYYMMdd"];
                [[NSUserDefaults standardUserDefaults] setObject:[dateFormatter stringFromDate:currentDate] forKey:ZYSTORE_DATE];
            });
        }else{
            NSString *message = dic[@"message"];
            if (_isShowLog)NSLog(@"互推：statisticsApp－%@",message);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (_isShowLog)NSLog(@"互推：statisticsApp网络异常 -%@", error);
    }];
}



- (void)showLog
{
    _isShowLog = YES;
}






//===============================测试接口===============================

- (void)registerTest
{
    //登陆链接
    if (_adGameInfoDic.count == 0 || !_ZYTestZyno) {
        return ;
    }
    NSString*url = [NSString stringWithFormat:@"%@:%@/%@",ZY_HOST,ZY_PORT,ZY_URL_REGISTER];
    NSDictionary * parameter = @{@"zyno":_ZYTestZyno, @"version":@"5.1"};
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 30;
    [self addHeader:manager];
    if (_isShowLog)NSLog(@"互推：register=>%@?%@",url,parameter);
    
    [manager POST:url parameters:parameter progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:nil];
        if (_isShowLog)NSLog(@"互推：register<=%@",dic);
        _isRegistering = NO;
        NSString *code = dic[@"code"];
        if (code && code.intValue == 0) {
            UIAlertView* tip = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"推送应用%@注册成功",_ZYTestZyno] delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
            [tip show];
        }else{
            NSString *message = dic[@"message"];
            if (_isShowLog)NSLog(@"互推：register－%@",message);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (_isShowLog)NSLog(@"互推：register网络异常 - %@", error);
    }];
}



//- (void)testCer
//{
//    
//    NSString*url = [NSString stringWithFormat:@"%@:%@/%@",ZY_HOST,ZY_PORT,ZY_URL_REGISTER];
//    NSDictionary * parameter = @{@"zyno":_ZYAppId, @"version":[self getVersion]};
//    
//    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
//    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
//    manager.requestSerializer.timeoutInterval = 30;
//    [self addHeader:manager];
//    //HTTPS SSL的验证，在此处调用上面的代码，给这个证书验证；
//    //    [manager setSecurityPolicy:[ZYGameServer customSecurityPolicy]];
//    [manager POST:url parameters:parameter progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:nil];
//        if (_isShowLog)NSLog(@"%@",dic);
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        
//        if (_isShowLog)NSLog(@"网络异常 - T_T%@", error);
//        
//    }];
//}
//
//
//
//- (NSDictionary*)addHeader
//{
//    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
//    [dict setObject:_ZYTransId forKey:@"transId"];
//    [dict setObject:[[ZYParamOnline shareParam] idfaString] forKey:@"idfa"];
//    [dict setObject:[[ZYParamOnline shareParam] idfvString] forKey:@"idfv"];
//    [dict setObject:[OpenUDID value] forKey:@"openudid"];
//    [dict setObject:@"ios" forKey:@"os"];
//    [dict setObject:[self getLanguage] forKey:@"language"];
//    [dict setObject:_ZYToken forKey:@"token"];
//    
//    if (_isShowLog)NSLog(@"header:%@",dict);
//    return dict;
//}
//
//- (NSDictionary*)createHeader
//{
//    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
//    srandom(time(0));
//    int nTransId = random() % 1000000+100000;
//    _ZYTransId = [NSString stringWithFormat:@"%d",nTransId];
//    [dict setObject:_ZYTransId forKey:@"transId"];
//    [dict setObject:[[ZYParamOnline shareParam] idfaString] forKey:@"idfa"];
//    [dict setObject:[[ZYParamOnline shareParam] idfvString] forKey:@"idfv"];
//    [dict setObject:[OpenUDID value] forKey:@"openudid"];
//    [dict setObject:@"ios" forKey:@"os"];
//    [dict setObject:[self getLanguage] forKey:@"language"];
//    
//    if (_isShowLog)NSLog(@"header:%@",dict);
//    return dict;
//}
//
@end
