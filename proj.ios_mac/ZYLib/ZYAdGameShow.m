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




@interface ZYAdGameShow()<UIScrollViewDelegate,UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate>
{
    int currPageNum;
    float adImageRate;
    BOOL _isHidden;
    int _currPage;
}
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIView *view;
@property (strong, nonatomic) UIView *buttonView;
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
        _isHidden = YES;
        _currPage = 0;
        
        _adZynoArray = [[NSMutableArray alloc] init];
        _adDefaultList = [[NSMutableArray alloc] init];
        currPageNum = 0;
        
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
        
        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, _winWidth, _winHeight)];
        self.scrollView.pagingEnabled = YES;
        self.scrollView.clipsToBounds = NO;
        self.scrollView.delegate = self;
        self.scrollView.contentSize = CGSizeMake(_winWidth, _winHeight);
        
        //设置回调
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadAdPage)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didChangedStatusBarOrientation:)
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification
                                                   object:nil];
    }
    return self;
}

- (void)showAdGame:(UIView*)mainView
{
    self.view = mainView;
}


- (void)reloadAdPage
{
    [self setAdHide:_isHidden Page:_currPage];
}


- (void)didChangedStatusBarOrientation:(NSNotification*)n {
    
}


- (void)setAdHide:(BOOL)isHide Page:(int)page
{
    NSString* adGame = [[ZYParamOnline shareParam] getParamOf:@"ZYAdgame"];
    if (adGame.intValue != 1) {
        return;
    }
    _isHidden = isHide;
    _currPage = page;
    if (_isHidden) {
        [self removeAdButton];
        [self removeAdGameView];
    }else{
        [self removeAdButton];
        [self removeAdGameView];
        switch (_currPage) {
            case 0:
                [self addAdButton];
                break;
            case 1:
                [self addAdGameView];
                break;
            default:
                break;
        }
    }
}

- (void)setAdPot:(CGPoint)pot Scale:(CGFloat)scale
{
    _btnViewPos = pot;
    _btnScale = scale;
}


- (void)addAdButton
{
    [self.buttonView removeFromSuperview];
    NSArray* list = [[ZYGameServer shareServer] getGameZynoArray];
    if (!list || [list count] == 0) {
        NSArray* listDefault = [[ZYGameServer shareServer] getDefaultArray];
        if (listDefault && listDefault.count> 0) {
            UIImage*image = [self imagesNamedFromCustomBundle:@"zyadmore"];
            CGFloat imageWidth = image.size.width*adImageRate;
            CGFloat imageHeight = image.size.height*adImageRate;
            self.buttonView = [[UIView alloc] initWithFrame:CGRectMake(_winWidth*_btnViewPos.x-imageWidth/2, _winHeight*_btnViewPos.y-imageHeight/2, imageWidth, imageHeight)];
            [self.view addSubview:self.buttonView];
            
            UITapGestureRecognizer *singleTap =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClickOpen)];
            [self.buttonView addGestureRecognizer:singleTap];
            self.buttonView.userInteractionEnabled=YES;
            
            UIImageView*buttonImage = [[UIImageView alloc] initWithImage:image];
            buttonImage.frame = CGRectMake(0, 0, image.size.width*adImageRate, image.size.height*adImageRate);
            buttonImage.layer.transform = CATransform3DMakeScale(_btnScale, _btnScale, 1.0);
            [self.buttonView addSubview:buttonImage];
            
            [self shakeToShow:self.buttonView];
        }
        return;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
//    for (id value in list) {
    NSDictionary *adDic = [[ZYGameServer shareServer] getGameInfoDic];
    int nCount = rand()%list.count;
    ZYGameInfo* info = adDic[list[nCount]];
    NSString* buttonPath = [self getFilePath:info.button];
    NSString* buttonFlashPath = [self getFilePath:info.buttonFlash];
    NSString* imgPath = [self getFilePath:info.img];
    if ([fileManager fileExistsAtPath:buttonPath]
        &&
        [fileManager fileExistsAtPath:buttonFlashPath]
        &&
        [fileManager fileExistsAtPath:imgPath] ) {
        
        currPageNum = nCount;
        
        UIImage*image = [UIImage imageWithContentsOfFile:buttonPath];
        CGFloat imageWidth = image.size.width*adImageRate;
        CGFloat imageHeight = image.size.height*adImageRate;
        self.buttonView = [[UIView alloc] initWithFrame:CGRectMake(_winWidth*_btnViewPos.x-imageWidth/2, _winHeight*_btnViewPos.y-imageHeight/2, imageWidth, imageHeight)];
        [self.view addSubview:self.buttonView];
        
        
        UITapGestureRecognizer *singleTap =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClickOpen)];
        [self.buttonView addGestureRecognizer:singleTap];
        self.buttonView.userInteractionEnabled=YES;
        
        
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
        
        UIImageView*buttonImage = [[UIImageView alloc] initWithImage:image];
        buttonImage.frame = CGRectMake(0, 0, image.size.width*adImageRate, image.size.height*adImageRate);
        buttonImage.layer.transform = CATransform3DMakeScale(_btnScale, _btnScale, 1.0);
        [self.buttonView addSubview:buttonImage];
        
        [self shakeToShow:self.buttonView];
        
        [[ZYAdStatistics shareStatistics] statistics:info.zyno andKey:@"iconShow"];
        
        return;
    }
//    }
    NSLog(@"进入循环模式");
    //如果一直没有就间隔时间再进行
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(addAdButton) userInfo:nil repeats:NO];
}

- (void) shakeToShow:(UIView*)aView{
    CAKeyframeAnimation* animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animation.duration = 0.8;
    animation.repeatCount = MAXFLOAT;
    
    NSMutableArray *values = [NSMutableArray array];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.9, 0.9, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)]];
    animation.values = values;
    [aView.layer addAnimation:animation forKey:nil];
}



- (void)removeAdButton
{
    //remove button
    [self.buttonView removeFromSuperview];
}

- (void)addAdGameView
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [_adZynoArray removeAllObjects];
    int count = 0;
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
                if (info.reward.intValue > 0 && info.rewardId != 0 ) {
                    UIImage* imageGift = [self imagesNamedFromCustomBundle:@"zyadgift"];
                    int imageGiftWidth = imageGift.size.width*adImageRate;
                    int imageGiftHeight = imageGift.size.height*adImageRate;
                    UIImageView* imageGiftView = [[UIImageView alloc] initWithImage:imageGift];
                    imageGiftView.frame = CGRectMake(adImageWidth-imageGiftWidth/2-20, -imageGiftHeight/2+20, imageGiftWidth, imageGiftHeight);
                    [imageView addSubview:imageGiftView];
                }
            }
        }
        NSString* zyno = _adZynoArray[0];
        [[ZYAdStatistics shareStatistics] statistics:zyno andKey:@"iconClick"];
        [[ZYAdStatistics shareStatistics] statistics:zyno andKey:@"imgShow"];
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
        ZYGameInfo* info = [_adDefaultList objectAtIndex:0];
        NSString* imgPath = [self getFilePath:info.listImg];
        UIImage* imageList = [UIImage imageWithContentsOfFile:imgPath];//[self imagesNamedFromCustomBundle:@"t1"];
        int imageWidth = imageList.size.width*adImageRate;
        int imageHeigh = imageList.size.height*adImageRate;
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake((imageMoreWidth-imageWidth)/2, imageMoreWidth*0.18, imageWidth, (imageHeigh+cellDistance)*3.3) style:UITableViewStylePlain];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        [self.tableView setSeparatorColor:[UIColor clearColor]];
        self.tableView.backgroundColor=[UIColor clearColor];
        self.tableView.userInteractionEnabled=YES;
        [buttonMoreBG addSubview:self.tableView];
        self.scrollView.contentSize = CGSizeMake(x + width, height);
    }
    
    [self.view addSubview:self.scrollView];
    self.scrollView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    
    UITapGestureRecognizer *singleTap =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClickClose)];
    singleTap.delegate = self;
    [self.scrollView addGestureRecognizer:singleTap];
    self.scrollView.userInteractionEnabled=YES;
    
    
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
    
    [self.scrollView setContentOffset:CGPointMake(width*currPageNum, 0) animated:NO];
}

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
    [self addAdButton];
}

- (void)onClickOpen {
    [self removeAdButton];
    [self addAdGameView];
}

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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    // 若为UITableViewCellContentView（即点击了tableViewCell），则不截获Touch事件
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"]) {
        return NO;
    }
    return  YES;
}

#pragma mark scrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)sView
{
    NSInteger index = fabs(sView.contentOffset.x) / sView.frame.size.width;
    currPageNum = index;
    //统计
    if (currPageNum < _adZynoArray.count) {
        NSString* zyno = _adZynoArray[currPageNum];
        [[ZYAdStatistics shareStatistics] statistics:zyno andKey:@"imgShow"];
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
    static NSString *identifer=@"cell";
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:identifer];
    if (cell==nil) {
        cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifer];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
    }
    ZYGameInfo* info = [_adDefaultList objectAtIndex:indexPath.row];
    NSString* imgPath = [self getFilePath:info.listImg];
    UIImage* imageList = [UIImage imageWithContentsOfFile:imgPath];
    int imageWidth = imageList.size.width*adImageRate;
    int imageHeigh = imageList.size.height*adImageRate;
    UIImageView *imageView=[[UIImageView alloc]initWithFrame:CGRectMake(0, cellDistance/2, imageWidth, imageHeigh)];
    imageView.image=imageList;
    [cell.contentView addSubview:imageView];
    
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
    
    NSString *img_path = [bundle pathForResource:imgName ofType:@"png"];
    
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
