//
//  AdVideoManager.m
//  sdkIOSDemo
//
//  Created by JustinYang on 16/8/26.
//
//

#import "ZYVideoManager.h"
#import "ZYVideoType.h"
#import "ZYVideoAdRegistry.h"
#import "AFNetworking.h"
#import "ZYVideoClassWrapper.h"


#define ZY_HOST                 @"http://121.42.183.124"
#define ZY_PORT                 @"80"
#define ZY_URL_VIDEO            @"ZYGameServer/app/v1/gameConverge"



@interface ZYVideoManager()
@property (nonatomic, retain) NSMutableDictionary* videoDict;
@property (nonatomic, retain) NSMutableDictionary* successDict;
@property (nonatomic, retain) ZYVideoAdapter *currAdapter;
@property (nonatomic, retain) NSString* currVideoType;
@property (nonatomic)    BOOL isShowLog;
@property (nonatomic, retain) UIActivityIndicatorView * Indicator;
@property (nonatomic, retain) NSString *zongyiKey;
@end


@implementation ZYVideoManager

+ (ZYVideoManager *)sharedManager {
    static ZYVideoManager *registry = nil;
    if (registry == nil) {
        registry = [[ZYVideoManager alloc] init];
    }
    return registry;
}

- (id)init{
    self = [super init];
    if (self) {
        _isShowLog = NO;
        _videoDict = [[NSMutableDictionary alloc] init];
        _successDict = [[NSMutableDictionary alloc] init];
        _repeatTimes = 5;
        _isLock = NO;
        
        //读取plist
        NSMutableDictionary *tmpDict = [[NSMutableDictionary alloc] init];
        NSString *bundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"ZYSdk.bundle"];
        NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
        NSString *plistPath = [bundle pathForResource:@"appConfig" ofType:@"plist"];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
        _zongyiKey = [dict objectForKey:@"zongyi_key"];
        
    }
    return self;
}

- (void)loadVideoConfig
{
    NSString *url = [NSString stringWithFormat:@"%@:%@/%@/%@",ZY_HOST,ZY_PORT,ZY_URL_VIDEO,_zongyiKey];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    if(self.isShowLog)NSLog(@"视频聚合:获取配置=>%@",url);
    
    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:nil];
        
        if(self.isShowLog)NSLog(@"视频聚合:获取配置<=%@",dic);
        NSString* code = dic[@"code"];
        if (code && code.intValue == 0) {
            NSArray *dataList= dic[@"dataList"];
            if (dataList && [dataList count] > 0) {
                [self dealWithJsonData:dataList];
                _repeatTimes = 10;
            }
        }else{
            NSString* message = dic[@"message"];
            NSLog(@"视频聚合:获取配置－%@",message);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if(self.isShowLog)NSLog(@"视频聚合:获取配置网络异常 -%@", error);
        [NSTimer scheduledTimerWithTimeInterval:_repeatTimes target:self selector:@selector(loadVideoConfig) userInfo:nil repeats:NO];
        _repeatTimes += 10;
    }];
    
    
//    NSString* testJson = @"{\"code\":0,\"dataCount\":2,\"message\":\"成功\",\"dataList\":[{\"adName\":\"Vungle\",\"adId\":\"577b14217498d903690000be\",\"adKey\":\"ssss\",\"rate\":50},{\"adName\":\"Applovin\",\"adId\":\"ssss\",\"adKey\":\"ssss\",\"rate\":50}]}";
//    NSData *resData = [[NSData alloc] initWithData:[testJson dataUsingEncoding:NSUTF8StringEncoding]];
//    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:resData options:NSJSONReadingMutableLeaves error:nil];
//
//    if(self.isShowLog)NSLog(@"视频聚合:获取配置<=%@",dic);
//    NSString* code = dic[@"code"];
//    if (code && code.intValue == 0) {
//        NSArray *dataList= dic[@"dataList"];
//        if (dataList && [dataList count] > 0) {
//            [self dealWithJsonData:dataList];
//            _repeatTimes = 10;
//        }
//    }else{
//        NSString* message = dic[@"message"];
//        NSLog(@"视频聚合:获取配置－%@",message);
//    }
}


- (void)dealWithJsonData:(NSArray*)dataList
{
    for (int index = 0; index < [dataList count]; index++) {
        NSDictionary *videoEnt = dataList[index];
        NSString *videoPlatem = videoEnt[@"adName"];
        NSString *videoKey = [self getVideoType:videoPlatem];
        NSString *videoAdID = videoEnt[@"adId"];
        NSString *videoAdKey = videoEnt[@"adKey"];
        NSString *videoRate = videoEnt[@"rate"];
        //概率保存
        if (videoKey) {
            //初始化
            NSDictionary *classDict = [[ZYVideoAdRegistry sharedRegistry] getClassesDict];
            ZYVideoClassWrapper *wrapper = classDict[videoKey];
            if (wrapper) {
                ZYVideoAdapter *adapter = [[wrapper.theClass alloc] init];
                adapter.appid = videoAdID;
                adapter.appsrec = videoAdKey;
                adapter.delegate = self;
                adapter.isShowLog = self.isShowLog;//是不是显示log
                [adapter initAd];
                if (videoRate) {
                    wrapper.theEnable = YES;
                    int nRate = (int)videoRate.floatValue;
                    [_videoDict setObject:[NSNumber numberWithInt:nRate] forKey:videoKey];
                }
            }else{
                if(self.isShowLog)NSLog(@"视频聚合:没有这个平台的sdk存在：%@",videoKey);
            }
        }
    }
}


- (void)loadNextVideo:(ZYVideoAdapter*)adapter
{
    [NSTimer scheduledTimerWithTimeInterval:_repeatTimes target:adapter selector:@selector(getAd) userInfo:nil repeats:NO];
    _repeatTimes += 10;
}


- (NSString*)getVideoType:(NSString*)platemName
{
    if ([platemName isEqualToString:@"Vungle"]) {
        return [NSString stringWithFormat:@"%d",ZYVideoVungle];
    }else if ([platemName isEqualToString:@"Joying"]) {
        return [NSString stringWithFormat:@"%d",ZYVideoJoying];
    }else if ([platemName isEqualToString:@"Applovin"]) {
        return [NSString stringWithFormat:@"%d",ZYVideoApplovin];
    }
    return nil;
}


- (void)showVideo:(UIViewController *)viewController begin:(beginPlay)begin pause:(pausePlay)pause finish:(finishPlay)finish
{
    if (_isLock) {
        //防止连点
        return;
    }
    _isLock = YES;
    
    //设置回调
    _beginPlay = begin;
    _pausePlay = pause;
    _finishPlay = finish;
    
    
    if ([_successDict count] >= 1) {
        self.Indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        //只能设置中心，不能设置大小
        self.Indicator.center = CGPointMake(CGRectGetMidX(viewController.view.frame), CGRectGetMidY(viewController.view.frame));
        [viewController.view addSubview:self.Indicator];
        [self.Indicator startAnimating];
        
        //随机一个平台id
        int nTotalPercent = 0;
        for (NSString*key in _successDict) {
            NSNumber *rate = _videoDict[key];
            nTotalPercent += rate.intValue;
        }
        int randvalue = rand()%nTotalPercent;
        for (NSString *key in _successDict) {
            NSNumber *rate = _videoDict[key];
            randvalue -= rate.intValue;
            if (randvalue <= 0) {
                ZYVideoAdapter *adapter = _successDict[key];
                _currAdapter = adapter;
                [_currAdapter showVideo:viewController];
                [_successDict removeObjectForKey:key];
                break;
            }
        }
    }else{
        if(self.isShowLog)NSLog(@"视频聚合:目前没有视频可以观看");
    }
}


- (void)isHasVideo:(isHasVideo)isHasBack
{
    _isHasCall = isHasBack;
}


- (void)showLog
{
    _isShowLog = YES;
}



- (void)success:(ZYVideoAdapter*)adapter withType:(ZYVideoType)type
{
    NSString *key = [NSString stringWithFormat:@"%d",type];
    if (!_successDict[key]) {
        [_successDict setObject:adapter forKey:key];
    }
    if(self.isShowLog)NSLog(@"视频聚合:视频缓存数组:%@",_successDict);
    
    [self.Indicator stopAnimating];
    [self.Indicator removeFromSuperview];
    
    if (_successDict.count > 0) {
        //显示按钮
        if (_isHasCall)_isHasCall(YES);
    }else{
        if (_isHasCall)_isHasCall(NO);
    }
}

- (void)failure:(ZYVideoAdapter*)adapter withType:(ZYVideoType)type
{
    //加载失败之后，
    [self loadNextVideo:adapter];
}

- (void)play:(ZYVideoAdapter*)adapter withType:(ZYVideoType)type
{
    if (_beginPlay) {
        _beginPlay();
    }
    [self.Indicator stopAnimating];
    [self.Indicator removeFromSuperview];

    //加载下一个视频
    [_currAdapter getAd];
    
    if (_successDict.count > 0) {
        //显示按钮
        if (_isHasCall)_isHasCall(YES);
    }else{
        //隐藏按钮
        if (_isHasCall)_isHasCall(NO);
    }
    _isLock = NO;
}

- (void)pause:(ZYVideoAdapter*)adapter withType:(ZYVideoType)type
{
    if (_pausePlay) {
        _pausePlay();
    }
}

- (void)finish:(ZYVideoAdapter*)adapter withType:(ZYVideoType)type
{
    [self.Indicator stopAnimating];
    [self.Indicator removeFromSuperview];
    if (_finishPlay) {
        _finishPlay();
    }
}




@end
