//
//  WeChatApi.hpp
//  sdkIOSDemo
//
//  Created by JustinYang on 16/10/31.
//
//

#ifndef WeChatApi_hpp
#define WeChatApi_hpp

#include <stdio.h>

#pragma mark - 需要配置的参数

// 开放平台登录https://open.weixin.qq.com的开发者中心获取APPID
#define WX_APPID                @"wx459b15288a0c688e"
// 开放平台登录https://open.weixin.qq.com的开发者中心获取AppSecret。
#define WX_APPSecret            @"710880027b36585ec00c0c4cef91d875"
// 微信支付商户号
#define MCH_ID                  @"1402915602"
// 安全校验码（MD5）密钥，商户平台登录账户和密码登录http://pay.weixin.qq.com
// 平台设置的“API密钥”，为了安全，请设置为以数字和字母组成的32字符串。
#define WX_PartnerKey           @"1d54fdfo9SA85dzyi52484htasfkjlKJ"
//  zysdk后台生成唯一性id
#define ZY_APPID                @"acba1f83d703422daacfc9615492abad"


#import <Foundation/Foundation.h>
#import "WXApi.h"
#import "WXApiObject.h"
#import <sqlite3.h>


@class WXTradeBody;
typedef void (^WxPayBack)(WXTradeBody* payResp);


@interface ZYWXApiManager : NSObject<WXApiDelegate>
{
    WxPayBack _wxPayBack;
    sqlite3 *db;
}

@property (nonatomic,strong) NSMutableDictionary* outTradeNoDic;
@property (nonatomic,strong) NSMutableArray* verifyPayArray;


+ (instancetype)sharedManager;
//- (void)sendAuthRequest;
/*! @brief 发送购买通知并返回支付成功回调
 *
 * @param payBody   需传入应用市场上的APP名字-实际商品名称，天天爱消除-游戏充值。
 * @param price     订单总金额，单位为分
 * @param payBack   微信支付成功后的回调
 */
- (void)setCallBack:(WxPayBack)payBack;
- (void)sendWxPay:(NSString*)payBody body:(WXTradeBody*)tradeBody;
- (void)sendQueryPay:(NSString*)outTradeNo;
- (NSString *)fetchIPAddress;
- (NSString *)idfaString;
@end


@interface WXTradeBody : NSObject

@property (nonatomic,retain) NSString* tradeNo;
@property (nonatomic,retain) NSNumber* price;
@property (nonatomic,retain) NSString* productId;
@property (nonatomic,retain) NSNumber* productNum;
@property (nonatomic,retain) NSString* idfa;

- (void)setValue:(id)value forUndefinedKey:(NSString *)key;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end




#endif /* WeChatApi_hpp */
