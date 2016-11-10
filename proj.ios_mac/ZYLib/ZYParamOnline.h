//
//  ParamOnline.h
//  sdkIOSDemo
//
//  Created by JustinYang on 16/8/23.
//
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <UIKit/UIKit.h>
#import "AFNetworking.h"


#define ZYSDK_VERSION       @"v1.1.5"
/**
 1.1.4  1.增加互推图片的超时时间，超过15天的图片就从本地删除
        2.增加本地数据库参数  pushdate defdate
 
 1.1.5  1.fix 修复了ios7下广告的横竖屏判断不准确问题
        2.fix 准确获取横竖屏广告图
 
 */

typedef void (^paramBack)(NSDictionary *dict);

@interface ZYParamOnline : NSObject


+ (ZYParamOnline*)shareParam;

+ (AFSecurityPolicy *)customSecurityPolicy;

/**
 *配置文件属性
 */
- (NSString *)getConfigValueFromKey:(NSString *)myKey;


/**
 *设置在线参数回调
 */
- (void)initParamBack:(paramBack) callBack;


/**
 *获取在线参数值
 */

- (NSString*)getParamOf:(NSString*)key;


/**
 *如果需要版本更新提醒的调用此函数
 */

- (void)checkNewVersion;


/**
 *审核设置的接口
 */
- (void)reviewPort;


/**
 *审核设置的接口
 */
- (BOOL)isReviewStatus;


/**
 *展示log
 */
- (void)showLog;


/**
 *获取sdk的版本号
 */
- (NSString*)getSdkVersion;

/**
 IDFA
 */
+ (NSString *)idfaString;

/**
 IDFV
 */
+ (NSString *)idfvString;

/**
 UUID
 */
+ (NSString *)UUIDString;


@end
