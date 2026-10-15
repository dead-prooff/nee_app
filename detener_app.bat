@echo off
REM Cierra la app y apaga el emulador Android.
set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
echo Cerrando la app y el emulador...
"%ADB%" shell am force-stop com.nee.nee_app >nul 2>&1
"%ADB%" emu kill >nul 2>&1
echo Listo.
timeout /t 2 >nul
