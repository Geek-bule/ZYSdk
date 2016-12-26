#!/bin/bash
#build .app
projectDir=$(cd `dirname $0`; pwd)
exprotDir=$projectDir/expDir
buildDir=$projectDir/build
infoplist=$projectDir/ios
sign="iPhone Developer: yang chao (F4PC9SL3M9)"

if [ -d $projectDir ]
then
cd $projectDir

fi

if [ -e $buildDir ]
then
rm -rf $buildDir
fi

if [ $? = 0 ]
then
xcodebuild clean
fi

if [ $? = 0 ]
then               #修改成当前工程名
xcodebuild -target ZYLib -configuration Release -sdk iphoneos
fi

if [ $? = 0 ]
then               #修改成当前工程名
xcodebuild -target ZYAdview -configuration Release -sdk iphoneos
fi

if [ $? = 0 ]
then               #修改成当前工程名
xcodebuild -target ZYVideo -configuration Release -sdk iphoneos
fi

if [ $? = 0 ]
then               #修改成当前工程名
xcodebuild -target ZYLib -configuration Release -sdk iphonesimulator
fi

if [ $? = 0 ]
then               #修改成当前工程名
xcodebuild -target ZYAdview -configuration Release -sdk iphonesimulator
fi

if [ $? = 0 ]
then               #修改成当前工程名
xcodebuild -target ZYVideo -configuration Release -sdk iphonesimulator
fi

libraryPath=$buildDir/Release-iphoneos
libraryImuPath=$buildDir/Release-iphonesimulator

ZYSdk=libZYLib.a
ZYAdview=libZYAdview.a
ZYVideo=libZYVideo.a

exportZYDir=$projectDir/../exportLib/


if [ $? = 0 ]
then
lipo -create $libraryPath/$ZYSdk $libraryImuPath/$ZYSdk -output $exportZYDir
fi


if [ $? = 0 ]
then
lipo -create $libraryPath/$ZYSdk $libraryImuPath/$ZYSdk -output $exportZYDir
fi


if [ $? = 0 ]
then
lipo -create $libraryPath/$ZYSdk $libraryImuPath/$ZYSdk -output $exportZYDir
fi


if [ $? = 0 ]
then
cp -r $libraryPath/usr/local/include $exportZYDir
fi


if [ $? = 0 ]
then
cp -r $projectDir/ZYSdk.bundle $exportZYDir
fi







