@echo off

echo Deploy build to ESB environment
echo.

cd .\distribution\target

echo Removing and recreating temp build folder...
echo.

rmdir /S /Q .\distribution-deploy
mkdir distribution-deploy
cd distribution-deploy

echo Unzipping build file...
echo.

jar xf ..\distribution-deploy.zip

cd .\dpdirect-framework\ant-deploy

SET /P ENV=[Environment]

cmd /k ant -f dp-deploy.xml deploy -Denv=%ENV%