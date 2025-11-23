@echo off
title TJK API Sunucusu
color 0A
echo ========================================
echo    TJK API Sunucusu Baslatiliyor...
echo ========================================
echo.
echo Bilgisayarinizin IP adresi:
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do echo   %%a
echo.
echo API Sunucusu asagidaki adreslerde calisacak:
echo   - http://localhost:5000
echo   - http://192.168.x.x:5000
echo.
echo Telefon ayarlarinda bu IP adresini kullanin!
echo.
echo ========================================
echo.
python api_server.py
echo.
echo API Sunucusu kapandi!
pause
