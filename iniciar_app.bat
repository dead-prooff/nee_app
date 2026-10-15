@echo off
REM Inicia el emulador Android (si no esta abierto) y corre la app.
REM En esta ventana: r = recargar cambios, R = reiniciar app, q = salir.
setlocal
cd /d "%~dp0"
set "SDK=%LOCALAPPDATA%\Android\Sdk"
set "ADB=%SDK%\platform-tools\adb.exe"
set "AVD=Medium_Phone_API_36.1"

"%ADB%" devices | findstr /r "emulator-[0-9]*.*device$" >nul
if errorlevel 1 (
    echo Abriendo emulador %AVD%...
    start "" "%SDK%\emulator\emulator.exe" -avd %AVD%
)

echo Esperando que el emulador termine de arrancar...
"%ADB%" wait-for-device
:esperar
for /f "delims=" %%b in ('"%ADB%" shell getprop sys.boot_completed 2^>nul') do set "BOOT=%%b"
if not "%BOOT%"=="1" (
    timeout /t 2 /nobreak >nul
    goto esperar
)

echo Emulador listo. Ejecutando la app...
call flutter run -d emulator-5554
endlocal
