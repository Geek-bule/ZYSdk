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


#define ZY_HOST                 @"http://121.42.183.124"
#define ZY_PORT                 @"80"


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
 IDFA
 */
- (NSString *)idfaString;

/**
 IDFV
 */
- (NSString *)idfvString;


@end
