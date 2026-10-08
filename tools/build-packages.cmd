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
if not "%~2"=="" if /i not "%~2"=="design" (
  echo Optional second argument: design. Its platform must match your IDE. 1>&2
  exit /b 2
)
where %CARD_COMPILER% >nul 2>&1
if errorlevel 1 exit /b %errorlevel%
set "CARD_BUILD=dist\packages\%CARD_PLATFORM%\Debug"
set "CARD_UNITS=src\core;src\crypto;src\pcsc;src\eid;src\emv;src\magstripe;src\contactless;src\design;%CARD_BUILD%"
for %%P in (ERDCardCore ERDCardMagStripe ERDCardPCSC ERDCardEID ERDCardEMV ERDCardContactless ERDCardCryptoWindows ERDCardCryptoOpenSSL) do (
  call :build_runtime %%P
  if errorlevel 1 exit /b 1
)
if /i "%~2"=="design" (
  call :build_package design ERDCardDesign
  if errorlevel 1 exit /b 1
)
exit /b 0
:build_runtime
call :build_package runtime %~1
exit /b %errorlevel%
:build_package
set "CARD_DCU=%CARD_BUILD%\%~2\dcu"
if not exist "%CARD_DCU%" mkdir "%CARD_DCU%"
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"%CARD_UNITS%" -N0"%CARD_DCU%" -LE"%CARD_BUILD%" -LN"%CARD_BUILD%" "packages\%~1\%~2.dpk"
exit /b %errorlevel%
