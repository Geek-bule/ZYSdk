//
//  GCHelper.h
//  CatRace
//
//  Created by Ray Wenderlich on 4/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//


#ifndef __OLStarYo__InGCHelper__
#define __OLStarYo__InGCHelper__

#include "cocos2d.h"

typedef std::function<void(int,float)> ccGCcallBack;

class InGCHelper
{
public:
    static InGCHelper *shareIAP();
    void initGC();
    void setGCcallBack(const ccGCcallBack &call);
    void showGameCenter();
    void updateGC(std::string identifer,int score);
    void getRank(std::string identifer);
    
    ccGCcallBack _callBack;
};

#endif /* defined(__OLStarYo__InGCHelper__) */


