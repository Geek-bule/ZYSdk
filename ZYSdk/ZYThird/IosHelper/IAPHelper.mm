//
//  IAPHelper.m
//  InAppRage
//
//  Created by Ray Wenderlich on 2/28/11.
//  Copyright 2011 Ray Wenderlich. All rights reserved.
//

#import "IAPHelper.h"
#import "AppController.h"
#import "MBProgressHUD.h"
#import "platform/ios/CCEAGLView-ios.h"
#import "StoreKit/StoreKit.h"
#import <Foundation/Foundation.h>


@interface IAPHelper : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver> {
    NSSet * _productIdentifiers;
    NSArray * _products;
    NSDictionary * _productsDoc;
    NSMutableSet * _purchasedProducts;
    SKProductsRequest * _request;
    MBProgressHUD* _hud;
}

@property (retain) NSSet *productIdentifiers;
@property (retain) NSArray * products;
@property (retain) NSDictionary * productsDoc;
@property (retain) NSMutableSet *purchasedProducts;
@property (retain) SKProductsRequest *request;
@property (retain) MBProgressHUD *hud;

+ (IAPHelper *) sharedHelper;
- (void)requestProducts:(BOOL)isLoad;
- (id)init;
- (void)buyProductId:(int) productId;             //购买物品调用次函数
- (void)buyProductIdent:(NSString*)productId;
- (void)restoreProductIdentifier;         //恢复之前的购买调用次函数
- (UIViewController*) getViewController;
- (void)createHUD:(NSString*)showmsg time:(float)delay tip:(NSString*)outMsg;
- (void)dismissHUD:(id)arg;

@end

@implementation IAPHelper
@synthesize productIdentifiers = _productIdentifiers;
@synthesize products = _products;
@synthesize productsDoc = _productsDoc;
@synthesize purchasedProducts = _purchasedProducts;
@synthesize request = _request;
@synthesize hud = _hud;

+ (IAPHelper *) sharedHelper {
    
    static IAPHelper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
    
}

- (id)init {
    if ((self = [super init])) {
        [_productIdentifiers retain];
    }
    return self;
}

- (void)loadProduct:(NSArray*)productIds
{
    _productIdentifiers = [NSSet setWithArray:productIds];
}

// Retrieve product information from the App Store
-(void)fetchProductInformation
{
    // Query the App Store for product information if the user is is allowed to make purchases.
    // Display an alert, otherwise.
    if([SKPaymentQueue canMakePayments])
    {
        // Load the product identifiers fron ProductIds.plist
        NSURL *plistURL = [[NSBundle mainBundle] URLForResource:@"ProductIds" withExtension:@"plist"];
        NSArray *productIds = [NSArray arrayWithContentsOfURL:plistURL];
        _productIdentifiers = [NSSet setWithArray:productIds];
    }
    else
    {
        // Warn the user that they are not allowed to make purchases.
        NSLog(@"Warning::Purchases are disabled on this device.");
    }
}

- (void)createHUD:(NSString*)showmsg time:(float)delay tip:(NSString*)outMsg {
    
    if (self.hud == nil) {
        self.hud = [MBProgressHUD showHUDAddedTo:[self getViewController].view animated:YES];
        _hud.labelText = showmsg;
        [self performSelector:@selector(timeout:) withObject:outMsg afterDelay:delay];
    }
}

- (void)dismissHUD:(id)arg{
    
    [[self class] cancelPreviousPerformRequestsWithTarget:self];
    [MBProgressHUD hideHUDForView:[self getViewController].view animated:YES];
    self.hud = nil;
}

- (void)timeout:(NSString*)outTip {
    
    _hud.labelText = outTip;
    _hud.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]] autorelease];
    _hud.mode = MBProgressHUDModeCustomView;
    [self performSelector:@selector(dismissHUD:) withObject:nil afterDelay:3.0];
    
}


- (void)requestProducts:(BOOL)isLoad {
    if(isLoad){
        [self createHUD:@"" time:40 tip:@""];
    }
    self.request = [[[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifiers] autorelease];
    _request.delegate = self;
    [_request start];
    
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"Failed to load list of products.%@",error);
    InIAPHelper::shareIAP()->dismissHUD();
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:nil
                                                 message:@"抱歉，商品加载失败了，请您检查网络后再次尝试"
                                                delegate:nil       //委托给Self，才会执行上面的调用
                                       cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                       otherButtonTitles:nil,nil];
    [av show];
    [av release];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    InIAPHelper::shareIAP()->dismissHUD();
    NSLog(@"Received products results...");   
    self.products = response.products;
    self.request = nil;    
    if (_products.count <= 0) {
        NSLog(@"商品加载失败，请检查网络");
        return;
    }
    std::vector<tagIAPINFO> vecIapInfo;
    NSMutableDictionary *doc = [NSMutableDictionary dictionary];
    for (int i=0 ; i < _products.count; i++) {
        SKProduct *skProduct = _products[i];
        tagIAPINFO info;
        info.iapId = i;
        info.iapIdent = [skProduct.productIdentifier UTF8String];
        info.iapPrice = [skProduct.price doubleValue];
        vecIapInfo.push_back(info);
        
        [doc setObject:skProduct forKey:skProduct.productIdentifier];
    }
    self.productsDoc = doc;
    InIAPHelper::shareIAP()->_loadCallBack(vecIapInfo);
}

- (void)recordTransaction:(SKPaymentTransaction *)transaction {
    // TODO: Record the transaction on the server side...    
}

- (void)provideContent:(NSString *)productIdentifier {
    
    NSLog(@"Toggling flag for: %@", productIdentifier);
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [_purchasedProducts addObject:productIdentifier];
    
    
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    
    NSLog(@"completeTransaction...");
    [self dismissHUD:nil];
    
    [self recordTransaction: transaction];
    [self provideContent: transaction.payment.productIdentifier];
    
    //购买成功获得金币
    std::string ident = [transaction.payment.productIdentifier UTF8String];
    InIAPHelper::shareIAP()->_orderCallBack(ident);
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    
    NSLog(@"restoreTransaction...");
    [self dismissHUD:nil];
    
    [self recordTransaction: transaction];
    [self provideContent: transaction.originalTransaction.payment.productIdentifier];
    
    //购买成功获得金币
    std::string ident = [transaction.payment.productIdentifier UTF8String];
    InIAPHelper::shareIAP()->_restoreCallBack(ident);
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    
    [self dismissHUD:nil];
    
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        NSLog(@"Transaction error: %@", transaction.error.localizedDescription);
    }else{
        NSLog(@"Transaction error cancell");
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchasing:
                
                break;
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    }
}

- (void)buyProductId:(int) productId {
    [self createHUD:@"" time:40 tip:@""];
    SKProduct *skProduct = _products[productId];
    NSLog(@"Buying %@...", skProduct);
    
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:skProduct];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
}

- (void)buyProductIdent:(NSString *)productId {
    if ([_productsDoc count] > 0) {
        [self createHUD:@"" time:40 tip:@""];
        SKProduct *skProduct = [_productsDoc objectForKey:productId];
        NSLog(@"Buying %@...", skProduct);
    
        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:skProduct];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }else{
        NSLog(@"Buying %@...", productId);
//        NSLog(@"无法购买商品，请检查网络正常后，重新加载商店商品");
        SKPayment *payment = [SKPayment paymentWithProductIdentifier:productId];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

- (void)restoreProductIdentifier{
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)dealloc
{
    [_productIdentifiers release];
    _productIdentifiers = nil;
    [_products release];
    _products = nil;
    [_purchasedProducts release];
    _purchasedProducts = nil;
    [_request release];
    _request = nil;
    [super dealloc];
}

- (UIViewController*) getViewController
{
    UIViewController *result = nil;
    
    UIWindow *topWindow = [[UIApplication sharedApplication] keyWindow];
    
    if (topWindow.windowLevel != UIWindowLevelNormal){
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(topWindow in windows){
            if (topWindow.windowLevel == UIWindowLevelNormal){
                break;
            }
        }
    }
    UIView *rootView = [[topWindow subviews] objectAtIndex:0];
    id nextResponder = [rootView nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]]){
        
        result = nextResponder;
        
    }else if ([topWindow respondsToSelector:@selector(rootViewController)] && topWindow.rootViewController != nil){
        
        result = topWindow.rootViewController;
        
    }
    return result;
}

@end


//////////////////////////////////////////////////////////
//              苹果的内置付费部分
//       1.库支持：StoreKit.framework
//       2.掉用之前初始化iap_id
//          NSSet *ProductID = [NSSet setWithObjects:/*IAP_ID1,IAP_ID2,*/nil];
//          [[SKPaymentQueue defaultQueue] addTransactionObserver:[[InAppRageIAPHelper alloc] init:ProductID]];
//////////////////////////////////////////////////////////


InIAPHelper *InIAPHelper::shareIAP()
{
    static InIAPHelper * helper=NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        helper= new InIAPHelper;
    });
    return helper;
}

void InIAPHelper::createHUD(std::string msg, float delay, std::string outMsg)
{
    NSString *outMessage = [NSString stringWithUTF8String:outMsg.c_str()];
    NSString *message = [NSString stringWithUTF8String:msg.c_str()];
    [[IAPHelper sharedHelper] createHUD:message time:delay tip:outMessage];

}

void InIAPHelper::dismissHUD()
{
    [[IAPHelper sharedHelper] dismissHUD:nil];
}

void InIAPHelper::initIAPId()
{
    [[SKPaymentQueue defaultQueue] addTransactionObserver:[IAPHelper sharedHelper]];
}

void InIAPHelper::loadIAPProducts(std::vector<std::string> productids,bool isLoad)
{
    NSMutableArray *products = [NSMutableArray array];
    for (int index =0; index < productids.size(); index++) {
        std::string identifier = productids[index];
        NSString *nsIdentifier = [NSString stringWithUTF8String:identifier.c_str()];
        [products addObject:nsIdentifier];
    }
    [[IAPHelper sharedHelper] loadProduct:products];
    [[IAPHelper sharedHelper] requestProducts:isLoad];
}

void InIAPHelper::orderProduct(int productid)
{
    [[IAPHelper sharedHelper] buyProductId:productid];
}

void InIAPHelper::orderIdentifier(std::string identifer)
{
    NSString *IdentifierNs = [NSString stringWithUTF8String:identifer.c_str()];
    [[IAPHelper sharedHelper] buyProductIdent:IdentifierNs];
}

void InIAPHelper::restoreProducts()
{
    [[IAPHelper sharedHelper] restoreProductIdentifier];
}

void InIAPHelper::setLoadSuccess(const ccIAPLoadBack &call)
{
    _loadCallBack = call;
}

void InIAPHelper::setOrderSuccess(const ccIAPCallBack &call)
{
    _orderCallBack = call;
}

void InIAPHelper::setRestoreSuccess(const ccIAPCallBack &call)
{
    _restoreCallBack = call;
}



