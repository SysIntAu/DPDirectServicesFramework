@echo off



set Environment=%1


echo Deploy build to DP environment %Environment%
echo.

set ANT_HOME=C:\Program Files\apache-ant-1.8.2
set JAVA_HOME=C:\Program Files\Java\jdk1.8.0_162
set PATH=%PATH%;C:\Program Files\apache-ant-1.8.2\bin;C:\Program Files\Java\jdk1.8.0_162

cd .\target



echo Removing and recreating temp build folder...

echo.



rmdir /S /Q .\distribution-deploy

mkdir distribution-deploy

cd distribution-deploy



echo Unzipping build file...

echo.



jar xf ..\distribution-deploy.zip


cd ant-deploy

REM SET /P ENV=[Environment]
SET ENV=%Environment%

cmd /k ant -f dp-deploy.xml deploy -Denv=%ENV%
