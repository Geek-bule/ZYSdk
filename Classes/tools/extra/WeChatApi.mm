//
//  WeChatApi.cpp
//  sdkIOSDemo
//
//  Created by JustinYang on 16/10/31.
//
//

#include "WeChatApi.h"
#import "AFNetworking.h"
#import "OpenUDID.h"
#import <CommonCrypto/CommonDigest.h>
//for idfa
#import <AdSupport/AdSupport.h>
#pragma mark - 用户获取设备ip地址
#include <ifaddrs.h>
#include <arpa/inet.h>

//地址
#define ZY_HOST                 @"https://www.zongyimobile.com:6602"
#define ZY_URL_QUERY            @"/ZYPay/app/v1/queryorder/"
#define ZY_URL_UNIFIED          @"/ZYPay/app/v1/unifiedorder/"

#pragma mark - 统一下单请求参数键值

// 应用id
#define WXAPPID @"appid"
// 商户号
#define WXMCHID @"mch_id"
// 随机字符串
#define WXNONCESTR @"nonce_str"
// 签名
#define WXSIGN @"sign"
// 商品描述
#define WXBODY @"body"
// 总金额
#define WXTOTALFEE @"total_fee"


@implementation ZYWXApiManager

#pragma mark - 单粒

+(instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static ZYWXApiManager *instance;
    dispatch_once(&onceToken, ^{
        instance = [[ZYWXApiManager alloc] init];
    });
    return instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        
        [self creteProductDB];
        
        _outTradeNoDic = [[NSMutableDictionary alloc] init];
        _verifyPayArray = [[NSMutableArray alloc] init];
        
        [self loadProductInfo];
        
        //设置回调
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(verifyPay)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        
        
    }
    return self;
}

#pragma mark - WXApiDelegate

- (void)onResp:(BaseResp *)resp
{
    if([resp isKindOfClass:[PayResp class]]){
        
        //支付返回结果，实际支付结果需要去微信服务器端查询
        
    }else if ([resp isKindOfClass:[SendAuthResp class]]) {
        NSString *strMsg;
        switch (resp.errCode) {
            case WXSuccess:
            {
                break;
            }
            default:
                strMsg = [NSString stringWithFormat:@"支付结果：失败！retcode = %d, retstr = %@", resp.errCode,resp.errStr];
                NSLog(@"错误，retcode = %d, retstr = %@", resp.errCode,resp.errStr);
                break;
        }
    }
}



#pragma mark - 产生随机字符串

//生成随机数算法 ,随机字符串，不长于32位
//微信支付API接口协议中包含字段nonce_str，主要保证签名不可预测。
//我们推荐生成随机数算法如下：调用随机数函数生成，将得到的值转换为字符串。
- (NSString *)generateTradeNO {
    
    static int kNumber = 15;
    
    NSString *sourceStr = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    
    NSMutableString *resultStr = [[NSMutableString alloc] init];
    
    srand(time(0)); // 此行代码有警告:
    
    for (int i = 0; i < kNumber; i++) {
        
        unsigned index = rand() % [sourceStr length];
        
        NSString *oneStr = [sourceStr substringWithRange:NSMakeRange(index, 1)];
        
        [resultStr appendString:oneStr];
    }
    return resultStr;
}


#pragma mark - 获取设备ip地址 / 貌似该方法获取ip地址只能在wifi状态下进行

- (NSString *)fetchIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}


#pragma mark - 创建发起支付时的sign签名
-(NSString *)createMD5SingForPay:(NSDictionary *)signParams{
    NSMutableString *contentString  =[NSMutableString string];
    NSArray *keys = [signParams allKeys];
    //按字母顺序排序
    NSArray *sortedArray = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    //拼接字符串
    for (NSString *categoryId in sortedArray) {
        [contentString appendFormat:@"%@=%@&", categoryId, [signParams objectForKey:categoryId]];
    }
    
    //添加商户密钥key字段
    [contentString appendFormat:@"key=%@", WX_PartnerKey];
    
    NSString *result = [self md5:contentString];
    
    return result;
}

#pragma mark -  MD5加密算法
-(NSString *) md5:(NSString *)str
{
    const char *cStr = [str UTF8String];
    //加密规则，因为逗比微信没有出微信支付demo，这里加密规则是参照安卓demo来得
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    //这里的x是小写则产生的md5也是小写，x是大写则md5是大写，这里只能用大写，逗比微信的大小写验证很逗
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

#pragma mark -  跳转微信支付
- (void)jumpToWxPay:(NSString*)prepayId
{
    // 发起微信支付，设置参数
    PayReq *request = [[PayReq alloc] init];
    request.openID = WX_APPID;
    request.partnerId = MCH_ID;
    request.prepayId= prepayId;
    request.package = @"Sign=WXPay";
    // 随机字符串变量 这里最好使用和安卓端一致的生成逻辑
    NSString *tradeNO = [self generateTradeNO];
    request.nonceStr= tradeNO;
    
    // 将当前时间转化成时间戳
    NSDate *datenow = [NSDate date];
    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[datenow timeIntervalSince1970]];
    UInt32 timeStamp =[timeSp intValue];
    request.timeStamp= timeStamp;
    
    NSMutableDictionary *signParams = [NSMutableDictionary dictionary];
    [signParams setObject:WX_APPID forKey:@"appid"];
    [signParams setObject:tradeNO forKey:@"noncestr"];
    [signParams setObject:@"Sign=WXPay" forKey:@"package"];
    [signParams setObject:MCH_ID forKey:@"partnerid"];
    [signParams setObject:prepayId forKey:@"prepayid"];
    [signParams setObject:[NSString stringWithFormat:@"%u",(unsigned int)timeStamp] forKey:@"timestamp"];
    request.sign = [self createMD5SingForPay:signParams];
    
    // 调用微信
    [WXApi sendReq:request];
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


- (NSString *)getUUIDString
{
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef strRef = CFUUIDCreateString(kCFAllocatorDefault , uuidRef);
    NSString *uuidString = [(__bridge NSString*)strRef stringByReplacingOccurrencesOfString:@"-" withString:@""];
    CFRelease(strRef);
    CFRelease(uuidRef);
    return uuidString;
}


- (void)addHeader:(AFHTTPSessionManager *)manager
{
    [manager.requestSerializer setValue:[self idfaString] forHTTPHeaderField:@"idfa"];
    [manager.requestSerializer setValue:[self idfvString] forHTTPHeaderField:@"idfv"];
    [manager.requestSerializer setValue:[OpenUDID value] forHTTPHeaderField:@"openudid"];
    [manager.requestSerializer setValue:[self getUUIDString] forHTTPHeaderField:@"uuid"];
}


#pragma mark - Public Methods

-(void)sendAuthRequest
{
    //构造SendAuthReq结构体
    SendAuthReq* req = [[SendAuthReq alloc ] init];
    req.scope = @"snsapi_userinfo" ;
    req.state = @"123" ;
    //第三方向微信终端发送一个SendAuthReq消息结构
    [WXApi sendReq:req];
}

- (void)setCallBack:(WxPayBack)payBack
{
    _wxPayBack = payBack;
}

- (void)sendWxPay:(NSString*)payBody body:(WXTradeBody*)tradeBody {
    
    NSString *url = [NSString stringWithFormat:@"%@%@%@",ZY_HOST,ZY_URL_UNIFIED,ZY_APPID];
    NSNumber *payFee = tradeBody.price;
    NSString *nonceStr = [self generateTradeNO];
    
    NSMutableDictionary *parameter = [[NSMutableDictionary alloc] init];
    [parameter setObject:nonceStr forKey:@"nonceStr"];
    [parameter setObject:payFee forKey:@"totalFee"];
    [parameter setObject:payBody forKey:@"body"];
    NSString *sign = [self createMD5SingForPay:parameter];
    [parameter setObject:sign forKey:@"sign"];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 30;
    
    [self addHeader:manager];
    
    [manager POST:url parameters:parameter progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:nil];
        NSString *code = dic[@"code"];
        if (code && code.intValue == 0) {
            NSMutableDictionary *parameter = [[NSMutableDictionary alloc] init];
            [parameter setObject:dic[@"code"] forKey:@"code"];
            [parameter setObject:dic[@"message"] forKey:@"message"];
            [parameter setObject:dic[@"nonceStr"] forKey:@"nonceStr"];
            [parameter setObject:dic[@"prepayId"] forKey:@"prepayId"];
            [parameter setObject:dic[@"outTradeNo"] forKey:@"outTradeNo"];
            NSString *sign = [self createMD5SingForPay:parameter];
            if ([sign isEqualToString:dic[@"sign"]]) {
                NSString* outTradeNo = dic[@"outTradeNo"];
                if (tradeBody) {
                    tradeBody.tradeNo = outTradeNo;
                    [_outTradeNoDic setObject:tradeBody forKey:outTradeNo];
                    [self storeProductInfo:outTradeNo];
                    [self jumpToWxPay:dic[@"prepayId"]];
                }
                NSLog(@"微信支付：创建订单－跳转微信 %@",dic);
            }else{
                NSLog(@"微信支付：创建订单－签名错误");
            }
        }else{
            NSString *message = dic[@"message"];
            NSLog(@"微信支付：创建订单－%@",message);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"微信支付：网络异常 创建订单-%@", error);
    }];
}


#pragma mark - 查询订单(验证订单的准确定，目前不做验证操作忽略此函数)

- (void)sendQueryPay:(NSString*)outTradeNo
{
    NSString *url = [NSString stringWithFormat:@"%@%@%@",ZY_HOST,ZY_URL_QUERY,ZY_APPID];
    NSString *nonceStr = [self generateTradeNO];
    
    NSMutableDictionary *parameter = [[NSMutableDictionary alloc] init];
    [parameter setObject:nonceStr forKey:@"nonceStr"];
    [parameter setObject:outTradeNo forKey:@"outTradeNo"];
    NSString *sign = [self createMD5SingForPay:parameter];
    [parameter setObject:sign forKey:@"sign"];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 40;
    
    [self addHeader:manager];
    
    NSLog(@"微信支付：sendQueryPay=>%@?%@",url,parameter);
    
    [manager POST:url parameters:parameter progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:nil];
        NSString *code = dic[@"code"];
        if (code && code.intValue == 0) {
            NSMutableDictionary *parameter = [[NSMutableDictionary alloc] init];
            [parameter setObject:dic[@"code"] forKey:@"code"];
            [parameter setObject:dic[@"message"] forKey:@"message"];
            [parameter setObject:dic[@"nonceStr"] forKey:@"nonceStr"];
            [parameter setObject:dic[@"tradeState"] forKey:@"tradeState"];
            [parameter setObject:dic[@"outTradeNo"] forKey:@"outTradeNo"];
            NSString *sign = [self createMD5SingForPay:parameter];
            if ([sign isEqualToString:dic[@"sign"]]) {
                /*
                 SUCCESS—支付成功
                 REFUND—转入退款
                 NOTPAY—未支付
                 CLOSED—已关闭
                 REVOKED—已撤销（刷卡支付）
                 USERPAYING--用户支付中
                 PAYERROR--支付失败
                 */
                if ([dic[@"tradeState"] isEqualToString:@"SUCCESS"]) {
                    //给玩家商品
                    NSLog(@"微信支付：查询订单－校验订单成功%@",dic);
                    WXTradeBody *body = [[WXTradeBody alloc] init];
                    body = _outTradeNoDic[dic[@"outTradeNo"]];
                    //支付返回结果，实际支付结果需要去微信服务器端查询
                    if (_wxPayBack) {
                        body.idfa = [self idfaString];
                        _wxPayBack(body);
                    }
                    [self deleteProductInfo:dic[@"outTradeNo"]];
                }else if ([dic[@"tradeState"] isEqualToString:@"CLOSED"]) {
                    //已关闭的删除掉
                    [self deleteProductInfo:dic[@"outTradeNo"]];
                }else{
                    //其他支付状态
                    NSLog(@"微信支付：查询订单－校验订单%@",dic[@"tradeState"]);
                }
                
            }else{
                NSLog(@"微信支付：查询订单－签名错误");
            }
        }else{
            NSString *message = dic[@"message"];
            NSLog(@"微信支付：查询订单－%@",message);
            [self deleteProductInfo:outTradeNo];
        }
        [self startVerify];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"微信支付：网络异常 查询订单-%@", error);
    }];
}

//遍历本地数组
- (void)verifyPay
{
    for (NSString *key in _outTradeNoDic) {
        [_verifyPayArray addObject:_outTradeNoDic[key]];
    }
    [self startVerify];
}

- (void)startVerify
{
    if ([_verifyPayArray count] > 0) {
        WXTradeBody *body = _verifyPayArray[0];
        [self sendQueryPay:body.tradeNo];
        [_verifyPayArray removeObjectAtIndex:0];
    }
}

//- (WXTradeBody*)tradeBodyFor:(NSNumber*)price tradeNo:(NSString*)tradeNo
//{
//    WXTradeBody* body = [[WXTradeBody alloc] init];
//    if (price.intValue == 1) {
//        body.tradeNo = tradeNo;
//        body.price = price;
//        body.productId = @"jinbi";
//        body.productNum = [NSNumber numberWithInt:30];
//        return body;
//    }
//    return nil;
//}

//订单表创建
- (void)creteProductDB
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    //先读取本地的sql文件数据
    NSString *path = [NSString stringWithFormat:@"%@",[paths lastObject]];
    NSString *databasePath = [path stringByAppendingPathComponent:@"zyproduct"];
    
    //判断有没有db文件，没有就创建
    if (sqlite3_open([databasePath UTF8String], &db) != SQLITE_OK) {
        NSLog(@"微信支付：创建数据库文件");
    }
    
    //创建微信支付table
    NSString *sqlCreateTable = @"CREATE TABLE IF NOT EXISTS zyproduct (tradeno varchar(130) not null,price int not null,productid varchar(100) not null,productnum int not null);";
    [self execSql:sqlCreateTable isClose:YES];
}
//订单表存储
- (void) storeProductInfo:(NSString*)tradeNo
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //inser data from db
        NSString *paramVec = [[NSString alloc] init];
        WXTradeBody *body = _outTradeNoDic[tradeNo];
        if (body) {
            paramVec = [NSString stringWithFormat:@"('%@','%@','%@','%@')",tradeNo,body.price,body.productId,body.productNum];
            NSString *insertTabel = [NSString stringWithFormat:@"INSERT INTO zyproduct (tradeno,price,productid,productnum) VALUES %@",paramVec];
            [self execSql:insertTabel isClose:YES];
        }
    });
}

//订单表删除
- (void) deleteProductInfo:(NSString*)tradeNo
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //inser data from db
        [_outTradeNoDic removeObjectForKey:tradeNo];
        NSString *deleteTable = [NSString stringWithFormat:@"delete from zyproduct where tradeno = '%@'",tradeNo];
        [self execSql:deleteTable isClose:YES];
    });
}

//订单表读取
- (void) loadProductInfo
{
    NSString *sqlQuery = @"SELECT * FROM zyproduct";
    sqlite3_stmt * statement;
    [_outTradeNoDic removeAllObjects];
    if (sqlite3_prepare_v2(db, [sqlQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            WXTradeBody *body = [[WXTradeBody alloc] init];
            char *strTradeNo = (char*)sqlite3_column_text(statement, 0);
            NSString *TradeNo = [[NSString alloc]initWithUTF8String:strTradeNo];
            body.tradeNo = TradeNo;
            
            int nPrice = sqlite3_column_int(statement, 1);
            NSNumber* price = [NSNumber numberWithInt:nPrice];
            body.price = price;
            
            char *strProductID = (char*)sqlite3_column_text(statement, 2);
            NSString *productId = [[NSString alloc]initWithUTF8String:strProductID];
            body.productId = productId;
            
            int nProductNum = sqlite3_column_int(statement, 3);
            NSNumber* productNum = [NSNumber numberWithInt:nProductNum];
            body.productNum = productNum;
            
            [_outTradeNoDic setObject:body forKey:TradeNo];
        }
        NSLog(@"微信支付：本地数据库读取成功");
    }
}

-(void)execSql:(NSString *)sql isClose:(BOOL)close
{
    char *err;
    if (sqlite3_exec(db, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK) {
        NSLog(@"微信支付：数据库操作数据失败!sql:%s",[sql UTF8String]);
        NSLog(@"微信支付：数据库操作数据失败!error:%s",err);
    }
}

@end

@implementation WXTradeBody

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    
}

- (void)setValue:(id)value forKey:(NSString *)key {
    
    if ([value isKindOfClass:[NSNull class]]) {
        
        return;
    }
    
    [super setValue:value forKey:key];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    
    if ([dictionary isKindOfClass:[NSDictionary class]]) {
        
        self = [super init];
        
        if (self) {
            
            [self setValuesForKeysWithDictionary:dictionary];
        }
        
        return self;
        
    } else {
        
        return nil;
    }
}

@end

