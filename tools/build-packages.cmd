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
where msbuild >nul 2>&1
if errorlevel 1 exit /b %errorlevel%
for %%P in (ERDCardCore ERDCardMagStripe ERDCardPCSC ERDCardEID ERDCardEMV ERDCardGlobalPlatform ERDCardContactless ERDCardCryptoWindows ERDCardCryptoOpenSSL ERDCardMemory ERDCardSIM ERDCardInput ERDCardTWN4) do (
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
rem MSBuild generates the package .res before invoking the selected Delphi compiler.
msbuild "packages\%~1\%~2.dproj" /t:Build /p:Config=Debug /p:Platform=%CARD_PLATFORM% /p:DCC_BuildAllUnits=true /nologo /v:minimal
exit /b %errorlevel%
