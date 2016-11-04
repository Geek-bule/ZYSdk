//
//  ZYAwardInfo.m
//  sdkIOSDemo
//
//  Created by JustinYang on 16/9/13.
//
//

#import "ZYAwardInfo.h"

@implementation ZYAwardInfo

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    
}

- (void)setValue:(id)value forKey:(NSString *)key {
    
    if ([value isKindOfClass:[NSNull class]]) {
        return;
    }
    
    [super setValue:value forKey:key];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    
    if ([dictionary isKindOfClass:[NSDictionary class]]) {
        
        self = [super init];
        
        if (self) {
            
            [self setValuesForKeysWithDictionary:dictionary];
        }
        
        return self;
        
    } else {
        
        return nil;
    }
}

@end
