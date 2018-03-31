echo off

set ANT_HOME=C:\Program Files\apache-ant-1.8.2
set JAVA_HOME=C:\Program Files\Java\jdk1.8.0_162
set PATH=%PATH%;C:\Program Files\apache-ant-1.8.2\bin

ant %*
PAUSE
