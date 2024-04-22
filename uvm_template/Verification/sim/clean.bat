@echo off
echo 开始清理......
del transcript
del *.log
del *.wlf
del *.xml
rd  /s /Q work
echo 清理完成......
@echo on
pause