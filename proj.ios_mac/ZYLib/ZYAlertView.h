//
//  ZYAlertView.h
//  sdkIOSDemo
//
//  Created by JustinYang on 16/9/23.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
typedef enum ButtonType
{
    Button_OK,
    Button_CANCEL,
    Button_OTHER
    
}ButtonType;

@class JKAlertDialogItem;
typedef void(^JKAlertDialogHandler)(JKAlertDialogItem *item);

@interface ZYAlertView : UIView
{
    UIView *_coverView;
    UIView *_alertView;
    UILabel *_labelTitle;
    UILabel *_labelmessage;
    
    UIScrollView *_buttonScrollView;
    UIScrollView *_contentScrollView;
    
    NSMutableArray *_items;
    NSString *_title;
    NSString *_message;
    
}
//按钮宽度,如果赋值,菜单按钮宽之和,超过alert宽,菜单会滚动
@property(assign,nonatomic)CGFloat buttonWidth;
//将要显示在alert上的自定义view
@property(strong,nonatomic)UIView *contentView;
@property (nonatomic, strong) UIButton *closeBtn;


- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message;
- (NSInteger)addButtonWithTitle:(NSString *)title;
- (void)addButton:(ButtonType)type withTitle:(NSString *)title handler:(JKAlertDialogHandler)handler;
- (void)show;
- (void)dismiss;
@end


@interface JKAlertDialogItem : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic) ButtonType type;
@property (nonatomic) NSUInteger tag;
@property (nonatomic, copy) JKAlertDialogHandler action;
@end
