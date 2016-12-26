//
//  ShareHelper.cpp
//  SpriteSheet
//
//  Created by JustinYang on 15/8/17.
//
//

#include "ShareHelper.h"
#include "ZYParamOnline.h"
#include "OpenUDID.h"
//ShareSDK必要头文件
#import <ShareSDK/ShareSDK.h>
#import <ShareSDKConnector/ShareSDKConnector.h>

#import <ShareSDKExtension/SSEShareHelper.h>
#import <ShareSDKUI/ShareSDK+SSUI.h>
#import <ShareSDKUI/SSUIShareActionSheetStyle.h>

//微信SDK头文件
#import "WXApi.h"

static UIView *_refView = nil;

ShareHelper *ShareHelper::shareHelper()
{
    static ShareHelper * share=NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        share= new ShareHelper;
    });
    return share;
}

void ShareHelper::init()
{
    /**
     *  设置ShareSDK的appKey，如果尚未在ShareSDK官网注册过App，请移步到http://mob.com/login 登录后台进行应用注册，
     *  在将生成的AppKey传入到此方法中。
     *  方法中的第二个参数用于指定要使用哪些社交平台，以数组形式传入。第三个参数为需要连接社交平台SDK时触发，
     *  在此事件中写入连接代码。第四个参数则为配置本地社交平台时触发，根据返回的平台类型来配置平台信息。
     *  如果您使用的时服务端托管平台信息时，第二、四项参数可以传入nil，第三项参数则根据服务端托管平台来决定要连接的社交SDK。
     */
    [ShareSDK registerApp:@SHARE_registerApp
          activePlatforms:@[@(SSDKPlatformSubTypeWechatSession),
                            @(SSDKPlatformSubTypeWechatTimeline),
                            @(SSDKPlatformTypeFacebook)
                            ]
                 onImport:^(SSDKPlatformType platformType) {
                     
                     switch (platformType)
                     {
                         case SSDKPlatformTypeWechat:
                             [ShareSDKConnector connectWeChat:[WXApi class]];
                             break;
                         default:
                             break;
                     }
                     
                 }
          onConfiguration:^(SSDKPlatformType platformType, NSMutableDictionary *appInfo) {
              
              switch (platformType)
              {
                  case SSDKPlatformTypeFacebook:
                      //设置Facebook应用信息，其中authType设置为只用SSO形式授权
                      [appInfo SSDKSetupFacebookByAppKey:@SHARE_FBappid
                                               appSecret:@SHARE_FBscrid
                                                authType:SSDKAuthTypeBoth];
                      break;
                  case SSDKPlatformTypeWechat:
                      [appInfo SSDKSetupWeChatByAppId:@SHARE_WXappid
                                            appSecret:@SHARE_WXscrid];
                      break;
                  default:
                      break;
              }
              
          }];
}

void ShareHelper::shareWithMsg(const char *title,const char *message,int award, cocos2d::Vec2 pt)
{
    
    //1、创建分享参数
    NSMutableDictionary *shareParams = [NSMutableDictionary dictionary];
    UIImage* imageArray = [UIImage imageNamed:@"shareImage/shareImage.png"];
    
    if (imageArray) {
        
        [shareParams SSDKSetupShareParamsByText:[NSString stringWithUTF8String:message]
                                         images:imageArray
                                            url:[NSURL URLWithString:@"http://a.app.qq.com/o/simple.jsp?pkgname=com.zongyi.cookie"]
                                          title:[NSString stringWithUTF8String:title]
                                           type:SSDKContentTypeImage];
        
        [shareParams SSDKSetupWeChatParamsByText:[NSString stringWithUTF8String:message]
                                           title:[NSString stringWithUTF8String:title]
                                             url:[NSURL URLWithString:@"http://a.app.qq.com/o/simple.jsp?pkgname=com.zongyi.cookie"]
                                      thumbImage:[UIImage imageNamed:@"shareImage/smallImage.png"]
                                           image:imageArray
                                    musicFileURL:nil
                                         extInfo:nil
                                        fileData:nil
                                    emoticonData:nil
                                            type:SSDKContentTypeImage
                              forPlatformSubType:SSDKPlatformSubTypeWechatTimeline];
        
        [shareParams SSDKSetupWeChatParamsByText:[NSString stringWithUTF8String:message]
                                           title:[NSString stringWithUTF8String:title]
                                             url:[NSURL URLWithString:@"http://a.app.qq.com/o/simple.jsp?pkgname=com.zongyi.cookie"]
                                      thumbImage:nil
                                           image:[UIImage imageNamed:@"shareImage/smallImage.png"]
                                    musicFileURL:nil
                                         extInfo:nil
                                        fileData:nil
                                    emoticonData:nil
                                            type:SSDKContentTypeWebPage
                              forPlatformSubType:SSDKPlatformSubTypeWechatSession];
        
        if (!_refView)
        {
            _refView = [[UIView alloc] initWithFrame:CGRectMake(pt.x, pt.y, 1, 1)];
        }
        _refView.frame = CGRectMake(pt.x, pt.y, 1, 1);
        [[UIApplication sharedApplication].keyWindow.rootViewController.view addSubview:_refView];
        
        //2、分享
        [ShareSDK showShareActionSheet:_refView
                                 items:@[@(SSDKPlatformSubTypeWechatSession),
                                         @(SSDKPlatformSubTypeWechatTimeline),
                                         @(SSDKPlatformTypeFacebook)
                                         ]
                           shareParams:shareParams
                   onShareStateChanged:^(SSDKResponseState state, SSDKPlatformType platformType, NSDictionary *userData, SSDKContentEntity *contentEntity, NSError *error, BOOL end) {
                       
                       switch (state) {
                               
                           case SSDKResponseStateBegin:
                           {
                               
                               break;
                           }
                           case SSDKResponseStateSuccess:
                           {
                               callback(award);
                               break;
                           }
                           case SSDKResponseStateFail:
                           {
                               if (platformType == SSDKPlatformTypeSMS && [error code] == 201)
                               {
                                   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"分享失败"
                                                                                   message:@"失败原因可能是：1、短信应用没有设置帐号；2、设备不支持短信应用；3、短信应用在iOS 7以上才能发送带附件的短信。"
                                                                                  delegate:nil
                                                                         cancelButtonTitle:@"OK"
                                                                         otherButtonTitles:nil, nil];
                                   [alert show];
                                   break;
                               }
                               else if(platformType == SSDKPlatformTypeMail && [error code] == 201)
                               {
                                   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"分享失败"
                                                                                   message:@"失败原因可能是：1、邮件应用没有设置帐号；2、设备不支持邮件应用；"
                                                                                  delegate:nil
                                                                         cancelButtonTitle:@"OK"
                                                                         otherButtonTitles:nil, nil];
                                   [alert show];
                                   break;
                               }
                               else
                               {
                                   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"分享失败"
                                                                                   message:[NSString stringWithFormat:@"%@",error]
                                                                                  delegate:nil
                                                                         cancelButtonTitle:@"OK"
                                                                         otherButtonTitles:nil, nil];
                                   [alert show];
                                   break;
                               }
                               break;
                           }
                           case SSDKResponseStateCancel:
                           {
                               NSLog(@"分享已取消");
                               break;
                           }
                           default:
                               break;
                       }
                       
                       if (state != SSDKResponseStateBegin)
                       {
                           
                       }
                       
                       if (_refView)
                       {
                           //移除视图
                           [_refView removeFromSuperview];
                       }
                       
                   }];
        
    }else{
        cocos2d::MessageBox("资源图片没添加到工程中", "提示");
    }
}

void ShareHelper::shareToWechat(const char *msg, int award)
{
    
    //创建分享参数
    NSMutableDictionary *shareParams = [NSMutableDictionary dictionary];
    
    UIImage* imageArray = [UIImage imageNamed:@"shareImage/shareImage.png"];
    
    if (imageArray) {
        
        [shareParams SSDKSetupShareParamsByText:nil
                                         images:imageArray
                                            url:[NSURL URLWithString:@"http://a.app.qq.com/o/simple.jsp?pkgname=com.zongyi.cookie"]
                                          title:[NSString stringWithUTF8String:msg]
                                           type:SSDKContentTypeAuto];
        
        [shareParams SSDKSetupWeChatParamsByText:[NSString stringWithUTF8String:msg]
                                           title:[NSString stringWithUTF8String:msg]
                                             url:[NSURL URLWithString:@"http://a.app.qq.com/o/simple.jsp?pkgname=com.zongyi.cookie"]
                                      thumbImage:[UIImage imageNamed:@"shareImage/smallImage.png"]
                                           image:imageArray
                                    musicFileURL:nil
                                         extInfo:nil
                                        fileData:nil
                                    emoticonData:nil
                                            type:SSDKContentTypeImage
                              forPlatformSubType:SSDKPlatformSubTypeWechatTimeline];
        
        //进行分享
        [ShareSDK share:SSDKPlatformSubTypeWechatTimeline
             parameters:shareParams
         onStateChanged:^(SSDKResponseState state, NSDictionary *userData, SSDKContentEntity *contentEntity, NSError *error) {
             
             switch (state) {
                 case SSDKResponseStateSuccess:
                 {
                     callback(award);
                     break;
                 }
                 case SSDKResponseStateFail:
                 {
                     UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"分享失败"
                                                                         message:[NSString stringWithFormat:@"%@", error]
                                                                        delegate:nil
                                                               cancelButtonTitle:@"确定"
                                                               otherButtonTitles:nil];
                     [alertView show];
                     break;
                 }
                 case SSDKResponseStateCancel:
                 {
                     
                     break;
                 }
                 default:
                     break;
             }
             
         }];
    }else{
        cocos2d::MessageBox("资源图片没添加到工程中", "提示");
    }
}

void ShareHelper::initFunction(const ccShareCallBack call)
{
    callback = call;
}


void ShareHelper::shareDeviceInfo()
{
    //创建分享参数
    NSMutableDictionary *shareParams = [NSMutableDictionary dictionary];
    //设备信息
    NSString *deviceInfo = [NSString stringWithFormat:@"IDFA:%@\nIDFV:%@\nOPENID:%@\n",[ZYParamOnline idfaString],[ZYParamOnline idfvString],[OpenUDID value]];
    [shareParams SSDKSetupShareParamsByText:deviceInfo
                                     images:nil
                                        url:nil
                                      title:nil
                                       type:SSDKContentTypeText];
    
    //进行分享
    [ShareSDK share:SSDKPlatformSubTypeWechatSession
         parameters:shareParams
     onStateChanged:^(SSDKResponseState state, NSDictionary *userData, SSDKContentEntity *contentEntity, NSError *error) {
         
         switch (state) {
             case SSDKResponseStateSuccess:
             {
                 break;
             }
             case SSDKResponseStateFail:
             {
                 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"分享失败"
                                                                     message:[NSString stringWithFormat:@"%@", error]
                                                                    delegate:nil
                                                           cancelButtonTitle:@"确定"
                                                           otherButtonTitles:nil];
                 [alertView show];
                 break;
             }
             case SSDKResponseStateCancel:
             {
                 
                 break;
             }
             default:
                 break;
         }
         
     }];
}



