@echo off
setlocal
cd /d "%~dp0.."
if errorlevel 1 exit /b %errorlevel%
set "CARD_COMPILER=%~1"
if not defined CARD_COMPILER set "CARD_COMPILER=dcc32"
if /i "%CARD_COMPILER%"=="dcc32" goto compiler_selected
if /i "%CARD_COMPILER%"=="dcc64" goto compiler_selected
echo Use dcc32 or dcc64 from a RAD Studio command prompt. 1>&2
exit /b 2
:compiler_selected
where %CARD_COMPILER% >nul 2>&1
if errorlevel 1 exit /b %errorlevel%
set "CARD_BUILD=dist\core\%CARD_COMPILER%"
if not exist "%CARD_BUILD%" mkdir "%CARD_BUILD%"
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -Usrc\core -N0"%CARD_BUILD%" -E"%CARD_BUILD%" tests\core\CardCore.Tests.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\CardCore.Tests.exe"
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -Usrc\core -N0"%CARD_BUILD%" -E"%CARD_BUILD%" tests\core\ProtocolCore.Tests.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\ProtocolCore.Tests.exe"
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -Usrc\core -N0"%CARD_BUILD%" -E"%CARD_BUILD%" examples\core\InspectApdu.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectApdu.exe" 0000000002AABB00
exit /b %errorlevel%
