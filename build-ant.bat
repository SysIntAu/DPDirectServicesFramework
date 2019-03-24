echo off

set ANT_HOME=C:\Apps\Ant\apache-ant-1.8.2-bin\apache-ant-1.8.2
set JAVA_HOME=C:\Apps\Java\jdk1.8.0_151
set PATH=%PATH%;%ANT_HOME%\bin;%JAVA_HOME%\bin

ant %*
PAUSE
