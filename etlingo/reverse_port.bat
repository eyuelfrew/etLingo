@echo off

set DEVICE=R3CN50KWWFH

adb -s %DEVICE% reverse tcp:5050 tcp:5050

echo Ports reversed for %DEVICE%
adb -s %DEVICE% reverse --list