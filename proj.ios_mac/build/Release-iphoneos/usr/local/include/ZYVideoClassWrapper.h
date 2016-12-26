//
//  AdVideoClassWrapper.h
//  sdkIOSDemo
//
//  Created by JustinYang on 16/9/20.
//
//

#import <Foundation/Foundation.h>

@interface ZYVideoClassWrapper : NSObject{
    Class theClass;
    BOOL theEnable;
}

- (id)initWithClass:(Class)c;

@property (nonatomic, readonly) Class theClass;
@property (nonatomic, assign) BOOL	theEnable;
@property (nonatomic, assign) BOOL	theHide;

@end
