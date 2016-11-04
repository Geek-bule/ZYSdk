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


#define ZY_HOST                 @"http://121.42.183.124:6601"
#define ZY_URL_QUERY            @"/ZYPay/app/v1/queryorder/"
#define ZY_URL_UNIFIED          @"/ZYPay/app/v1/unifiedorder/"
#define ZY_APPID                @"zyp1477734954832"


@implementation WXApiManager

#pragma mark - 单粒

+(instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static WXApiManager *instance;
    dispatch_once(&onceToken, ^{
        instance = [[WXApiManager alloc] init];
    });
    return instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _outTradeNoDic = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - WXApiDelegate

- (void)onResp:(BaseResp *)resp
{
    if([resp isKindOfClass:[PayResp class]]){
        
        //支付返回结果，实际支付结果需要去微信服务器端查询
        PayResp *payResp = (PayResp *)resp;
        if (_wxPayBack) {
            _wxPayBack(payResp);
        }
        
    }else if ([resp isKindOfClass:[SendAuthResp class]]) {
        NSString *strMsg;
        switch (resp.errCode) {
            case WXSuccess:
            {
//                SendAuthResp *authResp = (SendAuthResp *)resp;
                
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

- (void)sendWxPay:(NSString*)payBody price:(int)price back:(WxPayBack)payBack
{
    _wxPayBack = payBack;
    NSString *url = [NSString stringWithFormat:@"%@%@%@",ZY_HOST,ZY_URL_UNIFIED,ZY_APPID];
    NSNumber *payFee = [NSNumber numberWithInteger:price];
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
                _outTradeNo = dic[@"outTradeNo"];
                NSLog(@"微信支付：创建订单－跳转微信");
                [self jumpToWxPay:dic[@"prepayId"]];
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
                    //
                    NSLog(@"微信支付：查询订单－校验订单成功");
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
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"微信支付：网络异常 查询订单-%@", error);
    }];
}


@end



