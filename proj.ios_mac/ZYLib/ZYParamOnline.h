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


#define ZYSDK_VERSION       @"v1.1.7"
/**
 1.1.4  1.增加互推图片的超时时间，超过15天的图片就从本地删除
        2.增加本地数据库参数  pushdate defdate
 
 1.1.5  1.fix 修复了ios7下广告的横竖屏判断不准确问题
        2.fix 准确获取横竖屏广告图
        3.修复切除游戏动画暂停问题
 
 1.1.6  1.添加一个version文件用来判断版本
        2.添加一个版本判断函数，设定某个版本更新时要删除旧版本的db和图片

 1.1.7  1.修改互推展示的界面规则，分为直接显示、圆形按钮和三角按钮
        2.修改了互推函数的接口结构
        3.标准所有界面的注释
        4.添加了一个三角形按钮
 
 */

typedef void (^paramBack)(NSDictionary *dict);

@interface ZYParamOnline : NSObject


+ (ZYParamOnline*)shareParam;

+ (AFSecurityPolicy *)customSecurityPolicy;

/**
 *  @brief  配置文件属性
 *  @param  myKey           appConfig.plist中设定的key
 */
- (NSString *)getConfigValueFromKey:(NSString *)myKey;


/**
 *  @brief  设置在线参数回调
 *  @param  callBack        设定在线参数通讯成功的回调
 */
- (void)initParamBack:(paramBack) callBack;


/**
 *  @brief  获取在线参数值
 *  @param  key             在线参数的key
 */

- (NSString*)getParamOf:(NSString*)key;


/**
 *  @brief  如果需要版本更新提醒的调用此函数
 */

- (void)checkNewVersion;


/**
 *  @brief  审核设置的接口，通过在线参数ZYBug来设定开关
 */
- (void)reviewPort;


/**
 *  @brief  判断当前是不是在审核的状态，根据在线参数ZYVersion来设定
 */
- (BOOL)isReviewStatus;


/**
 *  @brief  展示log
 */
- (void)showLog;


/**
 *  @brief  获取sdk的版本号
 */
- (NSString*)getSdkVersion;

/**
 *  @brief  IDFA
 */
+ (NSString *)idfaString;

/**
 *  @brief  IDFV
 */
+ (NSString *)idfvString;

/**
 *  @brief  手机用户名称
 */
+ (NSString *)deviceName;


@end
