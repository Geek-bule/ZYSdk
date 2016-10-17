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

typedef void (^paramBack)(NSDictionary *dict);

@interface ZYParamOnline : NSObject


+ (ZYParamOnline*)shareParam;

/**
 *设置在线参数回调
 */
- (void)initWithParamBack:(paramBack) callBack;


/**
 *获取在线参数值
 */

- (NSString*)getParamOf:(NSString*)key;


/**
 *如果需要版本更新提醒的调用此函数
 */

- (void)checkNewVersion;


/**
 *展示log
 */
- (void)showLog;

@end
