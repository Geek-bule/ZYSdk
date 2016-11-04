//
//  ZYAwardInfo.h
//  sdkIOSDemo
//
//  Created by JustinYang on 16/9/13.
//
//

#import <Foundation/Foundation.h>

@interface ZYAwardInfo : NSObject

@property (nonatomic, strong) NSNumber *rid;
@property (nonatomic, strong) NSString *zyno;
@property (nonatomic, strong) NSString *rewardId;
@property (nonatomic, strong) NSString *rewardName;
@property (nonatomic, strong) NSString *rewardIcon;
@property (nonatomic, strong) NSNumber *reward;


- (void)setValue:(id)value forUndefinedKey:(NSString *)key;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
