//
//  NABAppDelegateProxy.m
//  sdkIOSDemo
//
//  Created by JustinYang on 16/8/30.
//
//

#import "ZYAppDelegateProxy.h"

@implementation ZYAppDelegateProxy

- (id)init
{
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *sig;
    sig = [self.originalAppDelegate methodSignatureForSelector:aSelector];
    if (sig) {
        return sig;
    } else {
        sig = [self.naAppDelegate methodSignatureForSelector:aSelector];
        return sig;
    }
    return nil;
}

// Invoke the invocation on whichever real object had a signature for it.
- (void)forwardInvocation:(NSInvocation *)invocation
{
    if ([self naDelegateRespondsToSelector:[invocation selector]]) {
        [invocation invokeWithTarget:self.naAppDelegate];
    }
    
    if ([self.originalAppDelegate methodSignatureForSelector:[invocation selector]]) {
        [invocation invokeWithTarget:self.originalAppDelegate];
    }
}

// Override some of NSProxy's implementations to forward them...
- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([self.naAppDelegate respondsToSelector:aSelector])
        return YES;
    if ([self.originalAppDelegate respondsToSelector:aSelector])
        return YES;
    
    return NO;
}

- (BOOL)naDelegateRespondsToSelector:(SEL)selector
{
    return [self.naAppDelegate respondsToSelector:selector] && ![[NSObject class] instancesRespondToSelector:selector];
}
@end
