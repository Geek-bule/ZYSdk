//
//  appleWatch.cpp
//  sdkIOSDemo
//
//  Created by JustinYang on 16/10/11.
//
//

#include "appleWatch.h"

#import <Foundation/Foundation.h>
#import <WatchConnectivity/WatchConnectivity.h>

//================================================================================
//                  简单的手表功能，按照手表文档接入
//================================================================================

//手表功能 ios原生接入
@interface appleWatch : NSObject<WCSessionDelegate>

+ (appleWatch*)shareWatch;
//启动
- (void)startWatch;

@end


@implementation appleWatch

+ (appleWatch*)shareWatch
{
    static appleWatch* s_share = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_share = [[appleWatch alloc] init];
    });
    return s_share;
}

- (id)init
{
    self = [super init];
    if (self) {
        if ([WCSession isSupported]) {
            [WCSession defaultSession].delegate = self;
            [[WCSession defaultSession] activateSession];
        }
        
        [self updateWatchConnectivitySessionApplicationContext];
    }
    return self;
}

- (void)startWatch
{
    [NSTimer scheduledTimerWithTimeInterval:2
     
                                     target:self
     
                                   selector:@selector(updateWatchConnectivitySessionApplicationContext)
     
                                   userInfo:nil
     
                                    repeats:YES];
}

#pragma mark - WCSessionDelegate
//更新手表上面的展示信息
- (void)sessionWatchStateDidChange:(nonnull WCSession *)session {
    NSLog(@"手表 StateDidChange %@",session);
    if (session.watchAppInstalled) {
        [self updateWatchConnectivitySessionApplicationContext];
    }
}

//手表需要接受的数据在这里添加
- (void)updateWatchConnectivitySessionApplicationContext {
    // Do not proceed if `WCSession` is not supported on this iOS device.
    if (![WCSession isSupported]) { return; }
    
    WCSession *session = [WCSession defaultSession];
    
    // Do not proceed if the watch app is not installed on the paired watch.
    if (!session.watchAppInstalled) { return; }
    
    // A background queue to execute operations on to fetch the information about the lists.
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    // This operation will execute last and will actually update the application context.
    NSBlockOperation *updateApplicationContextOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSError *error;
        //需要上传的数据
        int nStageOpen = rand()%100;
        NSString *nStargeInfo = [NSString stringWithFormat:@"Stage %d",nStageOpen];
        
        int nTotalStars = rand()%222;
        NSString *pStarInfo = [NSString stringWithFormat:@"%d/%d",nTotalStars,nStageOpen*3];
        
        int nHeartCur = rand()%333;
        int nHeartMax = rand()%444;
        NSString *pHeartInfo = [NSString stringWithFormat:@"%d/%d",nHeartCur,nHeartMax];
        
        NSDictionary *response = @{@"stage":nStargeInfo,@"starinfo":pStarInfo,@"heartinfo":pHeartInfo};
        //传输的数据NSDictionary
        if (![session updateApplicationContext:response error:&error]) {
            NSLog(@"Error updating context: %@", error.localizedDescription);
        }
    }];
    
    [queue addOperation:updateApplicationContextOperation];
}


- (void)session:(nonnull WCSession *)session didReceiveApplicationContext:(nonnull NSDictionary<NSString *,id> *)applicationContext {
    
    NSLog(@"手表 didReceiveApplicationContext %@",session);
    
}


@end



void appleWatchCpp::init()
{
    [appleWatch shareWatch];
}


void appleWatchCpp::startWatch()
{
    [[appleWatch shareWatch] startWatch];
}
