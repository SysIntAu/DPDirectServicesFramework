@echo off



SET /P ENV=[Environment]


echo Deploying build to DP environment %ENV%
echo.

set ANT_HOME=C:\Apps\Ant\apache-ant-1.8.2-bin\apache-ant-1.8.2
set JAVA_HOME=C:\Apps\Java\jdk1.8.0_151
set PATH=%PATH%;%ANT_HOME%\bin;%JAVA_HOME%\bin

cd .\distribution\target



echo Removing and recreating temp build folder...

echo.



rmdir /S /Q .\distribution-deploy

mkdir distribution-deploy

cd distribution-deploy



echo Unzipping build file...

echo.



jar xf ..\distribution-deploy.zip


cd ant-deploy


cmd /k ant -f dp-deploy.xml deploy -Denv=%ENV%
