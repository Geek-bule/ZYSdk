//
//  ZYGameInfo.h
//  sdkIOSDemo
//
//  Created by JustinYang on 16/9/7.
//
//

#import <Foundation/Foundation.h>

@interface ZYGameInfo : NSObject

@property (nonatomic, strong) NSString *zyno;
@property (nonatomic, strong) NSString *scheme;
@property (nonatomic, strong) NSString *packageName;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSString *button;
@property (nonatomic, strong) NSString *buttonFlash;
@property (nonatomic, strong) NSString *img;
@property (nonatomic, strong) NSString *listImg;
@property (nonatomic, strong) NSString *rewardId;
@property (nonatomic, strong) NSString *rewardName;
@property (nonatomic, strong) NSString *rewardIcon;
@property (nonatomic, strong) NSNumber *reward;


- (void)setValue:(id)value forUndefinedKey:(NSString *)key;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
