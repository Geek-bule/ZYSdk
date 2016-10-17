//
//  IAPHelper.h
//  InAppRage
//
//  Created by Ray Wenderlich on 2/28/11.
//  Copyright 2011 Ray Wenderlich. All rights reserved.
//

#ifndef __OLStarYo__IAPHelper__
#define __OLStarYo__IAPHelper__


#include "cocos2d.h"

struct tagIAPINFO
{
    int iapId;
    std::string iapIdent;
    double iapPrice;
};


typedef std::function<void(std::string)> ccIAPCallBack;
typedef std::function<void(std::vector<tagIAPINFO>)> ccIAPLoadBack;

class InIAPHelper
{
public:
    static InIAPHelper *shareIAP();
    void createHUD(std::string msg, float delay, std::string outMsg);
    void dismissHUD();
    void initIAPId();
    void loadIAPProducts(std::vector<std::string> productids,bool isLoad);
    void setLoadSuccess(const ccIAPLoadBack &call);
    void setOrderSuccess(const ccIAPCallBack &call);
    void setRestoreSuccess(const ccIAPCallBack &call);
    void orderProduct(int productid);
    void orderIdentifier(std::string identifer);
    void restoreProducts();
    ccIAPCallBack _orderCallBack;
    ccIAPCallBack _restoreCallBack;
    ccIAPLoadBack _loadCallBack;
    
};

#endif /* defined(__OLStarYo__IAPHelper__) */