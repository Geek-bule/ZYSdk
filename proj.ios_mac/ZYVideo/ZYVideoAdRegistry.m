//
//  AdVideoAdRegistry.m
//  sdkIOSDemo
//
//  Created by JustinYang on 16/8/26.
//
//

#import "ZYVideoAdRegistry.h"
#import "ZYVideoClassWrapper.h"

@implementation ZYVideoAdRegistry

+ (ZYVideoAdRegistry *)sharedRegistry {
    static ZYVideoAdRegistry *registry = nil;
    if (registry == nil) {
        registry = [[ZYVideoAdRegistry alloc] init];
    }
    return registry;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.adapterDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)registerClass:(Class)adapterClass and:(ZYVideoType)type {
    // have to do all these to avoid compiler warnings...
    NSString *key = [NSString stringWithFormat:@"%d",type];
    ZYVideoClassWrapper *wapper = [[ZYVideoClassWrapper alloc] initWithClass:adapterClass];
    [self.adapterDict setObject:wapper forKey:key];
}

- (void)unregisterClassFor:(NSInteger)adNetworkType
{
    [self.adapterDict removeObjectForKey:[NSNumber numberWithInteger:adNetworkType]];
}

- (NSDictionary*)getClassesDict
{
    return self.adapterDict;
}



@end
