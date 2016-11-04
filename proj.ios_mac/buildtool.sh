#!/bin/bash
#build .app
projectDir=$(cd `dirname $0`; pwd)
ipaDir=$projectDir/bin
buildDir=$projectDir/build
infoplist=$projectDir/ios
sign="iPhone Developer: yang chao (F4PC9SL3M9)"

if [ -d $projectDir ]
then
cd $projectDir

fi

#if [ -e $buildDir ]
#then
#rm -rf $buildDir
#fi

#if [ $? = 0 ]
#then
#xcodebuild clean
#fi

#修改版本号
#if [ $? = 0 ]
#then
#last=`echo $verStr|awk -F "." '{print $1 "." $2 "." $3+1}'`
#/usr/libexec/PlistBuddy -c "Set CFBundleVersion ${last}" $infoplist/Info.plist
#fi

if [ $? = 0 ]
then               #修改成当前工程名
xcodebuild -target sdkIOSDemo-mobile #CODE_SIGN_IDENTITY="$sign"
fi

if [ -e $ipaDir ]
then
rm -rf $ipaDir
mkdir $ipaDir
else
mkdir $ipaDir
fi

if [ $? = 0 ]
then
#package .ipa                                                       修改成当前工程名
xcrun -sdk iphoneos  PackageApplication -v $buildDir/Debug-iphoneos/sdkIOSDemo-mobile.app -o $ipaDir/publish.ipa  #--sign "$sign"
else
echo "error...."
exit
fi

#if [ -e $buildDir ]
#then
#rm -rf $buildDir
#fi


if [ $? = 0 ]
then
echo "正在上传ipa到蒲公英，请勿终止或关闭终端，当上传成功之后会接受到成功提示"
#upload ipa to pgyer
result=$(curl -F "file=@bin/publish.ipa" -F "uKey=636757a606f06cf267a916f9130a8743" -F "_api_key=a1977dd6afd40ad800f24d64d236dd65" -F "publishRange=3" http://www.pgyer.com/apiv1/app/upload)
echo "接受到的信息开头显示{code:0 既是上传成功"
echo $result
echo "下载地址 http://www.pgyer.com/NdAl"
fi






