#!/bin/sh

libraryPath=/Users/justinyang/Library/Developer/Xcode/DerivedData/sdkIOSDemo-hkqwuavldxyucrdlzruuarvvdnez/Build/Products/Release-iphoneos
libraryImuPath=/Users/justinyang/Library/Developer/Xcode/DerivedData/sdkIOSDemo-hkqwuavldxyucrdlzruuarvvdnez/Build/Products/Release-iphonesimulator

ZYSdk=libZYLib.a
ZYAdview=libZYAdview.a
ZYVideo=libZYVideo.a

exportZYDir=/Users/justinyang/Desktop/svn/sdkIOSv3/sdkIOSDemov3/exportLib/
exportZYSdk=/Users/justinyang/Desktop/svn/sdkIOSv3/sdkIOSDemov3/exportLib/ZYSdk
exportZYZYAdview=/Users/justinyang/Desktop/svn/sdkIOSv3/sdkIOSDemov3/exportLib/ZYAdview
exportZYVideo=/Users/justinyang/Desktop/svn/sdkIOSv3/sdkIOSDemov3/exportLib/ZYVideo


if [ $? = 0 ]
then
lipo -create $libraryPath/$ZYSdk $libraryImuPath/$ZYSdk -output $exportZYSdk/$ZYSdk
fi


if [ $? = 0 ]
then
lipo -create $libraryPath/$ZYSdk $libraryImuPath/$ZYSdk -output $exportZYZYAdview/$ZYAdview
fi


if [ $? = 0 ]
then
lipo -create $libraryPath/$ZYSdk $libraryImuPath/$ZYSdk -output $exportZYVideo/$ZYVideo
fi


if [ $? = 0 ]
then
cp -r $libraryPath/usr/local/include $exportZYDir
fi


if [ $? = 0 ]
then
cp -r /Users/justinyang/Desktop/svn/sdkIOSv3/sdkIOSDemov3/proj.ios_mac/ZYSdk.bundle $exportZYDir
fi





