//
//  AdVideoAdRegistry.h
//  sdkIOSDemo
//
//  Created by JustinYang on 16/8/26.
//
//

#import <Foundation/Foundation.h>
#import "ZYVideoType.h"

@interface ZYVideoAdRegistry : NSObject
{
    
}
@property (nonatomic, strong) NSMutableDictionary *adapterDict;

+ (ZYVideoAdRegistry *)sharedRegistry;
- (void)registerClass:(Class)adapterClass and:(ZYVideoType)type;
- (NSDictionary*)getClassesDict;

@end
