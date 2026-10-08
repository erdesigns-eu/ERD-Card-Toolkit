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
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\magstripe" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" tests\magstripe\MagStripe.Tests.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\MagStripe.Tests.exe"
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -Usrc\magstripe -N0"%CARD_BUILD%" -E"%CARD_BUILD%" examples\magstripe\InspectMagStripe.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectMagStripe.exe" --help
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectMagStripe.exe" --track 1 --frame "%%AT3?"
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectMagStripe.exe" --track 2 --bits 110101000001000110011111100100
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectMagStripe.exe" --track 2 --bits 010101000001000110011111100100
if not errorlevel 1 exit /b 1
if errorlevel 2 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\magstripe" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" tests\magstripe\Msr206.Tests.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\Msr206.Tests.exe"
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\magstripe" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" tests\magstripe\Msr2067HL.Tests.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\Msr2067HL.Tests.exe"
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\magstripe" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" examples\magstripe\InspectMsr206.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectMsr206.exe" --help
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectMsr206.exe" --frame-hex 1B731B012530313F1B023B32333F1B033B34353F3F1C1B30
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectMsr206.exe" --frame-hex 1B731B012530313F1B023B32333F1B033B34353F3F1C1B31
if not errorlevel 1 exit /b 1
if errorlevel 2 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\emv" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" tests\core\CardCatalogs.Tests.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\CardCatalogs.Tests.exe"
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\contactless" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" tests\contactless\Iso15693Type5.Tests.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\Iso15693Type5.Tests.exe"
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\emv" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" examples\core\InspectCardTools.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectCardTools.exe" --help
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectCardTools.exe" --atr 3B8F8001804F0CA0000003060B00350000000056
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectCardTools.exe" --tag 9F26
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectCardTools.exe" --atr 3B8F8001804F0CA0000003060B00350000000057
if not errorlevel 1 exit /b 1
if errorlevel 2 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\pcsc;src\contactless" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" examples\contactless\InspectType5Ndef.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectType5Ndef.exe" --help
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectType5Ndef.exe" --cc-hex E1403F00 --blocks 128 --block-size 4 --address 8
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectType5Ndef.exe" --cc-hex E1404000 --blocks 128 --block-size 4 --address 8
if not errorlevel 1 exit /b 1
if errorlevel 2 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\crypto;src\contactless" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" tests\crypto\CardCrypto.Tests.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\CardCrypto.Tests.exe"
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\crypto;src\contactless;tests\contactless" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" tests\contactless\Desfire.Tests.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\Desfire.Tests.exe"
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\crypto;src\contactless;tests\contactless" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" tests\contactless\DesfireSession.Tests.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\DesfireSession.Tests.exe"
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\crypto;src\contactless;src\pcsc" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" examples\contactless\ManageDesfire.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\ManageDesfire.exe" --help
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\ManageDesfire.exe" --plan
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\ManageDesfire.exe" --unknown
if not errorlevel 1 exit /b 1
if errorlevel 2 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\crypto;src\contactless;src\pcsc" -N0"%CARD_BUILD%" -E"%CARD_BUILD%" examples\contactless\InspectDesfire.dpr
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectDesfire.exe" --help
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectDesfire.exe" --settings-hex 00031234332211 --file 0
if errorlevel 1 exit /b %errorlevel%
"%CARD_BUILD%\InspectDesfire.exe" --settings-hex 000312343322 --file 0
if not errorlevel 1 exit /b 1
if errorlevel 2 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -Usrc\magstripe -N0"%CARD_BUILD%" -LE"%CARD_BUILD%" -LN"%CARD_BUILD%" packages\runtime\ERDCardMagStripe.dpk
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -Usrc\core -N0"%CARD_BUILD%" -LE"%CARD_BUILD%" -LN"%CARD_BUILD%" packages\runtime\ERDCardCore.dpk
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\crypto;%CARD_BUILD%" -N0"%CARD_BUILD%" -LE"%CARD_BUILD%" -LN"%CARD_BUILD%" packages\runtime\ERDCardCryptoWindows.dpk
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\pcsc;%CARD_BUILD%" -N0"%CARD_BUILD%" -LE"%CARD_BUILD%" -LN"%CARD_BUILD%" packages\runtime\ERDCardPCSC.dpk
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\eid;%CARD_BUILD%" -N0"%CARD_BUILD%" -LE"%CARD_BUILD%" -LN"%CARD_BUILD%" packages\runtime\ERDCardEID.dpk
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\emv;%CARD_BUILD%" -N0"%CARD_BUILD%" -LE"%CARD_BUILD%" -LN"%CARD_BUILD%" packages\runtime\ERDCardEMV.dpk
if errorlevel 1 exit /b %errorlevel%
%CARD_COMPILER% -B -Q --doc -$R+ -$Q+ -U"src\core;src\contactless;%CARD_BUILD%" -N0"%CARD_BUILD%" -LE"%CARD_BUILD%" -LN"%CARD_BUILD%" packages\runtime\ERDCardContactless.dpk
exit /b %errorlevel%
