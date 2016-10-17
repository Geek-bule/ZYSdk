//
//  GCHelper.m
//  CatRace
//
//  Created by Ray Wenderlich on 4/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//


#import <GameKit/GameKit.h>
#import "GCHelper.h"
#import <Foundation/Foundation.h>


struct LocalPlayer{
    const char* alias;      //昵称
    int authenticated;      //是否已经验证
    int isFriend;
    const char* playerID;   //是否已经成年
    int underage;
};//登陆玩家信息


@protocol GCHelperDelegate //
- (void)matchStarted;
- (void)matchEnded;
- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID;
@end

@interface GCHelper : NSObject <GKMatchmakerViewControllerDelegate, GKMatchDelegate, GKLeaderboardViewControllerDelegate,GKAchievementViewControllerDelegate> {
    
    BOOL gameCenterAvailable;//是否支持是支持GameCenter的设备
    BOOL userAuthenticated;//是否原本用户（貌似）
    LocalPlayer user;
    
    //GameCenter 游戏使用
    UIViewController *presentingViewController;
    GKMatch *match;
    BOOL matchStarted;
    id <GCHelperDelegate> delegate;
    
}

@property (assign, readonly) BOOL gameCenterAvailable;
@property (retain) UIViewController *presentingViewController;
@property (retain) GKMatch *match;
@property (assign) id <GCHelperDelegate> delegate;

+ (GCHelper *)sharedInstance;
- (void)authenticateLocalUser;                  //初始化
- (void)reportScore: (int64_t) score forCategory: (NSString*) category;                     //对应id上传分数
- (void)updatePlayerScores:(NSString*) category upScore:(int64_t)score tagChoose:(int)Tag;  //

//GameCenter 游戏使用
- (void)showGameCenter:(UIViewController *)viewController;
- (void)showLeaderboard:(UIViewController*)viewController;
- (void)showAchievement:(UIViewController*)viewController;

- (void)findMatchWithMinPlayers:(int)minPlayers maxPlayers:(int)maxPlayers viewController:(UIViewController *)viewController delegate:(int) theDelegate;

@end

@implementation GCHelper
@synthesize gameCenterAvailable;
@synthesize presentingViewController;
@synthesize match;
@synthesize delegate;

//#define RANKPERCENT "rankpercent"

#pragma mark Initialization

+ (GCHelper *) sharedInstance {
    static GCHelper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

// 验证设备是否支持GameCenter
- (BOOL)isGameCenterAvailable {
    
	// check for presence of GKLocalPlayer API
	Class gcClass = (NSClassFromString(@"GKLocalPlayer"));
	
	// check if the device is running iOS 4.1 or later
	NSString *reqSysVer = @"4.1";
	NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
	BOOL osVersionSupported = ([currSysVer compare:reqSysVer 
                                           options:NSNumericSearch] != NSOrderedAscending);
	
	return (gcClass && osVersionSupported);
}

//intialze
- (id)init {
    if ((self = [super init])) {
        gameCenterAvailable = [self isGameCenterAvailable];
        
        if (gameCenterAvailable) {
            NSNotificationCenter *nc = 
            [NSNotificationCenter defaultCenter];
            [nc addObserver:self 
                   selector:@selector(authenticationChanged) 
                       name:GKPlayerAuthenticationDidChangeNotificationName 
                     object:nil];
        }
        
    }
    return self;
}

#pragma mark Internal functions
//当登陆用户改变时候（不太明白）
- (void)authenticationChanged {    
    
    if ([GKLocalPlayer localPlayer].isAuthenticated && !userAuthenticated) {
       NSLog(@"Authentication changed: player authenticated.");
       userAuthenticated = TRUE;           
    } else if (![GKLocalPlayer localPlayer].isAuthenticated && userAuthenticated) {
       NSLog(@"Authentication changed: player not authenticated");
       userAuthenticated = FALSE;
    }
                   
}

#pragma mark User functions
//用户登陆（一般再游戏初始化部分使用）
- (void)authenticateLocalUser { 
    
    if (!gameCenterAvailable) return;
    
    NSLog(@"Authenticating local user...");
    if ([GKLocalPlayer localPlayer].authenticated == NO) {     
        [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:nil];        
    } else {
        NSLog(@"Already authenticated!");
    }
    [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:^(NSError *error){
        if (error == nil) {
            //成功处理
            NSLog(@"成功");
            NSLog(@"1--alias--.%@",[GKLocalPlayer localPlayer].alias);
            NSLog(@"2--authenticated--.%d",[GKLocalPlayer localPlayer].authenticated);
            NSLog(@"3--isFriend--.%d",[GKLocalPlayer localPlayer].isFriend);
            NSLog(@"4--playerID--.%@",[GKLocalPlayer localPlayer].playerID);
            NSLog(@"5--underage--.%d",[GKLocalPlayer localPlayer].underage);
            //赋值给结构体
            user.alias = [[GKLocalPlayer localPlayer].alias UTF8String];
            user.authenticated = [GKLocalPlayer localPlayer].authenticated;
            user.isFriend = [GKLocalPlayer localPlayer].isFriend;
            user.playerID = [[GKLocalPlayer localPlayer].playerID UTF8String];
            user.underage = [GKLocalPlayer localPlayer].underage;
        }else {
            //错误处理
            NSLog(@"失败  %@",error);
        }
    }];
}

//上传分数
- (void) reportScore: (int64_t) score forCategory: (NSString*) category
{
    GKScore *scoreReporter = [[[GKScore alloc] initWithCategory:category] autorelease];
    scoreReporter.value = score;
    
    [scoreReporter reportScoreWithCompletionHandler:^(NSError *error) {
        if (error != nil)
        {
            // handle the reporting error
            NSLog(@"上传分数出错.");
            //If your application receives a network error, you should not discard the score.
            //Instead, store the score object and attempt to report the player’s process at
            //a later time.
            
        }else {
            NSLog(@"上传分数成功");
            [self getMaxRange:category];
        }
    }];
}

//更新玩家积分 （0:积分大于下载覆盖 1:积分小于下载覆盖）
- (void) updatePlayerScores:(NSString*) category upScore:(int64_t)score tagChoose:(int)tag
{
    if (![GKLocalPlayer localPlayer].authenticated) {
        [self reportScore:score forCategory:category];
        return;
    }
    GKLeaderboard *leaderboardRequest = [[GKLeaderboard alloc] initWithPlayerIDs:[NSArray arrayWithObject:[GKLocalPlayer localPlayer].playerID]];
    if (leaderboardRequest != nil)
    {
        leaderboardRequest.timeScope = GKLeaderboardTimeScopeAllTime;
        leaderboardRequest.range = NSMakeRange(1,1);
        leaderboardRequest.category = category;
        [leaderboardRequest loadScoresWithCompletionHandler: ^(NSArray *scores, NSError *error) {
            if (error != nil){
                // handle the error.
                NSLog(@"下载失败");
            }
            if (scores != nil){
                // process the score information.
                NSLog(@"下载成功....");
                NSArray *tempScore = [NSArray arrayWithArray:leaderboardRequest.scores];
                for (GKScore *obj in tempScore) {
                    NSLog(@"    playerID            : %@",obj.playerID);
                    NSLog(@"    category            : %@",obj.category);
                    NSLog(@"    date                : %@",obj.date);
                    NSLog(@"    formattedValue      : %@",obj.formattedValue);
                    NSLog(@"    value               : %lld",obj.value);
                    NSLog(@"    rank                : %d",obj.rank);
                    NSLog(@"    context             : %lld",obj.context);
                    NSLog(@"**************************************");
                    if (tag==0) {
						//积分取最小值
						if (obj.value<score) {
                            [self reportScore:score forCategory:category];
						}else {
							NSLog(@"无需更新");
						}
					}else if (tag==1) {
						//积分取最大值
						if (obj.value>score) {
							[self reportScore:score forCategory:category];
						}else {
							NSLog(@"无需更新");
						}
					}
                }
            }
        }];
    }
}

//获取现在的排名
- (void)getMaxRange:(NSString*) category
{
    GKLeaderboard* leaderBoard= [[[GKLeaderboard alloc] init] autorelease];
	leaderBoard.category= category;
	leaderBoard.timeScope= GKLeaderboardTimeScopeAllTime;
	leaderBoard.range= NSMakeRange(1, 1);
	
	[leaderBoard loadScoresWithCompletionHandler:  ^(NSArray *scores, NSError *error)
     {
         if (error != nil){
             // handle the error.
             NSLog(@"maxrange下载失败");
         }else if (leaderBoard.maxRange != 0) {
             int myLenght = [[NSString stringWithFormat:@"%lu",(unsigned long)leaderBoard.maxRange] intValue];
             NSLog(@"maxrange下载成功 %lu %d",(unsigned long)leaderBoard.maxRange, myLenght);
             
//             [self getRank:myLenght ofCategory:category];
         }
     }];
}

//获取排行
- (void)getRank:(int) maxrange_ ofCategory:(NSString*) category
{
    GKLeaderboard *leaderboardRequest = [[GKLeaderboard alloc] initWithPlayerIDs:[NSArray arrayWithObject:[GKLocalPlayer localPlayer].playerID]];
    if (leaderboardRequest != nil)
    {
        leaderboardRequest.timeScope = GKLeaderboardTimeScopeAllTime;
        leaderboardRequest.range = NSMakeRange(1,1);
        leaderboardRequest.category = category;
        [leaderboardRequest loadScoresWithCompletionHandler: ^(NSArray *scores, NSError *error) {
            if (error != nil){
                // handle the error.
                NSLog(@"rank下载失败");
            }else
            if ([leaderboardRequest.scores count]>0) {
                
                GKScore *localInfo = [leaderboardRequest.scores objectAtIndex:0];
                double rank = (double)(maxrange_ - localInfo.rank + 1);
                double percent =rank / maxrange_;
                int rankLocal = localInfo.rank;
                InGCHelper::shareIAP()->_callBack(rankLocal, percent);
                NSLog(@"rank下载成功 %f =  %f / %d",percent,rank,maxrange_);
            }
        }];
    }
}

//检索已登录用户好友列表
- (void) retrieveFriends
{
    GKLocalPlayer *lp = [GKLocalPlayer localPlayer];
    if (lp.authenticated)
    {
        [lp loadFriendsWithCompletionHandler:^(NSArray *friends, NSError *error) {
            if (error == nil)
            {
                [self loadPlayerData:friends];
                NSLog(@"wo no have friends");
            }
            else
            {
                NSLog(@"load friends error");;// report an error to the user.
            }
        }];
        
    }
}
//上面的friends得到的只是一个身份列表,里面存储的是NSString,想要转换成好友ID,必须调用- (void) loadPlayerData: (NSArray *) identifiers方法,该方法得到的array里面存储的才是GKPlayer对象.如下
/*
 2. Whether you received player identifiers by loading the identifiers for the local player’s
 3. friends, or from another Game Center class, you must retrieve the details about that player
 4. from Game Center.
 5. */
- (void) loadPlayerData: (NSArray *) identifiers
{
    [GKPlayer loadPlayersForIdentifiers:identifiers withCompletionHandler:^(NSArray *players, NSError *error) {
        if (error != nil)
        {
            // Handle the error.
        }
        if (players != nil)
        {
            NSLog(@"得到好友的alias成功");
            GKPlayer *friend1 = [players objectAtIndex:0];
            NSLog(@"friedns---alias---%@",friend1.alias);
            NSLog(@"friedns---isFriend---%d",friend1.isFriend);
            NSLog(@"friedns---playerID---%@",friend1.playerID);
        }
    }];
}

/*
 对于一个玩家可见的成就,你需要尽可能的报告给玩家解锁的进度;对于一个一部完成的成就,则不需要,当玩家的进度达到100%的时候,会自动解锁该成就.
 其中该函数的参数中identifier是你成就的ID, percent是该成就完成的百分比
 */
- (void) reportAchievementIdentifier: (NSString*) identifier percentComplete: (float) percent
{
    GKAchievement *achievement = [[[GKAchievement alloc] initWithIdentifier: identifier] autorelease];
    if (achievement)
    {
        achievement.percentComplete = percent;
        [achievement reportAchievementWithCompletionHandler:^(NSError *error)
         {
             if (error != nil)
             {
                 //The proper way for your application to handle network errors is retain
                 //the achievement object (possibly adding it to an array). Then, periodically
                 //attempt to report the progress until it is successfully reported.
                 //The GKAchievement class supports the NSCoding protocol to allow your
                 //application to archive an achie
                 NSLog(@"报告成就进度失败 ,错误信息为: \n %@",error);
             }else {
                 //对用户提示,已经完成XX%进度
                 NSLog(@"报告成就进度---->成功!");
                 NSLog(@"    completed:%d",achievement.completed);
                 NSLog(@"    hidden:%d",achievement.hidden);
                 NSLog(@"    lastReportedDate:%@",achievement.lastReportedDate);
                 NSLog(@"    percentComplete:%f",achievement.percentComplete);
                 NSLog(@"    identifier:%@",achievement.identifier);
             }
         }];
    }
}
//函数中NSArray返回的是你的所有成就ID.
//读取成就
- (void) loadAchievements
{
    NSMutableDictionary *achievementDictionary = [[NSMutableDictionary alloc] init];
    [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements,NSError *error)
     {
         if (error == nil) {
             NSArray *tempArray = [NSArray arrayWithArray:achievements];
             for (GKAchievement *tempAchievement in tempArray) {
                 [achievementDictionary setObject:tempAchievement forKey:tempAchievement.identifier];
                 NSLog(@"    completed:%d",tempAchievement.completed);
                 NSLog(@"    hidden:%d",tempAchievement.hidden);
                 NSLog(@"    lastReportedDate:%@",tempAchievement.lastReportedDate);
                 NSLog(@"    percentComplete:%f",tempAchievement.percentComplete);
                 NSLog(@"    identifier:%@",tempAchievement.identifier);
             }
         }
     }];
}

//方法二:根据ID获取成就
- (GKAchievement*) getAchievementForIdentifier: (NSString*) identifier
{
    NSMutableDictionary *achievementDictionary = [[NSMutableDictionary alloc] init];
    GKAchievement *achievement = [achievementDictionary objectForKey:identifier];
    if (achievement == nil)
    {
        achievement = [[[GKAchievement alloc] initWithIdentifier:identifier] autorelease];
        [achievementDictionary setObject:achievement forKey:achievement.identifier];
    }
    return [[achievement retain] autorelease];
}

/*
 获取成就描述和图片
 在自定义界面中,玩家需要一个成就描述,以及该成就的图片,Game Center提供了该功能.当然,你也可以自己在程序中完成,毕竟玩家不可能时刻处于在线状态.
 */
- (NSArray*)retrieveAchievmentMetadata
{
    //读取成就的描述
    [GKAchievementDescription loadAchievementDescriptionsWithCompletionHandler:
     ^(NSArray *descriptions, NSError *error) {
         if (error != nil)
         {
             // process the errors
             NSLog(@"读取成就说明出错");
         }
         if (descriptions != nil)
         {
             // use the achievement descriptions.
             for (GKAchievementDescription *achDescription in descriptions) {
                 NSLog(@"1..identifier..%@",achDescription.identifier);
                 NSLog(@"2..achievedDescription..%@",achDescription.achievedDescription);
                 NSLog(@"3..title..%@",achDescription.title);
                 NSLog(@"4..unachievedDescription..%@",achDescription.unachievedDescription);
                 NSLog(@"5............%@",achDescription.image);
                 
                 //获取成就图片,如果成就未解锁,返回一个大文号
                 /*
                  [achDescription loadImageWithCompletionHandler:^(UIImage *image, NSError *error) {
                  if (error == nil)
                  {
                  // use the loaded image. The image property is also populated with the same image.
                  NSLog(@"成功取得成就的图片");
                  UIImage *aImage = image;
                  UIImageView *aView = [[UIImageView alloc] initWithImage:aImage];
                  aView.frame = CGRectMake(50, 50, 200, 200);
                  aView.backgroundColor = [UIColor clearColor];
                  [[[CIDetector sharedDirector] openGLView] addSubview:aView];
                  }else {
                  NSLog(@"获得成就图片失败");
                  }
                  }];
                  */
             }
         }
     }];
    return nil;
}



//打开 GameCenter 界面，有待优化，分别打开成就和分数界面
- (void)showGameCenter:(UIViewController *)viewController
{
    if (!gameCenterAvailable) return;
    self.presentingViewController = viewController;
    [presentingViewController dismissModalViewControllerAnimated:NO];
    
    GKLeaderboardViewController *leaderboardController = [[GKLeaderboardViewController alloc] init];
    [leaderboardController setLeaderboardDelegate:self];
    [presentingViewController presentModalViewController:leaderboardController animated: YES];
    [leaderboardController release];
}

- (void)showLeaderboard:(UIViewController *)viewController
{
    if (!gameCenterAvailable) return;
    self.presentingViewController = viewController;
    [presentingViewController dismissModalViewControllerAnimated:NO];
    
    GKLeaderboardViewController *leaderboardController = [[GKLeaderboardViewController alloc] init];
    [leaderboardController setLeaderboardDelegate:self];
    [presentingViewController presentModalViewController:leaderboardController animated: YES];
    [leaderboardController release];
}

- (void)showAchievement:(UIViewController *)viewController
{
    if (!gameCenterAvailable) return;
    self.presentingViewController = viewController;
    [presentingViewController dismissModalViewControllerAnimated:NO];
    
    GKAchievementViewController *achievementController = [[GKAchievementViewController alloc] init];
    [achievementController setAchievementDelegate:self];
    [presentingViewController presentModalViewController:achievementController animated: YES];
    [achievementController release];
}

- (void)findMatchWithMinPlayers:(int)minPlayers maxPlayers:(int)maxPlayers viewController:(UIViewController *)viewController delegate:(int) theDelegate {
    
    if (!gameCenterAvailable) return;
    
//    matchStarted = NO;
//    self.match = nil;
//    self.presentingViewController = viewController;
//    delegate = theDelegate;               
//    [presentingViewController dismissModalViewControllerAnimated:NO];
//    
//    GKMatchRequest *request = [[[GKMatchRequest alloc] init] autorelease]; 
//    request.minPlayers = minPlayers;     
//    request.maxPlayers = maxPlayers;
//    
//    GKMatchmakerViewController *mmvc = [[[GKMatchmakerViewController alloc] initWithMatchRequest:request] autorelease];    
//    mmvc.matchmakerDelegate = self;
//    
//    [presentingViewController presentModalViewController:mmvc animated:YES];
    self.presentingViewController = viewController;
    [presentingViewController dismissModalViewControllerAnimated:NO];
    
    GKLeaderboardViewController *leaderboardController = [[GKLeaderboardViewController alloc] init];
    [leaderboardController setLeaderboardDelegate:self];
    [presentingViewController presentModalViewController:leaderboardController animated: YES];
    [leaderboardController release];
    
}

- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	[presentingViewController dismissModalViewControllerAnimated: YES];
}

- (void)achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
    [presentingViewController dismissModalViewControllerAnimated: YES];
}

#pragma mark GKMatchmakerViewControllerDelegate

// The user has cancelled matchmaking
- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController {
    [presentingViewController dismissModalViewControllerAnimated:YES];
}

// Matchmaking has failed with an error
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error {
    [presentingViewController dismissModalViewControllerAnimated:YES];
    NSLog(@"Error finding match: %@", error.localizedDescription);    
}

// A peer-to-peer match has been found, the game should start
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)theMatch {
    [presentingViewController dismissModalViewControllerAnimated:YES];
    self.match = theMatch;
    match.delegate = self;
    if (!matchStarted && match.expectedPlayerCount == 0) {
        NSLog(@"Ready to start match!");
    }
}

#pragma mark GKMatchDelegate

// The match received data sent from the player.
- (void)match:(GKMatch *)theMatch didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID {
    
    if (match != theMatch) return;
    
    [delegate match:theMatch didReceiveData:data fromPlayer:playerID];
}

// The player state changed (eg. connected or disconnected)
- (void)match:(GKMatch *)theMatch player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state {
    
    if (match != theMatch) return;
    
    switch (state) {
        case GKPlayerStateConnected: 
            // handle a new player connection.
            NSLog(@"Player connected!");
            
            if (!matchStarted && theMatch.expectedPlayerCount == 0) {
                NSLog(@"Ready to start match!");
            }
            
            break; 
        case GKPlayerStateDisconnected:
            // a player just disconnected. 
            NSLog(@"Player disconnected!");
            matchStarted = NO;
            [delegate matchEnded];
            break;
    }                 
    
}

// The match was unable to connect with the player due to an error.
- (void)match:(GKMatch *)theMatch connectionWithPlayerFailed:(NSString *)playerID withError:(NSError *)error {
    
    if (match != theMatch) return;
    
    NSLog(@"Failed to connect to player with error: %@", error.localizedDescription);
    matchStarted = NO;
    [delegate matchEnded];
}

// The match was unable to be established with any players due to an error.
- (void)match:(GKMatch *)theMatch didFailWithError:(NSError *)error {
    
    if (match != theMatch) return;
    
    NSLog(@"Match failed with error: %@", error.localizedDescription);
    matchStarted = NO;
    [delegate matchEnded];
}

@end


/////////////////////////////////////////////////////////////////////
//                  苹果的游戏中心
//            1.库支持： GameKit.framework
//            2.初始化 [[GCHelper sharedInstance] authenticateLocalUser];
/////////////////////////////////////////////////////////////////////


InGCHelper *InGCHelper::shareIAP()
{
    static InGCHelper * helper=NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        helper= new InGCHelper;
    });
    return helper;
}

void InGCHelper::initGC()
{
    [[GCHelper sharedInstance] authenticateLocalUser];
}

void InGCHelper::showGameCenter()
{
    UIViewController *result = nil;
    
    UIWindow *topWindow = [[UIApplication sharedApplication] keyWindow];
    
    if (topWindow.windowLevel != UIWindowLevelNormal){
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(topWindow in windows){
            if (topWindow.windowLevel == UIWindowLevelNormal){
                break;
            }
        }
    }
    UIView *rootView = [[topWindow subviews] objectAtIndex:0];
    id nextResponder = [rootView nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]]){
        
        result = nextResponder;
        
    }else if ([topWindow respondsToSelector:@selector(rootViewController)] && topWindow.rootViewController != nil){
        
        result = topWindow.rootViewController;
        
    }
    [[GCHelper sharedInstance] showGameCenter:result];
}

void InGCHelper::updateGC(std::string identifer, int score)
{
    NSString *_identifier = [NSString stringWithUTF8String:identifer.c_str()];
    [[GCHelper sharedInstance] reportScore:score forCategory:_identifier];
}

void InGCHelper::getRank(std::string identifer)
{
    NSString *_identifier = [NSString stringWithUTF8String:identifer.c_str()];
    [[GCHelper sharedInstance] getMaxRange:_identifier];
}

void InGCHelper::setGCcallBack(const ccGCcallBack &call)
{
    _callBack = call;
}





