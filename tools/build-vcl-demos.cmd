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
set "CARD_BUILD=dist\vcl\%CARD_PLATFORM%\Debug"
set "CARD_UNITS=src\core;src\crypto;src\pcsc;src\eid;src\emv;src\magstripe;src\contactless;examples\vcl\shared"
call :build_demo smartcard SmartCardDemo
if errorlevel 1 exit /b %errorlevel%
call :build_demo magstripe MagStripeDemo
exit /b %errorlevel%
:build_demo
set "CARD_DCU=%CARD_BUILD%\%~2\dcu"
if not exist "%CARD_DCU%" mkdir "%CARD_DCU%"
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"%CARD_UNITS%" -N0"%CARD_DCU%" -E"%CARD_BUILD%" "examples\vcl\%~1\%~2.dpr"
exit /b %errorlevel%
