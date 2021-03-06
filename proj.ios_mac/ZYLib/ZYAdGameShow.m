//
//  ZYAdGameShow.m
//  sdkIOSDemo
//
//  Created by JustinYang on 16/9/6.
//
//

#import "ZYAdGameShow.h"
#import "ZYGameServer.h"
#import "ZYGameInfo.h"
#import "ZYAdStatistics.h"
#import "ZYParamOnline.h"



#define cellDistance        8
#define IMAGE_WIDTH         620
#define IMAGE_HEIGHT        910


#define OPENTYPE_NONE       0
#define OPENTYPE_DIRECT     1
#define OPENTYPE_CIRCLE     2
#define OPENTYPE_TRIANGLE   3



@interface ZYAdGameShow()<UIScrollViewDelegate,UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate>
{
    //大图页数
    int currPageNum;
    //图片的缩放比例
    float adImageRate;
    //打开方式
    int _openType;
    //三角形位置
    int _trianleType;
    //显示与否
    bool _circleVisible;
    bool _triangleVisible;
    //page
    int _circlePage;
    int _trianglePage;
}
@property (strong, nonatomic) UIScrollView *scrollView;
//@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIView *view;
@property (strong, nonatomic) UIView *buttonView;
@property (strong, nonatomic) UIButton *triButton;
@property (strong, nonatomic) UIButton *buttonLeft;
@property (strong, nonatomic) UIButton *buttonRight;
@property (strong, nonatomic) NSMutableArray *adZynoArray;
@property (strong, nonatomic) NSMutableArray *adDefaultList;
@property (nonatomic, assign) CGPoint btnViewPos;
@property (nonatomic, assign) CGFloat btnScale;
@property (nonatomic, assign) CGFloat winWidth;
@property (nonatomic, assign) CGFloat winHeight;
@end

@implementation ZYAdGameShow


+ (ZYAdGameShow*)shareShow
{
    static ZYAdGameShow* s_share = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_share = [[ZYAdGameShow alloc] init];
    });
    return s_share;
}


- (id)init
{
    self = [super init];
    if (self) {
        
        _btnViewPos = CGPointMake(0.2, 0.20);
        _btnScale = 1.0;
        _openType = OPENTYPE_NONE;
        currPageNum = 0;
        _circleVisible = NO;
        _circlePage = 0;
        _triangleVisible = NO;
        _trianglePage = 0;
        
        _adZynoArray = [[NSMutableArray alloc] init];
        _adDefaultList = [[NSMutableArray alloc] init];
        
        
        //屏幕适配
        CGRect winSize = [[UIScreen mainScreen] bounds];
        UIDeviceOrientation orientation = (UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation;
        BOOL bIsLand = UIDeviceOrientationIsLandscape(orientation);
        
        _winWidth = winSize.size.width;
        _winHeight = winSize.size.height;
        
        if (bIsLand) {
            _winWidth = winSize.size.height>winSize.size.width?winSize.size.height:winSize.size.width;
            _winHeight = winSize.size.height<winSize.size.width?winSize.size.height:winSize.size.width;
        }
        
        {
            float winWidth = (_winWidth > _winHeight)?_winHeight:_winWidth;
            float winHeight = (_winWidth > _winHeight)?_winWidth:_winHeight;
            float rateScreent = winWidth/winHeight;
            if (rateScreent > 0.67) {
                //ipad height* 0.8
                adImageRate = winHeight*0.85/IMAGE_HEIGHT;
            }else{
                //iphone width* 0.8
                adImageRate = winWidth*0.85/IMAGE_WIDTH;
            }
        }
        
        
        self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _winWidth, _winHeight)];
        self.view.userInteractionEnabled = YES;
        
        //设置回调
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willEnterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangedStatusBarOrientation:)
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification
                                                   object:nil];
    }
    return self;
}

- (void)willEnterForeground
{
    
}

- (void)didChangedStatusBarOrientation:(NSNotification*)n {
    
}

#pragma mark public method

- (void)showAdGame:(UIView*)mainView
{
//    self.view = mainView;
    [mainView addSubview:self.view];
}

- (void)showDirect
{
    NSString* adGame = [[ZYParamOnline shareParam] getParamOf:@"ZYAdgame"];
    if (adGame.intValue != 1) {
        return;
    }
    
    if (_openType == OPENTYPE_NONE) {
        _openType = OPENTYPE_DIRECT;
        [self addAdGameView:0];
    }
}


- (void)showCircle:(CGPoint)pot Scale:(CGFloat)scale
{
    NSString* adGame = [[ZYParamOnline shareParam] getParamOf:@"ZYAdgame"];
    if (adGame.intValue != 1) {
        return;
    }
   
    _btnViewPos = pot;
    _btnScale = scale;
    _circleVisible = YES;
    [self addCircleButton];
}

- (void)hideCircle
{
    _circleVisible = NO;
    [self removeCircleButton];
}


- (void)showTriangle:(int)potType Scale:(CGFloat)scale
{
    NSString* adGame = [[ZYParamOnline shareParam] getParamOf:@"ZYAdgame"];
    if (adGame.intValue != 1) {
        return;
    }
    
    _trianleType = potType;
    _triangleVisible = YES;
    [self addTriangleButton:scale];
}

- (void)hideTriangle
{
    _triangleVisible = NO;
    [self removeTriangleButton];
}


#pragma mark private method

//创建圆形按钮
- (void)addCircleButton
{
    [self.buttonView removeFromSuperview];
    NSString* adGame = [[ZYParamOnline shareParam] getParamOf:@"ZYAdgame"];
    if (adGame.intValue != 1 || !_circleVisible) {
        return;
    }
    NSArray* list = [[ZYGameServer shareServer] getGameZynoArray];
    if (!list || [list count] == 0) {
        [self addMoreGameButton];
        return;
    }
    int nCount = rand()%(list.count+1);
    if (nCount==list.count) {
        _circlePage = nCount;
        [self addMoreGameButton];
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *adDic = [[ZYGameServer shareServer] getGameInfoDic];
    ZYGameInfo* info = adDic[list[nCount]];
    NSString* buttonPath = [self getFilePath:info.button];
    NSString* buttonFlashPath = [self getFilePath:info.buttonFlash];
    NSString* imgPath = [self getFilePath:info.img];
    if ([fileManager fileExistsAtPath:buttonPath]
        &&
        [fileManager fileExistsAtPath:buttonFlashPath]
        &&
        [fileManager fileExistsAtPath:imgPath] ) {
        
        _circlePage = nCount;
        
        UIImage*image = [UIImage imageWithContentsOfFile:buttonPath];
        CGFloat imageWidth = image.size.width*adImageRate;
        CGFloat imageHeight = image.size.height*adImageRate;
        self.buttonView = [[UIView alloc] initWithFrame:CGRectMake(_winWidth*_btnViewPos.x-imageWidth/2, _winHeight*_btnViewPos.y-imageHeight/2, imageWidth, imageHeight)];
        [self.view addSubview:self.buttonView];
        
//        UITapGestureRecognizer *singleTap =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onCircleClickOpen)];
//        [self.buttonView addGestureRecognizer:singleTap];
//        self.buttonView.userInteractionEnabled=YES;
        
        
        CGFloat disWidth = image.size.width*adImageRate*0.15/2;
        CGFloat disHeight = image.size.height*adImageRate*0.15/2;
        UIView *clipView = [[UIView alloc] initWithFrame:CGRectMake( disWidth, disHeight, image.size.width*adImageRate*0.85, image.size.height*adImageRate*0.85)];
        [clipView setClipsToBounds:YES];
        clipView.layer.cornerRadius = 90*adImageRate;
        clipView.layer.masksToBounds = YES;
        clipView.layer.transform = CATransform3DMakeScale(_btnScale, _btnScale, 1.0);
        [self.buttonView addSubview:clipView];
        
        UIImage*imageFlash = [UIImage imageWithContentsOfFile:buttonFlashPath];
        UIImageView* imageView1 = [[UIImageView alloc] initWithImage:imageFlash];
        imageView1.frame = CGRectMake(-disWidth, -disHeight, imageFlash.size.width*adImageRate, imageFlash.size.height*adImageRate);
        [clipView addSubview:imageView1];
        
        [UIView animateWithDuration:3.0 // 动画时长
                         animations:^{
                             imageView1.frame = CGRectMake(image.size.width*adImageRate-imageFlash.size.width*adImageRate-disWidth, image.size.height*adImageRate-imageFlash.size.height*adImageRate-disHeight, imageFlash.size.width*adImageRate, imageFlash.size.height*adImageRate);
                         }];
        
//        UIImageView *buttonImage = [[UIImageView alloc] initWithImage:image];
//        buttonImage.frame = CGRectMake(0, 0, image.size.width*adImageRate, image.size.height*adImageRate);
//        buttonImage.layer.transform = CATransform3DMakeScale(_btnScale, _btnScale, 1.0);
//        [self.buttonView addSubview:buttonImage];
        
        UIButton* buttonImage = [UIButton buttonWithType:UIButtonTypeCustom];//button的类型
        [buttonImage setBackgroundImage:image forState:UIControlStateNormal];
        [buttonImage addTarget:self action:@selector(onCircleClickOpen) forControlEvents:UIControlEventTouchUpInside];
        [self.buttonView addSubview:buttonImage];
        buttonImage.frame = CGRectMake(0, 0, image.size.width*adImageRate, image.size.height*adImageRate);
        buttonImage.layer.transform = CATransform3DMakeScale(_btnScale, _btnScale, 1.0);
        
        
        [self shakeToShow:self.buttonView];
        
        [[ZYAdStatistics shareStatistics] statistics:info.zyno andKey:@"iconShow"];
        
        return;
    }
    NSLog(@"进入循环模式");
    //如果一直没有就间隔时间再进行
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(addCircleButton) userInfo:nil repeats:NO];
}


- (void)addMoreGameButton
{
    NSArray* listDefault = [[ZYGameServer shareServer] getDefaultArray];
    if (listDefault && listDefault.count> 0) {
        UIImage*image = [self imagesNamedFromCustomBundle:@"zyadmore"];
        CGFloat imageWidth = image.size.width*adImageRate;
        CGFloat imageHeight = image.size.height*adImageRate;
        
        self.buttonView = [[UIView alloc] initWithFrame:CGRectMake(_winWidth*_btnViewPos.x-imageWidth/2, _winHeight*_btnViewPos.y-imageHeight/2, imageWidth, imageHeight)];
        [self.view addSubview:self.buttonView];
        
//        UIImageView*buttonImage = [[UIImageView alloc] initWithImage:image];
//        buttonImage.frame = CGRectMake(0, 0, image.size.width*adImageRate, image.size.height*adImageRate);
//        buttonImage.layer.transform = CATransform3DMakeScale(_btnScale, _btnScale, 1.0);
//        [self.buttonView addSubview:buttonImage];
        UIButton* buttonImage = [UIButton buttonWithType:UIButtonTypeCustom];//button的类型
        [buttonImage setBackgroundImage:image forState:UIControlStateNormal];
        [buttonImage addTarget:self action:@selector(onCircleClickOpen) forControlEvents:UIControlEventTouchUpInside];
        [self.buttonView addSubview:buttonImage];
        buttonImage.frame = CGRectMake(0, 0, image.size.width*adImageRate, image.size.height*adImageRate);
        buttonImage.layer.transform = CATransform3DMakeScale(_btnScale, _btnScale, 1.0);
        
        [self shakeToShow:self.buttonView];
    }
}

//圆形按钮动画
- (void) shakeToShow:(UIView*)aView{
    CAKeyframeAnimation* animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animation.duration = 0.8;
    animation.repeatCount = MAXFLOAT;
    animation.removedOnCompletion = NO;
    
    NSMutableArray *values = [NSMutableArray array];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.9, 0.9, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)]];
    animation.values = values;
    [aView.layer addAnimation:animation forKey:nil];
}

//删除圆形按钮
- (void)removeCircleButton
{
    //remove button
    [self.buttonView removeFromSuperview];
}

//创建三角按钮
- (void)addTriangleButton:(CGFloat)scale
{
    [self.triButton removeFromSuperview];
    NSString* adGame = [[ZYParamOnline shareParam] getParamOf:@"ZYAdgame"];
    if (adGame.intValue != 1 || !_triangleVisible) {
        return;
    }
    
    NSArray* list = [[ZYGameServer shareServer] getGameZynoArray];
    if (!list || [list count] == 0) {
        [self addMoreTriangleButton:scale];
        return;
    }
    
    int nCount = rand()%(list.count+1);
    if (nCount==list.count) {
        _trianglePage = nCount;
        [self addMoreTriangleButton:scale];
        return;
    }
    
    if (list && [list count] > 0 && nCount < [list count]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSDictionary *adDic = [[ZYGameServer shareServer] getGameInfoDic];
        ZYGameInfo* info = adDic[list[nCount]];
        NSString* buttonPath = [self getFilePath:info.triButton];
        NSString* imgPath = [self getFilePath:info.img];
        if ([fileManager fileExistsAtPath:buttonPath]
            &&
            [fileManager fileExistsAtPath:imgPath] ) {
            //page
            _trianglePage = nCount;
            //按钮
            UIImage*image = [UIImage imageWithContentsOfFile:buttonPath];
            int imageWidth = image.size.width*adImageRate;
            int imageHeight = image.size.height*adImageRate;
            self.triButton = [UIButton buttonWithType:UIButtonTypeCustom];//button的类型
            [self.triButton setBackgroundImage:image forState:UIControlStateNormal];
            [self.triButton addTarget:self action:@selector(onTriangleClickOpen) forControlEvents:UIControlEventTouchUpInside];
            [self.view addSubview:self.triButton];
            self.triButton.frame = CGRectMake(0, 0, imageWidth*scale, imageHeight*scale);//button的frame

            return;
        }
    }
//    NSLog(@"进入循环模式");
    //如果一直没有就间隔时间再进行
//    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(addTriangleButton:) userInfo:nil repeats:NO];
}

- (void)addMoreTriangleButton:(CGFloat)scale
{
    NSArray* listDefault = [[ZYGameServer shareServer] getDefaultArray];
    if (listDefault && listDefault.count> 0) {
        UIImage*image = [self imagesNamedFromCustomBundle:@"zyadmoretri"];
        int imageWidth = image.size.width*adImageRate;
        int imageHeight = image.size.height*adImageRate;
        self.triButton = [UIButton buttonWithType:UIButtonTypeCustom];//button的类型
        [self.triButton setBackgroundImage:image forState:UIControlStateNormal];
        [self.triButton addTarget:self action:@selector(onTriangleClickOpen) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.triButton];
        self.triButton.frame = CGRectMake(0, 0, imageWidth*scale, imageHeight*scale);//button的frame
    }
}

//删除三角按钮
-(void)removeTriangleButton
{
    [self.triButton removeFromSuperview];
}


//创建大图界面
- (void)addAdGameView:(int)page
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [_adZynoArray removeAllObjects];
    int count = 0;
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, _winWidth, _winHeight)];
    self.scrollView.pagingEnabled = YES;
    self.scrollView.clipsToBounds = NO;
    self.scrollView.delegate = self;
    self.scrollView.contentSize = CGSizeMake(_winWidth, _winHeight);
    
    //add scroll view
    NSArray*list = [[ZYGameServer shareServer] getGameZynoArray];
    if (list && [list count] > 0) {
        for (id value in list) {
            ZYGameInfo* info = [[ZYGameServer shareServer] getGameInfoDic][value];
            NSString* buttonPath = [self getFilePath:info.button];
            NSString* imgPath = [self getFilePath:info.img];
            if ([fileManager fileExistsAtPath:buttonPath]
                &&
                [fileManager fileExistsAtPath:imgPath]) {
                //添加数组
                [_adZynoArray addObject:info.zyno];
                count++;
                CGFloat width = CGRectGetWidth(self.scrollView.frame);
                CGFloat height = CGRectGetHeight(self.scrollView.frame);
                
                CGFloat x = self.scrollView.subviews.count * width;
                
                UIImage*image = [UIImage imageWithContentsOfFile:imgPath];
                UIImageView* imageView = [[UIImageView alloc] initWithImage:image];
                int adImageWidth = image.size.width*adImageRate;
                int adImageHeight = image.size.height*adImageRate;
                imageView.frame = CGRectMake((_winWidth-adImageWidth)/2+x, (_winHeight-adImageHeight)/2, adImageWidth, adImageHeight);
                [self.scrollView addSubview:imageView];
                self.scrollView.contentSize = CGSizeMake(x + width, height);
                UITapGestureRecognizer *singleTap =[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onClickImage)];
                [imageView addGestureRecognizer:singleTap];
                imageView.userInteractionEnabled = YES;
                
                UIImage *imageYes = [self imagesNamedFromCustomBundle:@"zyadopen"];
                int imageYesWidth = imageYes.size.width*adImageRate;
                int imageYesHeight = imageYes.size.height*adImageRate;
                UIImageView*buttonYes = [[UIImageView alloc] initWithFrame:CGRectMake(adImageWidth-imageYesWidth-25, adImageHeight-imageYesHeight-25, imageYesWidth, imageYesHeight)];
                buttonYes.image = imageYes;
                [imageView addSubview:buttonYes];
                
                UIImage* imageNo = [self imagesNamedFromCustomBundle:@"zyadclose"];
                int imageNoWidth = imageNo.size.width*adImageRate;
                int imageNoHeight = imageNo.size.height*adImageRate;
                UIButton *buttonNo = [UIButton buttonWithType:UIButtonTypeCustom];//button的类型
                [buttonNo setBackgroundImage:imageNo forState:UIControlStateNormal];
                buttonNo.frame = CGRectMake(25, adImageHeight-imageNoHeight-25, imageNoWidth, imageNoHeight);//button的frame
                [buttonNo addTarget:self action:@selector(onClickClose) forControlEvents:UIControlEventTouchUpInside];
                [imageView addSubview:buttonNo];
                
                //是否显示有奖励
                if (info.reward.intValue > 0 && ![info.rewardId isEqualToString:@""] ) {
                    UIImage* imageGift = [self imagesNamedFromCustomBundle:@"zyadgift"];
                    int imageGiftWidth = imageGift.size.width*adImageRate;
                    int imageGiftHeight = imageGift.size.height*adImageRate;
                    UIImageView* imageGiftView = [[UIImageView alloc] initWithImage:imageGift];
                    imageGiftView.frame = CGRectMake(adImageWidth-imageGiftWidth/2-20, -imageGiftHeight/2+20, imageGiftWidth, imageGiftHeight);
                    [imageView addSubview:imageGiftView];
                    [self giftShake:imageGiftView];
                    
                    UITapGestureRecognizer *singleTapGift =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClickImage)];
                    singleTapGift.delegate = self;
                    [imageGiftView addGestureRecognizer:singleTapGift];
                    
                    //添加提示文字
                    UILabel *labelTip = [[UILabel alloc] initWithFrame:CGRectMake(-(_winWidth-adImageWidth)/2+15, adImageHeight-40, _winWidth-30, 100)];
                    labelTip.text = @"下载并体验此应用可以获得奖励哦！\n注意：点击本页跳转App Store下载，并联网进入该应用。之后返回当前应用即可领取奖励。";
                    labelTip.shadowColor = [UIColor blackColor];//默认没有阴影
                    labelTip.shadowOffset = CGSizeMake(1,1);
                    labelTip.numberOfLines = 0;
                    labelTip.textColor = [UIColor colorWithRed:(1) green:(1) blue:(1) alpha:1];
                    labelTip.font = [UIFont systemFontOfSize:12];
                    [imageView addSubview:labelTip];
                    
                }
            }
        }
        if ([_adZynoArray count] > 0 && page < [_adZynoArray count]) {
            NSString* zyno = _adZynoArray[page];
            [[ZYAdStatistics shareStatistics] statistics:zyno andKey:@"iconClick"];
            [[ZYAdStatistics shareStatistics] statistics:zyno andKey:@"imgShow"];
        }
    }
    
    
    NSArray*listDefault = [[ZYGameServer shareServer] getDefaultArray];
    CGFloat width = CGRectGetWidth(self.scrollView.frame);
    CGFloat height = CGRectGetHeight(self.scrollView.frame);
    CGFloat x = self.scrollView.subviews.count * width;
    
    UIImage *imageMoreBG = [self imagesNamedFromCustomBundle:@"zyadmorebg"];
    int imageMoreWidth = imageMoreBG.size.width*adImageRate;
    int imageMoreHeight = imageMoreBG.size.height*adImageRate;
    UIImageView*buttonMoreBG = [[UIImageView alloc] initWithFrame:CGRectMake((_winWidth-imageMoreWidth)/2+x, (_winHeight-imageMoreHeight)/2, imageMoreWidth, imageMoreHeight)];
    buttonMoreBG.image = imageMoreBG;
    [self.scrollView addSubview:buttonMoreBG];
    buttonMoreBG.userInteractionEnabled=YES;
    
    UIImage* imageClose = [self imagesNamedFromCustomBundle:@"zyadclose"];
    int imageNoWidth = imageClose.size.width*adImageRate;
    int imageNoHeight = imageClose.size.height*adImageRate;
    UIButton *buttonClose = [UIButton buttonWithType:UIButtonTypeCustom];//button的类型
    [buttonClose setBackgroundImage:imageClose forState:UIControlStateNormal];
    buttonClose.frame = CGRectMake(imageMoreWidth-imageNoWidth+7, -7, imageNoWidth, imageNoHeight);//button的frame
    [buttonClose addTarget:self action:@selector(onClickClose) forControlEvents:UIControlEventTouchUpInside];
    [buttonMoreBG addSubview:buttonClose];
    
    //显示版本号
    UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(imageMoreWidth*0.69, imageMoreHeight*0.05, 40, 30)];
    versionLabel.text = ZYSDK_VERSION;
    versionLabel.font = [UIFont fontWithName:@"Arial" size:10];
    versionLabel.textAlignment = UITextAlignmentLeft;
    [buttonMoreBG addSubview:versionLabel];
    
    
    if (listDefault && listDefault.count> 0) {
        [_adDefaultList removeAllObjects];
        for (id value in listDefault) {
            ZYGameInfo* info = [[ZYGameServer shareServer] getGameInfoDic][value];
            NSString* imgPath = [self getFilePath:info.listImg];
            if ([fileManager fileExistsAtPath:imgPath]) {
                [_adDefaultList addObject:info];
            }
        }
        //额外增加一个列表
        if ([_adDefaultList count] > 0) {
            ZYGameInfo* info = [_adDefaultList objectAtIndex:0];
            NSString* imgPath = [self getFilePath:info.listImg];
            UIImage* imageList = [UIImage imageWithContentsOfFile:imgPath];//[self imagesNamedFromCustomBundle:@"t1"];
            int imageWidth = imageList.size.width*adImageRate;
            int imageHeigh = imageList.size.height*adImageRate;
            UITableView *_tableView = [[UITableView alloc] initWithFrame:CGRectMake((imageMoreWidth-imageWidth)/2, imageMoreWidth*0.18, imageWidth, (imageHeigh+cellDistance)*3.3) style:UITableViewStylePlain];
            _tableView.delegate = self;
            _tableView.dataSource = self;
            [_tableView setSeparatorColor:[UIColor clearColor]];
            _tableView.backgroundColor=[UIColor clearColor];
            _tableView.userInteractionEnabled=YES;
            [buttonMoreBG addSubview:_tableView];
            self.scrollView.contentSize = CGSizeMake(x + width, height);
        }
    }
    
    [self.view addSubview:self.scrollView];
    UITapGestureRecognizer *singleTap =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClickClose)];
    singleTap.delegate = self;
    [self.scrollView addGestureRecognizer:singleTap];
    self.scrollView.userInteractionEnabled=YES;
    self.scrollView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    
    if (_adZynoArray.count > 0){
        if (page > _adZynoArray.count) {
            currPageNum = 0;
        }else{
            currPageNum = page;
        }
        //切换到目标页
        [self.scrollView setContentOffset:CGPointMake(width*currPageNum, 0) animated:NO];
        
        //2个按钮
        UIImage* imageLeft = [self imagesNamedFromCustomBundle:@"zyadleft"];
        int imageLeftWidth = imageLeft.size.width*adImageRate;
        int imageLeftHeight = imageLeft.size.height*adImageRate;
        self.buttonLeft = [UIButton buttonWithType:UIButtonTypeCustom];//button的类型
        [self.buttonLeft setBackgroundImage:imageLeft forState:UIControlStateNormal];
        self.buttonLeft.frame = CGRectMake(6, _winHeight/2, imageLeftWidth, imageLeftHeight);//button的frame
        [self.buttonLeft addTarget:self action:@selector(onClickLeft) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.buttonLeft];
        
        UIImage* imageRight = [self imagesNamedFromCustomBundle:@"zyadright"];
        int imageRightWidth = imageRight.size.width*adImageRate;
        int imageRightHeight = imageRight.size.height*adImageRate;
        self.buttonRight = [UIButton buttonWithType:UIButtonTypeCustom];//button的类型
        [self.buttonRight setBackgroundImage:imageRight forState:UIControlStateNormal];
        self.buttonRight.frame = CGRectMake(_winWidth-imageRightWidth-6, _winHeight/2, imageRightWidth, imageRightHeight);//button的frame
        [self.buttonRight addTarget:self action:@selector(onClickRight) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.buttonRight];
        
        //
        if (currPageNum == _adZynoArray.count) {
            self.buttonRight.hidden = YES;
        }
        if (currPageNum == 0) {
            self.buttonLeft.hidden = YES;
        }
    }
}

//
- (void)giftShake:(UIView*)aView
{
    CAKeyframeAnimation *trans = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
    NSArray *values = @[@(0),@(10),@(20),@(10),@(-30),@(10),@(20),@(10),@(-30), @(0)];
    trans.values = values;
    NSArray *times = @[@(0.67),@(0.72),@(0.74),@(0.76),@(0.81),@(0.86),@(0.88),@(0.90),@(0.95), @(1)];
    trans.keyTimes = times;
    trans.duration = 3.5;
    trans.repeatCount = MAXFLOAT;
    trans.removedOnCompletion = NO;
    
    CAKeyframeAnimation *scaleXAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.x"];
    NSArray *scaleXValues = @[@(1),@(1),@(1.5),@(1),@(1),@(1),@(1.5),@(1),@(1),@(1)];
    scaleXAnimation.values = scaleXValues;
    NSArray *scaleXtimes = @[@(0.67),@(0.72),@(0.74),@(0.76),@(0.81),@(0.86),@(0.88),@(0.90),@(0.95), @(1)];
    scaleXAnimation.keyTimes = scaleXtimes;
    scaleXAnimation.duration = 3.5;
    scaleXAnimation.repeatCount = MAXFLOAT;
    scaleXAnimation.removedOnCompletion = NO;
    
    CAKeyframeAnimation *scaleYAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale.y"];
    NSArray *scaleYValues = @[@(1),@(1),@(0.6),@(1),@(1),@(1),@(0.6),@(1),@(1),@(1)];
    scaleYAnimation.values = scaleYValues;
    NSArray *scaleYtimes = @[@(0.67),@(0.72),@(0.74),@(0.76),@(0.81),@(0.86),@(0.88),@(0.90),@(0.95), @(1)];
    scaleYAnimation.keyTimes = scaleYtimes;
    scaleYAnimation.duration = 3.5;
    scaleYAnimation.repeatCount = MAXFLOAT;
    scaleYAnimation.removedOnCompletion = NO;
    
    [aView.layer addAnimation:trans forKey:@"trans"];
    [aView.layer addAnimation:scaleXAnimation forKey:@"scaleX"];
    [aView.layer addAnimation:scaleYAnimation forKey:@"scaleY"];
}

//移除大图界面
- (void)removeAdGameView
{
    for (UIView *view_ in self.scrollView.subviews) {
        [view_ removeFromSuperview];
    }
    [self.scrollView removeFromSuperview];
    [self.buttonLeft removeFromSuperview];
    [self.buttonRight removeFromSuperview];
}

//button相应的事件
- (void)onClickClose {
    [self removeAdGameView];
    switch (_openType) {
        case OPENTYPE_NONE:
            //error
            break;
        case OPENTYPE_CIRCLE:
            [self addCircleButton];
            break;
        case OPENTYPE_DIRECT:
            //nothing
            break;
        case OPENTYPE_TRIANGLE:
            
            break;
        default:
            break;
    }
    _openType = OPENTYPE_NONE;
}

//圆形按钮点击打开
- (void)onCircleClickOpen {
    if (_openType == OPENTYPE_NONE) {
        _openType = OPENTYPE_CIRCLE;
        [self removeCircleButton];
        [self addAdGameView:_circlePage];
    }
}

//三角按钮点击打开
- (void)onTriangleClickOpen {
    if (_openType == OPENTYPE_NONE) {
        _openType = OPENTYPE_CIRCLE;
        [self removeCircleButton];
        [self addAdGameView:_trianglePage];
    }
}

//点击大图
- (void)onClickImage{
    //jump to download
    if (_adZynoArray.count > currPageNum && _adZynoArray.count >0) {
        NSString *zyno = _adZynoArray[currPageNum];
        [[ZYAdStatistics shareStatistics] statistics:zyno andKey:@"imgClick"];
        [[ZYGameServer shareServer] jumpToDownload:zyno];
    }else{
        NSLog(@"Error:点击无法跳转链接！！！");
    }
}

//左方向按钮
- (void)onClickLeft
{
    if (currPageNum > 0) {
        currPageNum--;
        [self.scrollView setContentOffset:CGPointMake(_winWidth*currPageNum, 0) animated:YES];
        if (currPageNum < _adZynoArray.count) {
            NSString* zyno = _adZynoArray[currPageNum];
            [[ZYAdStatistics shareStatistics] statistics:zyno andKey:@"imgShow"];
        }
    }
}

//右方向按钮
- (void)onClickRight
{
    if (currPageNum < _adZynoArray.count) {
        currPageNum++;
        [self.scrollView setContentOffset:CGPointMake(_winWidth*currPageNum, 0) animated:YES];
        if (currPageNum < _adZynoArray.count) {
            NSString* zyno = _adZynoArray[currPageNum];
            [[ZYAdStatistics shareStatistics] statistics:zyno andKey:@"imgShow"];
        }
    }
}

//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
//{
//    // 若为UITableViewCellContentView（即点击了tableViewCell），则不截获Touch事件
//    if ([NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"]) {
//        return NO;
//    }
//    return  YES;
//}

#pragma mark scrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)sView
{
    if (sView == self.scrollView) {
        NSInteger index = fabs(sView.contentOffset.x) / sView.frame.size.width;
        currPageNum = index;
        //统计
        if (currPageNum < _adZynoArray.count) {
            NSString* zyno = _adZynoArray[currPageNum];
            [[ZYAdStatistics shareStatistics] statistics:zyno andKey:@"imgShow"];
        }
        
        if (currPageNum == _adZynoArray.count) {
            self.buttonRight.hidden = YES;
        }else{
            self.buttonRight.hidden = NO;
        }
        if (currPageNum == 0) {
            self.buttonLeft.hidden = YES;
        }else{
            self.buttonLeft.hidden = NO;
        }
    }
}


#pragma mark tableViewDelegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //分组数 也就是section数
    return 1;
}

//设置每个分组下tableview的行数
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _adDefaultList.count;
}
////每个分组上边预留的空白高度
//-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//    return 20;
//}
////每个分组下边预留的空白高度
//-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
//{
//    return 20;
//}
//每一个分组下对应的tableview 高度
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZYGameInfo* info = [_adDefaultList objectAtIndex:0];
    NSString* imgPath = [self getFilePath:info.listImg];
    UIImage* imageList = [UIImage imageWithContentsOfFile:imgPath];
    int imageHeigh = imageList.size.height*adImageRate;
    return imageHeigh+cellDistance;
}

//设置每行对应的cell（展示的内容）
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifer= [NSString stringWithFormat:@"cell%@",indexPath];
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:identifer];
    if (cell==nil) {
        cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifer];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
        
        ZYGameInfo* info = [_adDefaultList objectAtIndex:indexPath.row];
        NSString* imgPath = [self getFilePath:info.listImg];
        UIImage* imageList = [UIImage imageWithContentsOfFile:imgPath];
        int imageWidth = imageList.size.width*adImageRate;
        int imageHeigh = imageList.size.height*adImageRate;
        UIImageView *imageView=[[UIImageView alloc]initWithFrame:CGRectMake(0, cellDistance/2, imageWidth, imageHeigh)];
        imageView.image=imageList;
        [cell.contentView addSubview:imageView];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ZYGameInfo* info = [_adDefaultList objectAtIndex:indexPath.row];
    NSURL *downUrl= [NSURL URLWithString:info.url];
    [[UIApplication sharedApplication] openURL:downUrl];
    [tableView deselectRowAtIndexPath:indexPath animated:YES]; 
}


#pragma mark tools
- (NSString*)getFilePath:(NSString*)url
{
    NSArray* searchArray = [url componentsSeparatedByString:@"/"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *path = [NSString stringWithFormat:@"%@/zongyi/images",[paths lastObject]];
    NSString *imagePath = [path stringByAppendingPathComponent:searchArray.lastObject];
    return imagePath;
}


-(UIImage*) OriginImage:(UIImage *)image scaleToSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);  //size 为CGSize类型，即你所需要的图片尺寸
    
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return scaledImage;   //返回的就是已经改变的图片
}


- (UIImage *)imagesNamedFromCustomBundle:(NSString *)imgName
{
    NSString *bundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"ZYSdk.bundle"];
    
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    
    NSString *img_path = [bundle pathForResource:[NSString stringWithFormat:@"img/%@",imgName] ofType:@"png"];
    
    return [UIImage imageWithContentsOfFile:img_path];
    
}


//- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
//{
//    // 当touch point是在_btn上，则hitTest返回_btn
////    CGPoint btnPointInA = [_btn convertPoint:point fromView:self];
////    if ([_btn pointInside:btnPointInA withEvent:event]) {
////        return _btn;
////    }
//    
//    // 否则，返回默认处理
//    return [super hitTest:point withEvent:event];
//    
//}


@end
