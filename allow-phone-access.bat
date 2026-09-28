@echo off
:: Lets phones on your Wi-Fi reach the chat server on port 3000.
:: Right-click this file -> "Run as administrator". Only needed once.
netsh advfirewall firewall delete rule name="SecureChat dev server" >nul 2>&1
netsh advfirewall firewall add rule name="SecureChat dev server" dir=in action=allow protocol=TCP localport=3000 profile=private
if %errorlevel%==0 (echo Done. Phones on your Wi-Fi can now reach port 3000.) else (echo Failed. Right-click this file and choose "Run as administrator".)
pause
