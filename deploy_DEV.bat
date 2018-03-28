@echo off



set Environment=%1


echo Deploy build to DP environment %Environment%
echo.

REM set ANT_HOME=C:\tools\Ant_1.9.1
set ANT_HOME=C:\tools\apache-ant-1.7.1
set JAVA_HOME=C:\tools\jdk1.8.0_31
set PATH=%PATH%;C:\Tools\Ant\bin;C:\tools\jdk1.8.0_31\bin

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

cmd /k ant -f dp-deploy.xml deploy -Denv=DEV
