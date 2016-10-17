//
//  GameServer.m
//  sdkIOSDemo
//
//  Created by JustinYang on 16/8/24.
//
//

#import "ZYGameServer.h"


#define HTTP_MOREGAME           @"http://www.zongyigame.com:8801/zhongyi/gameInfoIF/getRanGameInfos/v2"
#define HTTP_REGISTER           @"http://www.zongyigame.com:8801/zhongyi/gameInfoIF/saveMobileGame"
#define HTTP_RECOMMEND          "http://www.zongyigame.com:8801/zhongyi/gameInfoIF/saveMobileJumpGame"
#define HTTP_ACTIVATION         "http://www.zongyigame.com:8801/zhongyi/gameInfoIF/getUnexchangedRewardList"
#define HTTP_EXCHANGE           "http://www.zongyigame.com:8801/zhongyi/gameInfoIF/changeStatusExchangedReward"


@implementation ZYGameServer



- (void)registerMobile
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:HTTP_REGISTER]];
        if (data && [data length]>0) {
            id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            if (obj && [obj isKindOfClass:[NSDictionary class]]) {
                
            }
        }
    });
}



@end
