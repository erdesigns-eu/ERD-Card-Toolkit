@echo off
setlocal
cd /d "%~dp0.."
if errorlevel 1 exit /b %errorlevel%
set "CARD_COMPILER=%~1"
if not defined CARD_COMPILER set "CARD_COMPILER=dcc32"
if /i "%CARD_COMPILER%"=="dcc32" (set "CARD_PLATFORM=Win32") else if /i "%CARD_COMPILER%"=="dcc64" (set "CARD_PLATFORM=Win64") else (
  echo Use dcc32 or dcc64 from a RAD Studio command prompt. 1>&2
  exit /b 2
)
where %CARD_COMPILER% >nul 2>&1
if errorlevel 1 exit /b %errorlevel%
where msbuild >nul 2>&1
if errorlevel 1 exit /b %errorlevel%
call :build_demo smartcard SmartCardDemo
if errorlevel 1 exit /b %errorlevel%
call :build_demo magstripe MagStripeDemo
if errorlevel 1 exit /b %errorlevel%
call :build_demo readertools ReaderToolsDemo
if errorlevel 1 exit /b %errorlevel%
call :build_demo memorycard MemoryCardDemo
if errorlevel 1 exit /b %errorlevel%
call :build_demo slecounter SleCounterDemo
if errorlevel 1 exit /b %errorlevel%
call :build_demo sle4404 Sle4404Demo
if errorlevel 1 exit /b %errorlevel%
call :build_demo twn4 Twn4Demo
if errorlevel 1 exit /b %errorlevel%
call :build_demo rfidinput RfidInputDemo
if errorlevel 1 exit /b %errorlevel%
call :build_demo simcard SimCardDemo
if errorlevel 1 exit /b %errorlevel%
call :build_demo mifareclassic MifareClassicDemo
if errorlevel 1 exit /b %errorlevel%
call :build_demo type2 Type2Demo
if errorlevel 1 exit /b %errorlevel%
call :build_demo type4ndef Type4NdefDemo
if errorlevel 1 exit /b %errorlevel%
call :build_demo emv EmvDemo
if errorlevel 1 exit /b %errorlevel%
call :build_demo belgianeid BelgianEidDemo
if errorlevel 1 exit /b %errorlevel%
call :build_demo icaodocument IcaoDocumentDemo
if errorlevel 1 exit /b %errorlevel%
call :build_demo iso15693 Iso15693Demo
if errorlevel 1 exit /b %errorlevel%
call :build_demo uid UidProgrammingDemo
if errorlevel 1 exit /b %errorlevel%
call :build_demo desfire DesfireDemo
if errorlevel 1 exit /b %errorlevel%
call :build_demo magstripeprofiles MagStripeProfilesDemo
if errorlevel 1 exit /b %errorlevel%
call :build_demo usbhid UsbHidDemo
if errorlevel 1 exit /b %errorlevel%
exit /b %errorlevel%
:build_demo
rem Use the same resource generation and configuration as the IDE projects.
msbuild "examples\vcl\%~1\%~2.dproj" /t:Build /p:Config=Debug /p:Platform=%CARD_PLATFORM% /p:DCC_BuildAllUnits=true /nologo /v:minimal
exit /b %errorlevel%
