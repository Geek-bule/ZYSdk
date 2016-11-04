//
//  InterfaceController.m
//  Cookie Extension
//
//  Created by JustinYang on 16/1/5.
//
//
@import WatchConnectivity;
#import "InterfaceController.h"


@interface InterfaceController()

@end


@implementation InterfaceController

- (instancetype)init {
    self = [super init];
    
    if (self) {
        //激活功能
        if ([WCSession isSupported]) {
            [WCSession defaultSession].delegate = self;
            [[WCSession defaultSession] activateSession];
        }
    }
    
    return self;
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

//手机发送需要展示的信息过来进行展示
- (void)session:(nonnull WCSession *)session didReceiveApplicationContext:(nonnull NSDictionary<NSString *,id> *)applicationContext {
    NSLog(@"Reply Info: %@", applicationContext);
    NSString *pStageInfo = [applicationContext valueForKey:@"stage"];
    [self.LabelStage setText:pStageInfo];
    NSString *pStarInfo = [applicationContext valueForKey:@"starinfo"];
    [self.LabelStar setText:pStarInfo];
    NSString *pHeartInfo = [applicationContext valueForKey:@"heartinfo"];
    [self.LabelHeart setText:pHeartInfo];
}


@end



