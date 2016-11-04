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
#define WX_APPID @"wxa467f86b4d427b77"
// 开放平台登录https://open.weixin.qq.com的开发者中心获取AppSecret。
#define WX_APPSecret @"c43ec03a72699816c79026d96d53f441"
// 微信支付商户号
#define MCH_ID  @"1402915602"
// 安全校验码（MD5）密钥，商户平台登录账户和密码登录http://pay.weixin.qq.com
// 平台设置的“API密钥”，为了安全，请设置为以数字和字母组成的32字符串。
#define WX_PartnerKey @"1d54fdfo9SA85dzyi52484htasfkjlKJ"



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


#import <Foundation/Foundation.h>
#import "WXApi.h"
#import "WXApiObject.h"

typedef void (^WxPayBack)(PayResp* payResp);


@interface WXApiManager : NSObject<WXApiDelegate>
{
    WxPayBack _wxPayBack;
}

@property (nonatomic,strong) NSMutableDictionary* outTradeNoDic;
@property (nonatomic,strong) NSString* outTradeNo;


+ (instancetype)sharedManager;
//- (void)sendAuthRequest;
/*! @brief 发送购买通知并返回支付成功回调
 *
 * @param payBody   需传入应用市场上的APP名字-实际商品名称，天天爱消除-游戏充值。
 * @param price     订单总金额，单位为分
 * @param payBack   微信支付成功后的回调
 */
- (void)sendWxPay:(NSString*)payBody price:(int)price back:(WxPayBack)payBack;
//- (void)sendQueryPay:(NSString*)outTradeNo;
@end


#endif /* WeChatApi_hpp */
