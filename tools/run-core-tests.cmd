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
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\pcsc" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" tests\transport\CardTransport.Tests.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\CardTransport.Tests.exe"
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\eid" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" tests\eid\BelgianEid.Tests.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\BelgianEid.Tests.exe"
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\eid" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" tests\eid\Icao.Tests.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\Icao.Tests.exe"
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\emv" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" tests\emv\Emv.Tests.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\Emv.Tests.exe"
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\contactless" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" tests\contactless\Contactless.Tests.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\Contactless.Tests.exe"
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\contactless" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" tests\contactless\RawUid.Tests.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\RawUid.Tests.exe"
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\contactless" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" tests\contactless\Type2Password.Tests.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\Type2Password.Tests.exe"
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\contactless" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" tests\contactless\Ndef.Tests.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\Ndef.Tests.exe"
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\contactless" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" examples\contactless\InspectNdef.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectNdef.exe" --help
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectNdef.exe" D101055402656E4869
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectNdef.exe" D101055402656E48
if not errorlevel 1 exit /b 1
if errorlevel 2 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\contactless" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" tests\contactless\Type4Ndef.Tests.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\Type4Ndef.Tests.exe"
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\pcsc;src\contactless" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" examples\contactless\InspectType4Ndef.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectType4Ndef.exe" --help
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectType4Ndef.exe" --cc-hex 000F20003A00340406E10401000000
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectType4Ndef.exe" --cc-hex 000F20003A00340406E104010000
if not errorlevel 1 exit /b 1
if errorlevel 2 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\pcsc;src\contactless" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" examples\contactless\InspectContactless.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectContactless.exe" --help
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\pcsc;src\emv" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" examples\emv\InspectEmv.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectEmv.exe" --help
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\pcsc;src\eid" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" examples\eid\ReadBelgianEid.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\ReadBelgianEid.exe" --help
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\pcsc" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" examples\pcsc\InspectReader.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectReader.exe" --help
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -Usrc\core -N0"%CARD_BUILD%" -E"%CARD_BUILD%" examples\core\InspectApdu.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectApdu.exe" 0000000002AABB00
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -Usrc\core -N0"%CARD_BUILD%" -LE"%CARD_BUILD%" -LN"%CARD_BUILD%" packages\runtime\ERDCardCore.dpk
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\pcsc;%CARD_BUILD%" -N0"%CARD_BUILD%" -LE"%CARD_BUILD%" -LN"%CARD_BUILD%" packages\runtime\ERDCardPCSC.dpk
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\eid;%CARD_BUILD%" -N0"%CARD_BUILD%" -LE"%CARD_BUILD%" -LN"%CARD_BUILD%" packages\runtime\ERDCardEID.dpk
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\emv;%CARD_BUILD%" -N0"%CARD_BUILD%" -LE"%CARD_BUILD%" -LN"%CARD_BUILD%" packages\runtime\ERDCardEMV.dpk
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\contactless;%CARD_BUILD%" -N0"%CARD_BUILD%" -LE"%CARD_BUILD%" -LN"%CARD_BUILD%" packages\runtime\ERDCardContactless.dpk
exit /b %errorlevel%
