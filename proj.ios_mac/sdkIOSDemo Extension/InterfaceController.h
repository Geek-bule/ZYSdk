//
//  InterfaceController.h
//  Cookie Extension
//
//  Created by JustinYang on 16/1/5.
//
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface InterfaceController : WKInterfaceController<WCSessionDelegate>

@property(weak, nonatomic) IBOutlet WKInterfaceLabel *LabelStage;
@property(weak, nonatomic) IBOutlet WKInterfaceLabel *LabelStar;
@property(weak, nonatomic) IBOutlet WKInterfaceLabel *LabelHeart;

@end
