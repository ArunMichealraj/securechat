@echo off
:: Starts the SecureChat backend. Keep this window open while using the app.
cd /d "%~dp0backend"
if not exist node_modules call npm install --cache D:\dev\npm-cache
if not exist .env copy .env.example .env >nul
call npx tsc -p tsconfig.json || (pause & exit /b 1)
echo.
echo Phones connect to: http://YOUR-PC-WIFI-IP:3000   (run "ipconfig" to see it)
echo.
node dist\main.js
pause
