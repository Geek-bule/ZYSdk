//
//  IOSInfo.cpp
//  sdkIOSDemo
//
//  Created by JustinYang on 16/7/8.
//
//

#include "IOSInfo.h"
#import <Foundation/Foundation.h>
#import <AdSupport/AdSupport.h>
#import <UIKit/UIKit.h>

#define IOSAPDATE

std::string IOSInfo::getLanguage()
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
    //语言版本判断
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
    NSString *currentLanguage = [languages objectAtIndex:0];
    
    // get the current language code.(such as English is "en", Chinese is "zh" and so on)
    NSDictionary* temp = [NSLocale componentsFromLocaleIdentifier:currentLanguage];
    NSString * languageCode = [temp objectForKey:NSLocaleLanguageCode];
    
    return [languageCode UTF8String];
#endif
}

std::string IOSInfo::getIdFa()
{
#ifdef IOSAPDATE
    NSString *adId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    return [adId UTF8String];
#endif
    
}

std::string IOSInfo::getIdFv()
{
#ifdef IOSAPDATE
    NSString *idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    return [idfv UTF8String];
#endif
}

std::string IOSInfo::getVersion()
{
#ifdef IOSAPDATE
    NSString *curVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    return [curVersion UTF8String];
#endif
}

std::string IOSInfo::getBuild()
{
#ifdef IOSAPDATE
    NSString *curVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    return [curVersion UTF8String];
#endif
}

std::string IOSInfo::getUnicode(const char* strChinese)
{
    NSString *str1 = [NSString stringWithUTF8String:strChinese];
    NSString *str2 = [str1 stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return str2.UTF8String;
}

bool IOSInfo::canOpenUlr(std::string url)
{
#ifdef IOSAPDATE
    NSString *urlSchemes = [NSString stringWithUTF8String:url.c_str()];
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:urlSchemes]])
    {
        NSLog(@"%@ installed",urlSchemes);
        return true;
    }
    return false;
#endif
}


void IOSInfo::openUrl(std::string url)
{
#ifdef IOSAPDATE
    NSURL *urlOS= [NSURL URLWithString:[NSString stringWithUTF8String:url.c_str()]];
    [[UIApplication sharedApplication] openURL:urlOS];
#endif
}
