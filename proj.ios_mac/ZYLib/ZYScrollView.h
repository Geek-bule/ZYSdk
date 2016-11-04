//
//  ZYScrollView.h
//  ZYScrollView
//
//  Created by Jonathan Tribouharet
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ZYScrollViewEffect) {
    ZYScrollViewEffectNone,
    ZYScrollViewEffectTranslation,
    ZYScrollViewEffectDepth,
    ZYScrollViewEffectCarousel,
    ZYScrollViewEffectCards
};

@interface ZYScrollView : UIScrollView

@property (nonatomic) ZYScrollViewEffect effect;

@property (nonatomic) CGFloat angleRatio;

@property (nonatomic) CGFloat rotationX;
@property (nonatomic) CGFloat rotationY;
@property (nonatomic) CGFloat rotationZ;

@property (nonatomic) CGFloat translateX;
@property (nonatomic) CGFloat translateY;

- (NSUInteger)currentPage;

- (void)loadNextPage:(BOOL)animated;
- (void)loadPreviousPage:(BOOL)animated;
- (void)loadPageIndex:(NSUInteger)index animated:(BOOL)animated;

@end
// 版权属于原作者
// http://code4app.com (cn) http://code4app.net (en)
// 发布代码于最专业的源码分享网站: Code4App.com// 版权属于原作者
// http://code4app.com (cn) http://code4app.net (en)
// 发布代码于最专业的源码分享网站: Code4App.com